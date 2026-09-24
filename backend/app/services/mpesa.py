# backend/app/services/mpesa.py
"""Safaricom Daraja - STK Push (Lipa Na M-Pesa Online)"""
import base64
import requests
from datetime import datetime, timedelta, timezone
from backend.app.core.config import settings

# Kenya is UTC+3 (East Africa Time), no DST
EAT = timezone(timedelta(hours=3))


class MpesaClient:
    def __init__(self):
        self.consumer_key = settings.MPESA_CONSUMER_KEY
        self.consumer_secret = settings.MPESA_CONSUMER_SECRET
        self.shortcode = settings.MPESA_SHORTCODE
        self.passkey = settings.MPESA_PASSKEY
        self.base_url = "https://sandbox.safaricom.co.ke"

    def _auth_token(self) -> str:
        url = f"{self.base_url}/oauth/v1/generate?grant_type=client_credentials"
        r = requests.get(url, auth=(self.consumer_key, self.consumer_secret), timeout=15)
        r.raise_for_status()
        return r.json()["access_token"]

    def _password(self) -> tuple:
        # Use Kenya time (UTC+3) for the timestamp
        ts = datetime.now(EAT).strftime("%Y%m%d%H%M%S")
        raw = f"{self.shortcode}{self.passkey}{ts}"
        pwd = base64.b64encode(raw.encode()).decode()
        return pwd, ts

    def stk_push(self, phone: str, amount: int, booking_ref: str, callback_url: str = None) -> dict:
        token = self._auth_token()
        pwd, ts = self._password()

        cb = callback_url or settings.MPESA_CALLBACK_URL or "https://example.com/callback"

        payload = {
            "BusinessShortCode": self.shortcode,
            "Password": pwd,
            "Timestamp": ts,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": amount,
            "PartyA": phone,
            "PartyB": self.shortcode,
            "PhoneNumber": phone,
            "CallBackURL": cb,
            "AccountReference": booking_ref,
            "TransactionDesc": f"Rafiki booking {booking_ref}",
        }
        headers = {"Authorization": f"Bearer {token}"}
        r = requests.post(
            f"{self.base_url}/mpesa/stkpush/v1/processrequest",
            json=payload, headers=headers, timeout=30
        )
        return r.json()


mpesa_client = MpesaClient()