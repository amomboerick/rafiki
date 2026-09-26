# backend/app/routes/search.py
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session, joinedload
from backend.app.core.database import get_db
from backend.app.models import (
    ServiceCategory, Service, ProviderProfile, User, VerificationStatus
)
from backend.app.schemas import CategoryOut

router = APIRouter(prefix="/search", tags=["Search"])


@router.get("/categories", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    return db.query(ServiceCategory).order_by(ServiceCategory.name).all()


@router.get("/services")
def search_services(
    q: Optional[str] = None,
    category: Optional[str] = None,
    county: Optional[str] = None,
    constituency: Optional[str] = None,      # ← renamed from sub_county
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    min_rating: Optional[float] = None,
    verified_only: bool = False,
    sort: str = Query("rating_desc", pattern="^(rating_desc|price_asc|price_desc|newest)$"),
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db),
):
    query = (
        db.query(Service)
        .join(ProviderProfile, Service.provider_id == ProviderProfile.id)
        .join(User, ProviderProfile.user_id == User.id)
        .join(ServiceCategory, Service.category_id == ServiceCategory.id)
        .options(joinedload(Service.provider).joinedload(ProviderProfile.user),
                 joinedload(Service.category))
        .filter(Service.is_active == True)
    )

    # Text search: service title, category name, group, description
    if q:
        pattern = f"%{q}%"
        query = query.filter(
            Service.title.ilike(pattern) |
            ServiceCategory.name.ilike(pattern) |
            ServiceCategory.category_group.ilike(pattern) |
            Service.description.ilike(pattern)
        )

    if category:
        query = query.filter(
            (ServiceCategory.slug == category) | (ServiceCategory.name.ilike(category))
        )
    if county:
        query = query.filter(User.county.ilike(county))
    if constituency:
        query = query.filter(User.constituency.ilike(constituency))    # ← renamed
    if min_price is not None:
        query = query.filter(Service.base_price >= min_price)
    if max_price is not None:
        query = query.filter(Service.base_price <= max_price)
    if min_rating is not None:
        query = query.filter(ProviderProfile.avg_rating >= min_rating)
    if verified_only:
        query = query.filter(ProviderProfile.verification_status == VerificationStatus.verified)

    sort_map = {
        "rating_desc": ProviderProfile.avg_rating.desc(),
        "price_asc": Service.base_price.asc(),
        "price_desc": Service.base_price.desc(),
        "newest": Service.created_at.desc(),
    }
    query = query.order_by(sort_map[sort]).offset(offset).limit(limit)

    results = []
    for s in query.all():
        p = s.provider
        results.append({
            "service_id": s.id,
            "title": s.title,
            "price": float(s.base_price),
            "price_unit": s.price_unit,
            "category": s.category.name,
            "provider": {
                "id": p.id,
                "name": p.user.full_name,
                "county": p.user.county,
                "constituency": p.user.constituency,    # ← renamed
                "sub_county": p.user.constituency,      # keep for backwards compat with Flutter
                "rating": p.avg_rating,
                "reviews": p.total_reviews,
                "verified": p.verification_status == VerificationStatus.verified,
                "whatsapp": p.user.phone,
            }
        })
    return {"count": len(results), "results": results}