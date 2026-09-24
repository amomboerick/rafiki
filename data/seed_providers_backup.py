# data/seed_providers.py
"""
Seeds 20 fake Rafiki providers across Nairobi with services in various categories.
Run AFTER seed_categories.py
"""
import sys, os, random
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.app.core.database import SessionLocal, engine, Base
from backend.app.core.security import hash_password
from backend.app.models import (
    User, UserRole, ProviderProfile, VerificationStatus,
    Service, ServiceCategory
)

random.seed(42)

FIRST_NAMES = ["John", "Mary", "Peter", "Grace", "David", "Faith", "James", "Mercy",
               "Samuel", "Esther", "Brian", "Lydia", "Kevin", "Nancy", "Dennis",
               "Joyce", "Felix", "Winnie", "Anthony", "Beatrice"]
LAST_NAMES  = ["Mwangi", "Otieno", "Kamau", "Wanjiru", "Kimani", "Achieng", "Kiptoo",
               "Njoroge", "Onyango", "Mutua", "Wafula", "Cheruiyot", "Odhiambo",
               "Karanja", "Mwende", "Barasa", "Njeri", "Kilonzo", "Wambui", "Ouma"]

SUB_COUNTIES = ["Westlands", "Kasarani", "Embakasi", "Langata", "Dagoretti",
                "Kibra", "Roysambu", "Starehe", "Makadara", "Kamukunji"]

# Category slug → sample service titles with price ranges (KES)
SERVICE_TEMPLATES = {
    "salon":                     [("Bridal hair & makeup", 3500, 8000), ("Braiding", 1500, 4000)],
    "barber":                    [("Men's haircut at home", 300, 800), ("Beard trim", 200, 500)],
    "manicure-pedicure":         [("Classic manicure", 800, 1500), ("Gel pedicure", 1200, 2500)],
    "spa-massage":               [("Full body massage", 2500, 6000), ("Deep tissue", 3000, 7000)],
    "car-wash":                  [("Exterior wash", 300, 600), ("Full detail", 1500, 4000)],
    "car-servicing":             [("Minor service", 3500, 8000), ("Full service", 8000, 15000)],
    "car-towing":                [("Tow within Nairobi", 3000, 7000), ("Long distance tow", 8000, 20000)],
    "battery-jumpstart":         [("Emergency jumpstart", 500, 1500)],
    "car-hire":                  [("Self-drive per day", 4000, 12000), ("With driver per day", 6000, 15000)],
    "pickup-truck":              [("House move (within Nairobi)", 5000, 15000), ("Delivery", 2000, 8000)],
    "tractor-hire":              [("Ploughing per acre", 3500, 6000), ("Harrowing per acre", 2500, 5000)],
    "mechanic":                  [("Diagnostics", 1000, 2500), ("Brake repair", 2000, 6000)],
    "plumber":                   [("Tap repair", 500, 1500), ("Pipe installation", 2000, 8000)],
    "electrician":               [("Socket install", 800, 2000), ("Wiring (per room)", 1500, 4000)],
    "carpentry":                 [("Custom wardrobe", 15000, 60000), ("Door repair", 1500, 4000)],
    "painting":                  [("Room painting", 8000, 25000), ("Exterior painting", 20000, 80000)],
    "interior-decor":            [("Living room styling", 15000, 50000)],
    "masonry":                   [("Wall construction per sqm", 1200, 2500)],
    "roofing":                   [("Roof repair per sqm", 800, 2000), ("New roof per sqm", 1500, 3500)],
    "pest-control-fumigation":   [("House fumigation", 3000, 8000), ("Termite treatment", 8000, 25000)],
    "locksmith":                 [("Lock change", 1500, 4000), ("Emergency unlock", 2000, 5000)],
    "cleaning":                  [("House deep clean", 2500, 8000), ("Sofa cleaning", 1500, 4000)],
    "laundry":                   [("Per kg laundry", 100, 250), ("Ironing per item", 50, 150)],
    "waste-collection":          [("Monthly household", 800, 2000)],
    "solar-installation":        [("Home solar system", 40000, 150000)],
    "borehole-drilling":         [("Borehole survey", 15000, 40000), ("Drilling per meter", 5000, 12000)],
    "gas-cylinder-delivery":     [("6kg refill", 1200, 1500), ("13kg refill", 2600, 3200)],
    "water-delivery":            [("Water bowser 10,000L", 8000, 15000)],
    "security-guard":            [("Day guard monthly", 20000, 35000), ("Night guard monthly", 22000, 38000)],
    "pet-care":                  [("Dog walking", 500, 1200), ("Pet grooming", 1500, 4000)],
    "wedding-planning":          [("Full wedding planning", 80000, 300000)],
    "catering":                  [("Per plate buffet", 600, 1500), ("Live cooking per plate", 1200, 2500)],
    "cake-bakers":               [("Birthday cake", 2500, 8000), ("Wedding cake", 15000, 60000)],
    "photographers-videographers": [("Event photography", 20000, 80000), ("Wedding videography", 50000, 150000)],
    "tent-hiring":               [("Tent per day", 3000, 15000)],
    "dj-mcs":                    [("DJ per event", 15000, 40000), ("MC per event", 10000, 30000)],
    "chefs":                     [("Private chef per day", 3000, 8000)],
    "home-tuition":              [("Maths tutoring per hour", 500, 1500), ("Sciences per hour", 600, 1800)],
    "music-teachers":            [("Piano lessons per hour", 800, 2000), ("Guitar lessons per hour", 700, 1800)],
    "coding-tutors":             [("Python for kids per hour", 800, 2000)],
    "swimming-lessons":          [("Private swimming per hour", 1000, 2500)],
    "chess-coaching":            [("Chess lesson per hour", 600, 1500)],
    "it-support":                [("Network setup", 3000, 10000), ("PC repair", 1500, 5000)],
    "tailoring":                 [("Custom dress", 3000, 15000), ("Suit", 8000, 35000)],
    "fitness-training":          [("Personal training per session", 1000, 3000)],
}


def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # Load categories into a dict
    cats = {c.slug: c for c in db.query(ServiceCategory).all()}
    cat_slugs = list(SERVICE_TEMPLATES.keys())

    created_providers = 0
    created_services = 0

    for i in range(20):
        phone = f"2547{70000000 + i:08d}"   # 2547XXXXXXXX
        if db.query(User).filter_by(phone=phone).first():
            continue

        first = FIRST_NAMES[i % len(FIRST_NAMES)]
        last  = LAST_NAMES[i % len(LAST_NAMES)]
        sub   = SUB_COUNTIES[i % len(SUB_COUNTIES)]

        user = User(
            full_name=f"{first} {last}",
            phone=phone,
            hashed_password=hash_password("fundi2026"),
            role=UserRole.provider,
            county="Nairobi",
            sub_county=sub,
        )
        db.add(user)
        db.flush()   # get user.id

        verified = i % 3 != 0    # ~2/3 verified
        profile = ProviderProfile(
            user_id=user.id,
            bio=f"Experienced {first} offering quality services in {sub} and around Nairobi.",
            years_experience=random.randint(1, 15),
            verification_status=VerificationStatus.verified if verified else VerificationStatus.pending,
            avg_rating=round(random.uniform(3.5, 5.0), 2),
            total_reviews=random.randint(5, 200),
            total_bookings=random.randint(10, 500),
        )
        db.add(profile)
        db.flush()

        # Give each provider 1-3 services from random categories
        cats_for_provider = random.sample(cat_slugs, k=random.randint(1, 3))
        for slug in cats_for_provider:
            cat = cats.get(slug)
            if not cat:
                continue
            for title, lo, hi in SERVICE_TEMPLATES[slug]:
                price = random.randint(lo, hi)
                svc = Service(
                    provider_id=profile.id,
                    category_id=cat.id,
                    title=title,
                    description=f"{title} by {first} — professional and reliable.",
                    base_price=price,
                    price_unit="per job",
                )
                db.add(svc)
                created_services += 1

        created_providers += 1

    db.commit()
    db.close()
    print(f"✅ Seeded {created_providers} providers and {created_services} services")


if __name__ == "__main__":
    seed()