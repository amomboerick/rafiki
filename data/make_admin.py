# data/make_admin.py
"""
Promote any registered user to admin.
Usage:
  python data/make_admin.py 254712345678
"""
import sys, os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.app.core.database import SessionLocal
from backend.app.models import User, UserRole


def promote(phone: str):
    db = SessionLocal()
    u = db.query(User).filter_by(phone=phone).first()
    if not u:
        print(f"❌ No user with phone {phone}")
        db.close()
        return
    u.role = UserRole.admin
    db.commit()
    print(f"✅ {u.full_name} ({u.phone}) is now an ADMIN")
    db.close()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python data/make_admin.py 2547XXXXXXXX")
        sys.exit(1)
    promote(sys.argv[1])