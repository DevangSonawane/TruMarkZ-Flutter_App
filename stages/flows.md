🚀 ENTRY FLOW
Splash → Onboarding → Login/Register → Role Selection
                                              |
                    ┌─────────────────────────┼─────────────────────┐
                    ↓                         ↓                     ↓
             Organisation               Individual            Just Verifying

🏢 ORGANISATION FLOW
Organisation
    ↓
Organisation Registration
(name, industry, address, GST, reg no., email OTP, mobile)
    ↓
OTP Verification
(6-digit email OTP)
    ↓
Pending Approval
(waiting for Super Admin)
    ↓
[Admin Approves]
    ↓
Dashboard
(Home tab)
    ↓
NEW BATCH button / FAB +
    ↓
Verification Plan Setup
(industry select → check selection → cost breakdown → permission setting)
    ↓
Bulk Upload Page
(download Excel template → fill → upload Excel + photos ZIP → preview → name batch)
    ↓
Credential Template Selector
(T1 / T2 / T3 / T4 / T5 / T6)
    ↓
Map Credential Fields
(pick 5-6 fields to show on card face → preview)
    ↓
[Background batch job runs]
API Checks auto (Aadhaar, PAN, DL, Education, Employment)
    +
Human Checks assigned to verifier agency by Super Admin
    ↓
Credentials Generated (success screen)
    ↓
Batch Tracking Detail
(live progress — 24/80 complete — per record status)
    ↓
Individual Record Detail
(all checks, evidence, on-chain proof, dispute button)
    ↓
Credential Detail
(final issued credential — QR, hash, fields)

📊 DASHBOARD TABS (Bottom Nav)
Dashboard (Home)
    ├── Home tab (index 0) → Dashboard
    ├── Batches tab (index 1) → Batch Progress → Batch Tracking Detail → Individual Record Detail
    ├── FAB + (centre) → Verification Plan Setup (new batch flow)
    ├── Registry tab (index 3) → Registry Search → Public Verification Result
    └── Profile tab (index 4) → Profile Settings
                                      ├── Notifications
                                      ├── Identity Wallet → Credential Wallet → Credential Detail
                                      └── Theme toggle (Light / Dark)

👤 INDIVIDUAL FLOW
Individual
    ↓
Individual Registration
(same login — individual account type)
    ↓
Skill Tree Page
(sections: Education / Courses / Work Experience / Skills)
    ↓
Add item to each section
(institution, year, upload certificate)
    ↓
Submit for verification
    ├── API check (NAD for degree etc.)
    └── Human check (small institute certs etc.)
    ↓
Node verified → green tick + credential ID
    ↓
Tap node → Individual Record Detail
(full verification report + blockchain proof)
    ↓
Share Skill Tree
    ├── Link
    ├── PDF (tappable QR on each node)
    └── WhatsApp / Email

🔍 JUST VERIFYING FLOW
Just Verifying
    ↓
Registry Search
(search by name / credential ID / DOB / licence no.)
    ↓
Result card → Public Verification Result
    ├── VERIFIED / EXPIRED / REVOKED badge
    ├── Per-check breakdown (Identity ✓ Address ✓ Police ✓)
    ├── Basic info → FREE
    └── Full report → ₹5-10 Razorpay payment
              ↓
         Full Report Download

    OR

QR Scanner (from nav or direct)
    ↓
Scan QR on credential
    ↓
Bottom sheet → Confirm
    ↓
Public Verification Result
(same as above)

🛡️ SUPER ADMIN FLOW
Login (admin credentials)
    ↓
Super Admin Dashboard
    ├── Pending Org Approvals
    │       ↓
    │   Organisation Approval Detail
    │   (review GST + docs)
    │       ├── Approve → org gets email → PendingApprovalPage flips to approved
    │       └── Reject → org gets rejection email → can re-submit
    │
    ├── Batch Monitoring
    │       ↓
    │   Batch Monitoring Detail
    │   (live: org, verifier, records, SLA deadline, % complete)
    │       ↓
    │   [30% SLA remaining] → auto alert email to verifier + red flag on dashboard
    │       ↓
    │   Activate Project → org notified verification has begun
    │
    ├── Verifier Management (missing screen)
    │   (set cost per check / assign agency per check type + location)
    │
    └── Dispute Resolution (missing screen)
        (org or verifier raises issue → admin rules → record updated)








SplashPage
└── OnboardingPage
    └── LoginPage
        └── RoleSelectionPage
            ├── OrganisationRegistrationPage
            │   └── OtpVerificationPage
            │       └── PendingApprovalPage
            │           └── DashboardPage [SHELL START]
            │               ├── BatchProgressPage
            │               │   └── BatchTrackingDetailPage
            │               │       └── IndividualRecordDetailPage
            │               │           └── CredentialDetailPage
            │               ├── VerificationPlanSetupPage (FAB)
            │               │   └── BulkUploadPage
            │               │       └── CredentialTemplateSelectorPage
            │               │           └── MapCredentialFieldsPage
            │               │               └── CredentialsGeneratedPage
            │               │                   └── BatchTrackingDetailPage
            │               ├── RegistrySearchPage
            │               │   └── PublicVerificationResultPage
            │               ├── QRScannerPage
            │               │   └── PublicVerificationResultPage
            │               └── ProfileSettingsPage
            │                   ├── NotificationCentrePage
            │                   └── CredentialWalletPage
            │                       └── CredentialDetailPage
            │
            ├── SkillTreePage [NO SHELL — missing]
            │   └── IndividualRecordDetailPage
            │       └── CredentialDetailPage
            │
            └── RegistrySearchPage [NO SHELL — missing]
                └── PublicVerificationResultPage

SuperAdminDashboardPage [UNREACHABLE — no route from login]
    ├── OrganisationApprovalDetailPage
    └── BatchMonitoringDetailPage