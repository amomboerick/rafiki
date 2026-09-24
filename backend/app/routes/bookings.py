# backend/app/routes/bookings.py
import random
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.core.security import decode_token
from backend.app.models import (
    Booking, BookingType, BookingStatus, Service, User, ProviderProfile, ServiceCategory
)
from backend.app.schemas import BookingCreate, BookingOut

router = APIRouter(prefix="/bookings", tags=["Bookings"])
bearer = HTTPBearer(auto_error=False)


def _current_user(cred: HTTPAuthorizationCredentials, db: Session) -> User:
    if not cred:
        raise HTTPException(401, "Not authenticated")
    payload = decode_token(cred.credentials)
    if not payload:
        raise HTTPException(401, "Invalid token")
    user = db.query(User).get(int(payload["sub"]))
    if not user:
        raise HTTPException(401, "User not found")
    return user


def _ref() -> str:
    return f"RFK-{random.randint(10000, 99999)}"


@router.post("", response_model=BookingOut, status_code=201)
def create_booking(
    data: BookingCreate,
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    service = db.query(Service).get(data.service_id)
    if not service:
        raise HTTPException(404, "Service not found")

    if data.booking_type == "scheduled" and not data.scheduled_at:
        raise HTTPException(400, "scheduled_at is required for scheduled bookings")

    booking = Booking(
        reference=_ref(),
        client_id=user.id,
        provider_id=service.provider_id,
        service_id=service.id,
        booking_type=BookingType(data.booking_type),
        status=BookingStatus.pending,
        scheduled_at=data.scheduled_at,
        address=data.address,
        latitude=data.latitude,
        longitude=data.longitude,
        notes=data.notes,
        total_amount=service.base_price,
    )
    db.add(booking)
    db.commit()
    db.refresh(booking)
    return BookingOut.model_validate(booking)


@router.get("/my", response_model=List[dict])
def my_bookings(
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    """List the current user's bookings, enriched with provider + service info."""
    user = _current_user(cred, db)

    rows = (
        db.query(Booking, Service, ServiceCategory, ProviderProfile, User)
        .join(Service, Booking.service_id == Service.id)
        .join(ServiceCategory, Service.category_id == ServiceCategory.id)
        .join(ProviderProfile, Booking.provider_id == ProviderProfile.id)
        .join(User, ProviderProfile.user_id == User.id)
        .filter(Booking.client_id == user.id)
        .order_by(Booking.created_at.desc())
        .all()
    )

    results = []
    for b, s, c, pp, pu in rows:
        results.append({
            "id": b.id,
            "reference": b.reference,
            "booking_type": b.booking_type.value,
            "status": b.status.value,
            "scheduled_at": b.scheduled_at.isoformat() if b.scheduled_at else None,
            "address": b.address,
            "notes": b.notes,
            "total_amount": float(b.total_amount),
            "created_at": b.created_at.isoformat(),
            "service": {
                "id": s.id,
                "title": s.title,
                "price": float(s.base_price),
                "price_unit": s.price_unit,
                "category": c.name,
            },
            "provider": {
                "id": pp.id,
                "name": pu.full_name,
                "phone": pu.phone,
                "county": pu.county,
                "sub_county": pu.sub_county,
                "rating": pp.avg_rating,
                "verified": pp.verification_status.value == "verified",
            },
        })
    return results


@router.get("/{reference}", response_model=BookingOut)
def get_booking(reference: str, db: Session = Depends(get_db)):
    b = db.query(Booking).filter_by(reference=reference).first()
    if not b:
        raise HTTPException(404, "Booking not found")
    return BookingOut.model_validate(b)