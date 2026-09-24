# backend/app/routes/payments.py
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.core.config import settings
from backend.app.models import (
    Booking, Payment, PaymentType, PaymentStatus,
    ServiceCategory, Service
)
from backend.app.schemas import STKPushRequest, STKPushResponse
from backend.app.services.mpesa import mpesa_client

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("/stkpush", response_model=STKPushResponse)
def initiate_stkpush(data: STKPushRequest, db: Session = Depends(get_db)):
    booking = db.query(Booking).filter_by(reference=data.booking_reference).first()
    if not booking:
        raise HTTPException(404, "Booking not found")

    service = db.query(Service).get(booking.service_id)
    category = db.query(ServiceCategory).get(service.category_id)

    if data.payment_type == "deposit":
        pct = category.default_deposit_pct or 30
        amount = int(float(booking.total_amount) * pct / 100)
    else:
        amount = int(float(booking.total_amount))

    if amount < 1:
        raise HTTPException(400, "Amount too low")

    payment = Payment(
        booking_id=booking.id,
        payment_type=PaymentType(data.payment_type),
        amount=amount,
        phone=data.phone,
        status=PaymentStatus.pending,
    )
    db.add(payment)
    db.commit()

    # --- DEBUG: Print Safaricom response ---
    print("=" * 60)
    print(f"[STK PUSH] Phone: {data.phone} | Amount: {amount} | Ref: {booking.reference}")
    print(f"[STK PUSH] Callback URL: {settings.MPESA_CALLBACK_URL}")
    print(f"[STK PUSH] Shortcode: {settings.MPESA_SHORTCODE}")
    try:
        resp = mpesa_client.stk_push(
            phone=data.phone,
            amount=amount,
            booking_ref=booking.reference,
            callback_url=settings.MPESA_CALLBACK_URL,
        )
        print(f"[STK PUSH] Safaricom raw response: {resp}")
    except Exception as e:
        print(f"[STK PUSH] EXCEPTION calling Safaricom: {e}")
        raise HTTPException(502, f"M-Pesa error: {e}")
    print("=" * 60)

    payment.checkout_request_id = resp.get("CheckoutRequestID")
    payment.merchant_request_id = resp.get("MerchantRequestID")
    db.commit()

    # If Safaricom didn't give a CheckoutRequestID, something went wrong
    if not resp.get("CheckoutRequestID"):
        error_msg = resp.get("errorMessage") or resp.get("ResponseDescription") or "Unknown Safaricom error"
        print(f"[STK PUSH] ⚠️ No CheckoutRequestID in response. Safaricom said: {error_msg}")
        return STKPushResponse(
            checkout_request_id=None,
            merchant_request_id=None,
            customer_message=f"Safaricom rejected request: {error_msg}",
            success=False,
        )

    return STKPushResponse(
        checkout_request_id=resp.get("CheckoutRequestID"),
        merchant_request_id=resp.get("MerchantRequestID"),
        customer_message=resp.get("CustomerMessage", "Check your phone to enter PIN"),
        success=resp.get("ResponseCode") == "0",
    )


@router.post("/callback")
async def mpesa_callback(request: Request, db: Session = Depends(get_db)):
    try:
        payload = await request.json()
    except Exception:
        return {"ResultCode": 0, "ResultDesc": "Accepted"}

    print("=" * 60)
    print(f"[CALLBACK] Received: {payload}")
    print("=" * 60)

    stk = payload.get("Body", {}).get("stkCallback", {})
    checkout_id = stk.get("CheckoutRequestID")
    result_code = stk.get("ResultCode")

    payment = db.query(Payment).filter_by(checkout_request_id=checkout_id).first()
    if not payment:
        print(f"[CALLBACK] No payment found for CheckoutRequestID: {checkout_id}")
        return {"ResultCode": 0, "ResultDesc": "Accepted"}

    if result_code == 0:
        items = {i["Name"]: i.get("Value") for i in stk.get("CallbackMetadata", {}).get("Item", [])}
        payment.mpesa_receipt = items.get("MpesaReceiptNumber")
        payment.status = PaymentStatus.success
        print(f"[CALLBACK] ✅ Payment {payment.id} marked SUCCESS. Receipt: {payment.mpesa_receipt}")
    else:
        payment.status = PaymentStatus.failed
        print(f"[CALLBACK] ❌ Payment {payment.id} marked FAILED. Code: {result_code}")

    db.commit()
    return {"ResultCode": 0, "ResultDesc": "Accepted"}