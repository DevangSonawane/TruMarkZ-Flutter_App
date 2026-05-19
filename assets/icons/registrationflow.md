# Organisation Registration Flow (Updated)

## 1) Signup (Org)
- Screen: Organisation Registration (`/org-registration`)
- API: `POST /auth/signup/organization`
- Request body:
```json
{
  "org_name": "string",
  "email": "user@example.com",
  "phone_number": "string",
  "password": "string"
}
```
- Notes:
  - Sends OTP to email
  - Returns `user_id`
  - Signup screen fields must be only: org name, email, phone number, password

## 2) Verify OTP
- Screen: OTP Verification (`/otp-verification`)
- API: `POST /auth/verify-otp`
- Request body:
```json
{
  "email": "user@example.com",
  "otp_code": "string"
}
```

## 3) Resend OTP
- Screen: OTP Verification (`/otp-verification`)
- API: `POST /auth/resend-otp`
- Request body:
```json
{
  "email": "user@example.com"
}
```

## 4) Login (Org)
- Screen: Login (`/login?type=organization`)
- API: `POST /auth/login`
- Response includes `requires_onboarding`:
  - If `requires_onboarding == true` → go to Org Onboarding screen
  - If `requires_onboarding == false` → go directly to Org Dashboard

## 5) Complete Onboarding (Org only)
- Screen: Org Onboarding (`/org-onboarding`)
- API: `POST /auth/onboarding`
- Request body:
```json
{
  "industry_type": ["string"],
  "gstin": "string",
  "business_reg_number": "string",
  "address_line1": "string",
  "address_line2": "string",
  "address_line3": "string",
  "use_cases": {}
}
```

