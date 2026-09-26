# backend/app/models/__init__.py
from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime, Text,
    ForeignKey, Enum, Numeric, Index
)
from sqlalchemy.orm import relationship
from backend.app.core.database import Base
import enum


# ---------- ENUMS ----------
class UserRole(str, enum.Enum):
    client = "client"
    provider = "provider"
    admin = "admin"

class VerificationStatus(str, enum.Enum):
    unverified = "unverified"
    pending = "pending"
    verified = "verified"
    rejected = "rejected"

class BookingType(str, enum.Enum):
    instant = "instant"
    scheduled = "scheduled"

class BookingStatus(str, enum.Enum):
    pending = "pending"
    accepted = "accepted"
    en_route = "en_route"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"
    disputed = "disputed"

class PaymentType(str, enum.Enum):
    full = "full"
    deposit = "deposit"

class PaymentStatus(str, enum.Enum):
    pending = "pending"
    success = "success"
    failed = "failed"
    refunded = "refunded"


# ---------- MODELS ----------
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(120), nullable=False)
    phone = Column(String(15), unique=True, index=True, nullable=False)
    email = Column(String(120), unique=True, nullable=True)
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), default=UserRole.client, nullable=False)
    county = Column(String(50), default="Nairobi")
    constituency = Column(String(80), nullable=True)   # was sub_county
    ward = Column(String(80), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    provider_profile = relationship("ProviderProfile", back_populates="user", uselist=False)
    bookings_as_client = relationship(
        "Booking", foreign_keys="Booking.client_id", back_populates="client"
    )


class ServiceCategory(Base):
    __tablename__ = "service_categories"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(80), unique=True, nullable=False)
    slug = Column(String(80), unique=True, index=True)
    category_group = Column(String(50))
    icon = Column(String(80), nullable=True)
    default_deposit_pct = Column(Integer, default=0)

    services = relationship("Service", back_populates="category")


class ProviderProfile(Base):
    __tablename__ = "provider_profiles"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    bio = Column(Text, nullable=True)
    years_experience = Column(Integer, default=0)
    verification_status = Column(Enum(VerificationStatus), default=VerificationStatus.unverified)
    id_number = Column(String(20), nullable=True)
    id_doc_url = Column(String(255), nullable=True)
    cert_doc_url = Column(String(255), nullable=True)
    # NEW: photos + location text
    photo_urls = Column(Text, nullable=True)          # JSON-encoded array of URLs
    location_text = Column(String(255), nullable=True)  # "Westlands, Nairobi"
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    avg_rating = Column(Float, default=0.0)
    total_reviews = Column(Integer, default=0)
    total_bookings = Column(Integer, default=0)
    is_available = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="provider_profile")
    services = relationship("Service", back_populates="provider")


class Service(Base):
    __tablename__ = "services"
    id = Column(Integer, primary_key=True, index=True)
    provider_id = Column(Integer, ForeignKey("provider_profiles.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("service_categories.id"), nullable=False)
    title = Column(String(120), nullable=False)
    description = Column(Text, nullable=True)
    base_price = Column(Numeric(10, 2), nullable=False)
    price_unit = Column(String(30), default="per job")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    provider = relationship("ProviderProfile", back_populates="services")
    category = relationship("ServiceCategory", back_populates="services")

    __table_args__ = (
        Index("ix_service_cat_price", "category_id", "base_price"),
    )


class Booking(Base):
    __tablename__ = "bookings"
    id = Column(Integer, primary_key=True, index=True)
    reference = Column(String(20), unique=True, index=True)
    client_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    provider_id = Column(Integer, ForeignKey("provider_profiles.id"), nullable=False)
    service_id = Column(Integer, ForeignKey("services.id"), nullable=False)
    booking_type = Column(Enum(BookingType), default=BookingType.instant)
    status = Column(Enum(BookingStatus), default=BookingStatus.pending)
    scheduled_at = Column(DateTime, nullable=True)
    address = Column(String(255), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    total_amount = Column(Numeric(10, 2), nullable=False)
    # NEW: rating captured after service completes
    rating = Column(Integer, nullable=True)
    rating_comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    client = relationship("User", foreign_keys=[client_id], back_populates="bookings_as_client")
    payments = relationship("Payment", back_populates="booking")
    review = relationship("Review", back_populates="booking", uselist=False)


class Payment(Base):
    __tablename__ = "payments"
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False)
    payment_type = Column(Enum(PaymentType), default=PaymentType.full)
    amount = Column(Numeric(10, 2), nullable=False)
    phone = Column(String(15), nullable=False)
    mpesa_receipt = Column(String(40), nullable=True)
    merchant_request_id = Column(String(60), nullable=True)
    checkout_request_id = Column(String(60), nullable=True)
    status = Column(Enum(PaymentStatus), default=PaymentStatus.pending)
    created_at = Column(DateTime, default=datetime.utcnow)

    booking = relationship("Booking", back_populates="payments")


class Review(Base):
    __tablename__ = "reviews"
    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), unique=True, nullable=False)
    client_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    provider_id = Column(Integer, ForeignKey("provider_profiles.id"), nullable=False)
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    booking = relationship("Booking", back_populates="review")


class Notification(Base):
    __tablename__ = "notifications"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    channel = Column(String(20))
    title = Column(String(120))
    body = Column(Text)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)