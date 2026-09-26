# backend/app/routes/providers.py
from typing import List
import json
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.core.security import decode_token
from backend.app.models import (
    User, UserRole, ProviderProfile, VerificationStatus,
    Service, ServiceCategory
)
from backend.app.schemas import (
    ProviderProfileCreate, ProviderProfileUpdate, ProviderProfileOut,
    ServiceCreate, ServiceOut
)

router = APIRouter(prefix="/providers", tags=["Providers"])
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


def _parse_photos(raw):
    if not raw:
        return []
    try:
        return json.loads(raw)
    except Exception:
        return []


def _profile_to_out(profile: ProviderProfile, user: User) -> dict:
    return {
        "id": profile.id,
        "user_id": profile.user_id,
        "full_name": user.full_name,
        "phone": user.phone,
        "county": user.county,
        "constituency": user.constituency,
        "bio": profile.bio,
        "years_experience": profile.years_experience,
        "verification_status": profile.verification_status.value,
        "location_text": profile.location_text,
        "latitude": profile.latitude,
        "longitude": profile.longitude,
        "photo_urls": _parse_photos(profile.photo_urls),
        "avg_rating": profile.avg_rating,
        "total_reviews": profile.total_reviews,
        "total_bookings": profile.total_bookings,
        "is_available": profile.is_available,
    }


# ---------- PUBLIC PROVIDER DETAIL ----------
@router.get("/{provider_id}")
def get_provider_detail(provider_id: int, db: Session = Depends(get_db)):
    """Public provider detail — usable by clients when viewing a provider."""
    profile = db.query(ProviderProfile).get(provider_id)
    if not profile:
        raise HTTPException(404, "Provider not found")
    user = db.query(User).get(profile.user_id)
    if not user:
        raise HTTPException(404, "Provider user not found")

    # Get all services for this provider
    services = db.query(Service).filter_by(provider_id=profile.id, is_active=True).all()
    services_out = []
    for s in services:
        cat = db.query(ServiceCategory).get(s.category_id)
        services_out.append({
            "id": s.id,
            "title": s.title,
            "description": s.description,
            "price": float(s.base_price),
            "price_unit": s.price_unit,
            "category": cat.name if cat else "",
            "category_id": s.category_id,
        })

    return {
        "id": profile.id,
        "user_id": profile.user_id,
        "full_name": user.full_name,
        "phone": user.phone,
        "county": user.county,
        "constituency": user.constituency,
        "bio": profile.bio,
        "years_experience": profile.years_experience,
        "verification_status": profile.verification_status.value,
        "location_text": profile.location_text,
        "latitude": profile.latitude,
        "longitude": profile.longitude,
        "photo_urls": _parse_photos(profile.photo_urls),
        "avg_rating": profile.avg_rating,
        "total_reviews": profile.total_reviews,
        "total_bookings": profile.total_bookings,
        "is_available": profile.is_available,
        "services": services_out,
    }


# ---------- MY PROFILE ----------
@router.get("/me")
def get_my_profile(
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    if user.role != UserRole.provider:
        raise HTTPException(403, "Only providers have profiles")
    profile = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    if not profile:
        raise HTTPException(404, "Profile not created yet")
    return _profile_to_out(profile, user)


@router.post("/profile", status_code=201)
def create_profile(
    data: ProviderProfileCreate,
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    if user.role != UserRole.provider:
        raise HTTPException(403, "Only providers can create a profile")

    existing = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    if existing:
        raise HTTPException(400, "Profile already exists — use PATCH")

    profile = ProviderProfile(
        user_id=user.id,
        bio=data.bio,
        years_experience=data.years_experience,
        id_number=data.id_number,
        id_doc_url=data.id_doc_url,
        cert_doc_url=data.cert_doc_url,
        location_text=data.location_text,
        latitude=data.latitude,
        longitude=data.longitude,
        verification_status=VerificationStatus.pending,
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return _profile_to_out(profile, user)


@router.patch("/profile")
def update_profile(
    data: ProviderProfileUpdate,
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    profile = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    if not profile:
        raise HTTPException(404, "Profile not found")

    if data.bio is not None:
        profile.bio = data.bio
    if data.years_experience is not None:
        profile.years_experience = data.years_experience
    if data.location_text is not None:
        profile.location_text = data.location_text
    if data.latitude is not None:
        profile.latitude = data.latitude
    if data.longitude is not None:
        profile.longitude = data.longitude
    if data.is_available is not None:
        profile.is_available = data.is_available
    if data.photo_urls is not None:
        profile.photo_urls = json.dumps(data.photo_urls)

    db.commit()
    db.refresh(profile)
    return _profile_to_out(profile, user)


@router.patch("/availability")
def toggle_availability(
    is_available: bool,
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    profile = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    if not profile:
        raise HTTPException(404, "Profile not found")
    profile.is_available = is_available
    db.commit()
    return {"is_available": profile.is_available}


# ---------- MY SERVICES ----------
@router.get("/services/list", response_model=List[ServiceOut])
def my_services(
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    profile = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    if not profile:
        raise HTTPException(404, "Profile not found")
    return db.query(Service).filter_by(provider_id=profile.id).all()


@router.post("/services", response_model=ServiceOut, status_code=201)
def add_service(
    data: ServiceCreate,
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    profile = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    if not profile:
        raise HTTPException(404, "Create provider profile first")

    cat = db.query(ServiceCategory).get(data.category_id)
    if not cat:
        raise HTTPException(404, "Category not found")

    svc = Service(
        provider_id=profile.id,
        category_id=data.category_id,
        title=data.title,
        description=data.description,
        base_price=data.base_price,
        price_unit=data.price_unit,
    )
    db.add(svc)
    db.commit()
    db.refresh(svc)
    return ServiceOut.model_validate(svc)


@router.put("/services/{service_id}", response_model=ServiceOut)
def update_service(
    service_id: int,
    data: ServiceCreate,
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    profile = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    if not profile:
        raise HTTPException(404, "Profile not found")
    svc = db.query(Service).filter_by(id=service_id, provider_id=profile.id).first()
    if not svc:
        raise HTTPException(404, "Service not found or not yours")
    svc.category_id = data.category_id
    svc.title = data.title
    svc.description = data.description
    svc.base_price = data.base_price
    svc.price_unit = data.price_unit
    db.commit()
    db.refresh(svc)
    return ServiceOut.model_validate(svc)


@router.delete("/services/{service_id}")
def delete_service(
    service_id: int,
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    profile = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    if not profile:
        raise HTTPException(404, "Profile not found")
    svc = db.query(Service).filter_by(id=service_id, provider_id=profile.id).first()
    if not svc:
        raise HTTPException(404, "Service not found or not yours")
    svc.is_active = False
    db.commit()
    return {"deactivated": service_id}