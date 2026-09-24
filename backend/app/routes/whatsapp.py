# backend/app/routes/whatsapp.py
from urllib.parse import quote
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.models import Booking, ProviderProfile, User, Service

router = APIRouter(prefix="/whatsapp", tags=["WhatsApp"])


@router.get("/{booking_reference}")
def whatsapp_link(booking_reference: str, db: Session = Depends(get_db)):
    b = db.query(Booking).filter_by(reference=booking_reference).first()
    if not b:
        raise HTTPException(404, "Booking not found")

    provider_profile = db.query(ProviderProfile).get(b.provider_id)
    provider_user = db.query(User).get(provider_profile.user_id)
    service = db.query(Service).get(b.service_id)

    msg = (
        f"Habari {provider_user.full_name}! "
        f"Nina booking ya Rafiki #{b.reference} kwa huduma ya '{service.title}'. "
        f"Tarehe: {b.scheduled_at or 'Haraka iwezekanavyo'}. "
        f"Tafadhali nithibitishe."
    )

    url = f"https://wa.me/{provider_user.phone}?text={quote(msg)}"
    return {"whatsapp_url": url, "provider_phone": provider_user.phone, "message": msg}