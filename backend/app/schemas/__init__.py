# backend/app/schemas/__init__.py
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


# ---- USER ----
class UserRegister(BaseModel):
    full_name: str
    phone: str = Field(..., pattern=r"^2547\d{8}$")
    email: Optional[str] = None
    password: str = Field(..., min_length=6)
    role: str = "client"
    county: str = "Nairobi"
    constituency: Optional[str] = None

class UserLogin(BaseModel):
    phone: str
    password: str

class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    full_name: str
    phone: str
    role: str
    county: str

class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


# ---- CATEGORY ----
class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    slug: str
    category_group: Optional[str] = None
    default_deposit_pct: int = 0


# ---- PROVIDER ----
class ProviderProfileCreate(BaseModel):
    bio: Optional[str] = None
    years_experience: int = 0
    id_number: Optional[str] = None
    id_doc_url: Optional[str] = None
    cert_doc_url: Optional[str] = None
    location_text: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class ProviderProfileUpdate(BaseModel):
    bio: Optional[str] = None
    years_experience: Optional[int] = None
    location_text: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    photo_urls: Optional[List[str]] = None
    is_available: Optional[bool] = None

class ProviderProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    user_id: int
    bio: Optional[str]
    years_experience: int
    verification_status: str
    location_text: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    avg_rating: float
    total_reviews: int
    total_bookings: int
    is_available: bool


class ServiceCreate(BaseModel):
    category_id: int
    title: str = Field(..., min_length=3, max_length=120)
    description: Optional[str] = None
    base_price: float = Field(..., gt=0)
    price_unit: str = "per job"

class ServiceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    provider_id: int
    category_id: int
    title: str
    description: Optional[str]
    base_price: float
    price_unit: str
    is_active: bool
    created_at: datetime


# ---- ADMIN ----
class VerifyAction(BaseModel):
    verification_status: str = Field(..., pattern="^(verified|rejected|pending|unverified)$")
    note: Optional[str] = None


# ---- BOOKING ----
class BookingCreate(BaseModel):
    service_id: int
    booking_type: str = "instant"
    scheduled_at: Optional[datetime] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    notes: Optional[str] = None

class BookingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    reference: str
    client_id: int
    provider_id: int
    service_id: int
    booking_type: str
    status: str
    scheduled_at: Optional[datetime]
    total_amount: float
    rating: Optional[int] = None
    rating_comment: Optional[str] = None
    created_at: datetime


# ---- REVIEW ----
class ReviewCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None


# ---- PAYMENT ----
class STKPushRequest(BaseModel):
    booking_reference: str
    payment_type: str = "full"
    phone: str = Field(..., pattern=r"^2547\d{8}$")

class STKPushResponse(BaseModel):
    checkout_request_id: Optional[str]
    merchant_request_id: Optional[str]
    customer_message: str
    success: bool