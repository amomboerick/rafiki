# backend/app/schemas/__init__.py
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


# ---- USER ----
class UserRegister(BaseModel):
    full_name: str
    phone: str = Field(..., pattern=r"^2547\d{8}$", description="Format: 2547XXXXXXXX")
    email: Optional[str] = None
    password: str = Field(..., min_length=6)
    role: str = "client"
    county: str = "Nairobi"
    sub_county: Optional[str] = None

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

class ProviderProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    user_id: int
    bio: Optional[str]
    years_experience: int
    verification_status: str
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
    created_at: datetime


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