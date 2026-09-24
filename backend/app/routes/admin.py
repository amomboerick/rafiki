# backend/app/routes/admin.py
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.core.security import decode_token
from backend.app.models import (
    User, UserRole, ProviderProfile, VerificationStatus
)
from backend.app.schemas import ProviderProfileOut, VerifyAction

router = APIRouter(prefix="/admin", tags=["Admin"])
bearer = HTTPBearer(auto_error=False)


def _require_admin(cred: HTTPAuthorizationCredentials, db: Session) -> User:
    if not cred:
        raise HTTPException(401, "Not authenticated")
    payload = decode_token(cred.credentials)
    if not payload:
        raise HTTPException(401, "Invalid token")
    user = db.query(User).get(int(payload["sub"]))
    if not user or user.role != UserRole.admin:
        raise HTTPException(403, "Admin only")
    return user


@router.get("/queue", response_model=List[ProviderProfileOut])
def verification_queue(
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    _require_admin(cred, db)
    return (
        db.query(ProviderProfile)
        .filter(ProviderProfile.verification_status == VerificationStatus.pending)
        .order_by(ProviderProfile.created_at.desc())
        .all()
    )


@router.post("/verify/{provider_id}", response_model=ProviderProfileOut)
def verify_provider(
    provider_id: int,
    action: VerifyAction,
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    _require_admin(cred, db)
    profile = db.query(ProviderProfile).get(provider_id)
    if not profile:
        raise HTTPException(404, "Provider not found")
    profile.verification_status = VerificationStatus(action.verification_status)
    db.commit()
    db.refresh(profile)
    return ProviderProfileOut.model_validate(profile)


@router.get("/stats")
def admin_stats(
    cred: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
):
    _require_admin(cred, db)
    from backend.app.models import Service, Booking
    return {
        "users": db.query(User).count(),
        "providers": db.query(ProviderProfile).count(),
        "services": db.query(Service).count(),
        "bookings": db.query(Booking).count(),
        "pending_verification": db.query(ProviderProfile)
            .filter(ProviderProfile.verification_status == VerificationStatus.pending).count(),
        "verified": db.query(ProviderProfile)
            .filter(ProviderProfile.verification_status == VerificationStatus.verified).count(),
    }