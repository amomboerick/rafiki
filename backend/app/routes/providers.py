# backend/app/routes/providers.py
from typing import List
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
    ProviderProfileCreate, ProviderProfileOut,
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


# ---------- PROFILE ----------
@router.get("/me", response_model=ProviderProfileOut)
def get_my_profile(
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    if user.role != UserRole.provider:
        raise HTTPException(403, "Only providers have profiles")
    profile = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    if not profile:
        raise HTTPException(404, "Profile not created yet — POST /providers/profile first")
    return ProviderProfileOut.model_validate(profile)


@router.post("/profile", response_model=ProviderProfileOut, status_code=201)
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
        raise HTTPException(400, "Profile already exists — use PATCH to update")

    profile = ProviderProfile(
        user_id=user.id,
        bio=data.bio,
        years_experience=data.years_experience,
        id_number=data.id_number,
        id_doc_url=data.id_doc_url,
        cert_doc_url=data.cert_doc_url,
        verification_status=VerificationStatus.pending,
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    return ProviderProfileOut.model_validate(profile)


@router.patch("/profile", response_model=ProviderProfileOut)
def update_profile(
    data: ProviderProfileCreate,
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    user = _current_user(cred, db)
    profile = db.query(ProviderProfile).filter_by(user_id=user.id).first()
    if not profile:
        raise HTTPException(404, "Profile not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    db.commit()
    db.refresh(profile)
    return ProviderProfileOut.model_validate(profile)


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


# ---------- SERVICES ----------
@router.get("/services", response_model=List[ServiceOut])
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