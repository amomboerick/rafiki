# data/seed_categories.py
import sys, os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.app.core.database import SessionLocal, engine, Base
from backend.app.models import ServiceCategory

CATEGORIES = [
    # (name, group, default_deposit_pct)
    ("Salon", "Beauty", 100),
    ("Barber", "Beauty", 100),
    ("Manicure & Pedicure", "Beauty", 100),
    ("Spa & Massage", "Beauty", 100),
    ("Car Wash", "Auto", 0),
    ("Car Servicing", "Auto", 0),
    ("Car Towing", "Auto", 0),
    ("Battery Jumpstart", "Auto", 0),
    ("Car Hire", "Auto", 30),
    ("Pickup Truck", "Logistics", 30),
    ("Tractor Hire", "Agriculture", 30),
    ("Mechanic", "Auto", 0),
    ("Plumber", "Home", 0),
    ("Electrician", "Home", 0),
    ("Carpentry", "Home", 0),
    ("Painting", "Home", 0),
    ("Interior Decor", "Home", 30),
    ("Masonry", "Construction", 0),
    ("Roofing", "Construction", 0),
    ("Pest Control & Fumigation", "Home", 0),
    ("Locksmith", "Home", 0),
    ("Cleaning", "Home", 0),
    ("Laundry", "Home", 0),
    ("Waste Collection", "Home", 0),
    ("Solar Installation", "Energy", 30),
    ("Borehole Drilling", "Construction", 30),
    ("Gas Cylinder Delivery", "Logistics", 0),
    ("Water Delivery", "Logistics", 0),
    ("Security Guard", "Security", 30),
    ("Pet Care", "Lifestyle", 0),
    ("Wedding Planning", "Events", 30),
    ("Catering", "Events", 30),
    ("Cake Bakers", "Events", 50),
    ("Photographers & Videographers", "Events", 30),
    ("Tent Hiring", "Events", 30),
    ("DJ & MCs", "Events", 30),
    ("Chefs", "Events", 30),
    ("Home Tuition", "Education", 0),
    ("Music Teachers", "Education", 0),
    ("Coding Tutors", "Education", 0),
    ("Swimming Lessons", "Education", 0),
    ("Chess Coaching", "Education", 0),
    ("IT Support", "Tech", 0),
    ("Tailoring", "Fashion", 50),
    ("Fitness Training", "Lifestyle", 0),
]

def slugify(s):
    return s.lower().replace(" & ", "-").replace(" ", "-")

def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    added = 0
    for name, group, deposit in CATEGORIES:
        if not db.query(ServiceCategory).filter_by(name=name).first():
            db.add(ServiceCategory(
    name=name, slug=slugify(name), category_group=group,
    default_deposit_pct=deposit
))
            added += 1
    db.commit()
    db.close()
    print(f"✅ Rafiki seeded: {added} new categories (total in file: {len(CATEGORIES)})")

if __name__ == "__main__":
    seed()