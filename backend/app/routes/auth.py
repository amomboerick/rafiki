# backend/app/routes/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.core.security import hash_password, verify_password, create_access_token
from backend.app.models import User, UserRole
from backend.app.schemas import UserRegister, UserLogin, TokenOut, UserOut

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenOut, status_code=201)
def register(data: UserRegister, db: Session = Depends(get_db)):
    if db.query(User).filter_by(phone=data.phone).first():
        raise HTTPException(400, "Phone already registered")

    role = UserRole.provider if data.role == "provider" else UserRole.client
    user = User(
        full_name=data.full_name,
        phone=data.phone,
        email=data.email,
        hashed_password=hash_password(data.password),
        role=role,
        county=data.county,
        constituency=data.constituency,     # ← renamed from sub_county
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return TokenOut(access_token=token, user=UserOut.model_validate(user))


@router.post("/login", response_model=TokenOut)
def login(data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter_by(phone=data.phone).first()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid credentials")
    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return TokenOut(access_token=token, user=UserOut.model_validate(user))