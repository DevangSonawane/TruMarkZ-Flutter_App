TruMarkZ API Documentation
Base URL: https://trumarkz-api-54038467488.asia-south1.run.app
 Version: 1.0.0
 Authentication: Bearer JWT Token

Overview
TruMarkZ API supports three user roles:
individual — Individual users
organization — Organization accounts
super_admin — Platform administrators
All protected endpoints require:
Authorization: Bearer <access_token>


Authentication Endpoints

1. Register Individual
POST /auth/register/individual
Registers a new individual user. Sends OTP to email (and mobile if provided).
Request Body:
{
  "full_name": "John Doe",
  "email": "john@example.com",
  "mobile": "9876543210",
  "address": "123 Main St, Mumbai",
  "password": "Min8Chars@"
}

Field
Type
Required
Description
full_name
string
✅
Full name of user
email
string
✅
Valid email address
mobile
string
❌
10-15 digit mobile number
address
string
✅
Full address
password
string
✅
Minimum 8 characters

Response 200:
{
  "message": "Registration initiated. Please verify your email OTP.",
  "data": {
    "user_id": "uuid"
  }
}

Error Responses:
Code
Message
400
Email already registered
400
Mobile already registered
422
Validation error


2. Register Organization
POST /auth/register/organization
Registers a new organization. Sends OTP to official email (and mobile if provided).
Request Body:
{
  "organization_name": "Acme Pvt Ltd",
  "gst_number": "27ABCDE1234F1Z5",
  "business_registration_number": "U74999MH2020PTC123456",
  "address": "456 Business Park, Mumbai",
  "email": "contact@acme.com",
  "mobile": "9876543210",
  "password": "Min8Chars@"
}

Field
Type
Required
Description
organization_name
string
✅
Legal name of organization
gst_number
string
✅
Valid GST number (15 chars)
business_registration_number
string
✅
CIN or registration number
address
string
✅
Registered business address
email
string
✅
Official email (used for login)
mobile
string
❌
10-15 digit mobile number
password
string
✅
Minimum 8 characters

Response 200:
{
  "message": "Registration initiated. Please verify your email OTP.",
  "data": {
    "user_id": "uuid"
  }
}

Error Responses:
Code
Message
400
Email already registered
400
Mobile already registered
422
Invalid GST number format


3. Verify OTP
POST /auth/verify-otp
Verifies email or mobile OTP after registration or forgot password.
 On successful email verification, user storage folder is created automatically.
Request Body:
{
  "identifier": "john@example.com",
  "otp_code": "123456",
  "purpose": "registration"
}

Field
Type
Required
Description
identifier
string
✅
Email or mobile number
otp_code
string
✅
6-digit OTP
purpose
string
✅
registration or forgot_password

Response 200:
{
  "message": "OTP verified successfully"
}

Error Responses:
Code
Message
400
Invalid or expired OTP

Note: OTP expires in 10 minutes. User must verify email OTP to activate account.

4. Login
POST /auth/login
Authenticates user and returns JWT access token.
Request Body:
{
  "login_type": "individual",
  "email_or_mobile": "john@example.com",
  "password": "Min8Chars@",
  "remember_me": false
}

Field
Type
Required
Description
login_type
string
✅
individual, organization, or super_admin
email_or_mobile
string
✅
Registered email or mobile
password
string
✅
Account password
remember_me
boolean
❌
Default false. true = 7 day token, false = 1 hour token

Response 200:
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user_id": "uuid",
  "login_type": "individual"
}

Error Responses:
Code
Message
401
Invalid credentials
401
Invalid login type for this account
403
Account is inactive
403
Account not verified. Please verify your email OTP first.


5. Forgot Password
POST /auth/forgot-password
Sends password reset link to registered email.
Request Body:
{
  "email_or_mobile": "john@example.com"
}

Response 200:
{
  "message": "If this account exists, a reset link has been sent.",
  "data": {
    "reset_token": "token_string"
  }
}

Note: Always returns 200 to prevent user enumeration. Reset token expires in 30 minutes.

6. Reset Password
POST /auth/reset-password
Resets user password using token from forgot password response.
Request Body:
{
  "token": "reset_token_from_email",
  "new_password": "NewPass@1234"
}

Field
Type
Required
Description
token
string
✅
Token received from forgot password
new_password
string
✅
Minimum 8 characters

Response 200:
{
  "message": "Password reset successfully"
}

Error Responses:
Code
Message
400
Invalid or expired reset token


7. Get Current User
GET /auth/me
Returns profile of currently authenticated user.
Headers:
Authorization: Bearer <access_token>

Response 200:
{
  "id": "uuid",
  "login_type": "individual",
  "full_name": "John Doe",
  "email": "john@example.com",
  "mobile": "9876543210",
  "organization_name": null,
  "is_active": true,
  "is_verified": true,
  "email_verified": true,
  "mobile_verified": true,
  "storage_path": "users/uuid/"
}

Error Responses:
Code
Message
401
Invalid or expired token
403
Account is inactive


Organization Endpoints
All organization endpoints require a valid JWT token with login_type: organization.

8. Assign Existing Individual
POST /auth/org/assign-individual
Links an existing individual user to the organization. Creates a nested storage folder.
Headers:
Authorization: Bearer <org_access_token>

Request Body:
{
  "individual_email_or_mobile": "john@example.com"
}

Response 200:
{
  "message": "Individual assigned successfully",
  "data": {
    "assignment_id": "uuid",
    "storage_path": "organizations/org_id/individuals/individual_id/"
  }
}

Error Responses:
Code
Message
403
Only organizations can perform this action
404
Individual not found
400
User is not an individual


9. Invite New Individual
POST /auth/org/invite-individual
Sends an invitation link to a new user (not yet registered).
Headers:
Authorization: Bearer <org_access_token>

Request Body:
{
  "email": "newuser@example.com",
  "mobile": "9876543210"
}

Field
Type
Required
Description
email
string
❌
Email to send invite link
mobile
string
❌
Mobile to send invite SMS

At least one of email or mobile must be provided.
Response 200:
{
  "message": "Invitation sent successfully",
  "data": {
    "invite_token": "token_string"
  }
}

Invite link: https://trumarkz.asynk.in/register?invite=<token> — valid for 7 days.

10. Get Assigned Individuals
GET /auth/org/individuals
Returns list of all individuals assigned to the organization.
Headers:
Authorization: Bearer <org_access_token>

Response 200:
{
  "message": "Individuals fetched",
  "data": {
    "individuals": [
      {
        "assignment_id": "uuid",
        "individual_id": "uuid",
        "storage_path": "organizations/org_id/individuals/individual_id/",
        "status": "active",
        "assigned_at": "2026-05-10 13:00:00+00:00"
      }
    ]
  }
}


Storage Structure
Each user gets a dedicated GCS folder on email verification:
trumarkz-storage/
├── users/
│   └── {individual_id}/
│       ├── profile/
│       └── documents/
└── organizations/
    └── {org_id}/
        ├── profile/
        ├── documents/
        └── individuals/
            └── {individual_id}/


Error Format
All errors follow this format:
{
  "detail": "Error message here"
}


OTP Flow
Register → OTP sent to email + mobile
         → POST /auth/verify-otp (email)   ← required to activate account
         → POST /auth/verify-otp (mobile)  ← optional but recommended
         → POST /auth/login


Token Info
Type
Expiry
Normal login
1 hour
Remember me
7 days
OTP
10 minutes
Reset token
30 minutes
Invite token
7 days


Swagger UI
Interactive API documentation available at:
https://trumarkz-api-54038467488.asia-south1.run.app/docs


Health Check
GET /health
{ "status": "healthy" }


