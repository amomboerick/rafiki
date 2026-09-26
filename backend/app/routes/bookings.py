# backend/app/routes/bookings.py
import random
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.core.security import decode_token
from backend.app.models import (
    Booking, BookingType, BookingStatus, Service, User,
    ProviderProfile, ServiceCategory, Review
)
from backend.app.schemas import BookingCreate, BookingOut, ReviewCreate

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
    user = _current_user(cred, db)

    # Client-side bookings
    client_bookings = (
        db.query(Booking, Service, ServiceCategory, ProviderProfile, User)
        .join(Service, Booking.service_id == Service.id)
        .join(ServiceCategory, Service.category_id == ServiceCategory.id)
        .join(ProviderProfile, Booking.provider_id == ProviderProfile.id)
        .join(User, ProviderProfile.user_id == User.id)
        .filter(Booking.client_id == user.id)
        .order_by(Booking.created_at.desc())
        .all()
    )

    # Provider-side bookings
    provider_profile = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    provider_bookings = []
    if provider_profile:
        provider_bookings = (
            db.query(Booking, Service, ServiceCategory, User)
            .join(Service, Booking.service_id == Service.id)
            .join(ServiceCategory, Service.category_id == ServiceCategory.id)
            .join(User, Booking.client_id == User.id)
            .filter(Booking.provider_id == provider_profile.id)
            .order_by(Booking.created_at.desc())
            .all()
        )

    results = []

    for b, s, c, pp, pu in client_bookings:
        results.append({
            "id": b.id,
            "reference": b.reference,
            "role": "client",
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
                "constituency": pu.constituency,
                "sub_county": pu.constituency,
                "rating": pp.avg_rating,
                "verified": pp.verification_status.value == "verified",
            },
        })

    for b, s, c, cu in provider_bookings:
        results.append({
            "id": b.id,
            "reference": b.reference,
            "role": "provider",
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
                "id": 0,
                "name": cu.full_name,
                "phone": cu.phone,
                "county": cu.county,
                "constituency": cu.constituency,
                "sub_county": cu.constituency,
                "rating": 0,
                "verified": False,
            },
        })

    results.sort(key=lambda x: x["created_at"], reverse=True)
    return results


@router.get("/{reference}")
def get_booking_detail(reference: str, db: Session = Depends(get_db)):
    """Full booking detail with provider + service info."""
    b = db.query(Booking).filter_by(reference=reference).first()
    if not b:
        raise HTTPException(404, "Booking not found")

    s = db.query(Service).get(b.service_id)
    c = db.query(ServiceCategory).get(s.category_id) if s else None
    pp = db.query(ProviderProfile).get(b.provider_id)
    pu = db.query(User).get(pp.user_id) if pp else None
    cu = db.query(User).get(b.client_id)

    return {
        "id": b.id,
        "reference": b.reference,
        "booking_type": b.booking_type.value,
        "status": b.status.value,
        "scheduled_at": b.scheduled_at.isoformat() if b.scheduled_at else None,
        "address": b.address,
        "latitude": b.latitude,
        "longitude": b.longitude,
        "notes": b.notes,
        "total_amount": float(b.total_amount),
        "rating": b.rating,
        "rating_comment": b.rating_comment,
        "created_at": b.created_at.isoformat(),
        "service": {
            "id": s.id,
            "title": s.title,
            "description": s.description,
            "price": float(s.base_price),
            "price_unit": s.price_unit,
            "category": c.name if c else "",
        } if s else None,
        "provider": {
            "id": pp.id,
            "name": pu.full_name,
            "phone": pu.phone,
            "county": pu.county,
            "constituency": pu.constituency,
            "sub_county": pu.constituency,
            "rating": pp.avg_rating,
            "reviews": pp.total_reviews,
            "verified": pp.verification_status.value == "verified",
        } if pp and pu else None,
        "client": {
            "id": cu.id,
            "name": cu.full_name,
            "phone": cu.phone,
        } if cu else None,
    }


@router.post("/{reference}/cancel")
def cancel_booking(reference: str, db: Session = Depends(get_db)):
    b = db.query(Booking).filter_by(reference=reference).first()
    if not b:
        raise HTTPException(404, "Booking not found")
    if b.status not in (BookingStatus.pending, BookingStatus.accepted):
        raise HTTPException(400, "Only pending or accepted bookings can be cancelled")
    b.status = BookingStatus.cancelled
    db.commit()
    return {"cancelled": reference, "status": "cancelled"}


@router.post("/{reference}/review")
def submit_review(
    reference: str,
    data: ReviewCreate,
    db: Session = Depends(get_db),
):
    b = db.query(Booking).filter_by(reference=reference).first()
    if not b:
        raise HTTPException(404, "Booking not found")
    if b.status != BookingStatus.completed:
        raise HTTPException(400, "Can only review completed bookings")
    if b.rating is not None:
        raise HTTPException(400, "This booking already has a review")

    # Save to booking
    b.rating = data.rating
    b.rating_comment = data.comment
    db.commit()

    # Also create Review row
    review = Review(
        booking_id=b.id,
        client_id=b.client_id,
        provider_id=b.provider_id,
        rating=data.rating,
        comment=data.comment,
    )
    db.add(review)

    # Update provider's avg_rating
    pp = db.query(ProviderProfile).get(b.provider_id)
    if pp:
        all_reviews = db.query(Review).filter_by(provider_id=pp.id).all()
        total = sum(r.rating for r in all_reviews) + data.rating
        count = len(all_reviews) + 1
        pp.avg_rating = round(total / count, 2)
        pp.total_reviews = count

    db.commit()
    return {"ok": True, "rating": data.rating}