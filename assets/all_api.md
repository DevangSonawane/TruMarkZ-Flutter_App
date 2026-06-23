TruMarkZ API
 1.0.0 
OAS 3.1
/openapi.json
TruMarkZ Backend API

Authorize
Authentication


POST
/auth/signup/organization
Signup Organization


POST
/auth/signup/individual
Signup Individual


POST
/auth/verify-otp
Verify Otp


POST
/auth/resend-otp
Resend Otp


POST
/auth/login
Login


GET
/auth/google/url
Get Google Auth Url


GET
/auth/google/callback
Google Oauth Callback


POST
/auth/google
Google Auth


POST
/auth/complete-google-signup
Complete Google Signup



POST
/auth/onboarding
Complete Onboarding



GET
/auth/me
Get User Details



POST
/auth/forgot-password
Forgot Password


POST
/auth/reset-password
Reset Password


GET
/auth/users/grouped
List Users Grouped By Org



POST
/auth/promote-super-admin
Promote Super Admin



POST
/auth/create-super-admin
Create Super Admin



GET
/auth/organization/{org_id}/industry-type
Fetch Organization Industry Type



GET
/auth/users
Get Users List



POST
/auth/users
Create User



PATCH
/auth/users/{user_id}
Update User



DELETE
/auth/users/{user_id}
Deactivate User



GET
/auth/audit-logs/{batch_user_id}
Fetch Audit Logs


Verification


GET
/verification/categories
Get All Product Categories


POST
/verification/single/human
Upload Single Human



POST
/verification/single/product
Upload Single Product



POST
/verification/bulk-upload
Bulk Upload Humans from Excel



POST
/verification/upload/document
Upload Document


POST
/verification/upload/photo
Upload Photo


GET
/verification/all
Get Verifications



GET
/verification/user/{user_id}
Get Single Verification



PATCH
/verification/user/{user_id}/status
Update Status



POST
/verification/user/{user_id}/generate-qr
Generate Qr Pdf



POST
/verification/products/template
Generate Product Excel Template



POST
/verification/bulk-upload/products
Bulk Upload Products from Excel or CSV



POST
/verification/verification/automatic/{verification_type_name}/{user_id}
Mock Verify User



POST
/verification/generate-human-template
Generate Human Template



POST
/verification/templates
Save Template



GET
/verification/templates/{template_id}
Get Template



PUT
/verification/templates/{template_id}
Update Template



GET
/verification/templates/{template_id}/history
Get Template History



GET
/verification/batches
List Batches



GET
/verification/batches/{batch_id}
Get Batch Details



GET
/verification/batches/{batch_id}/third-party-verifiers
Get Third-Party Verifiers for a Batch



POST
/verification/verification-types
Create Verification


GET
/verification/verification-types
List Verifications


GET
/verification/verification-types/{verification_id}
Get Verification


DELETE
/verification/verification-types/{verification_id}
Remove Verification


PATCH
/verification/verification-types/{verification_id}
Patch Verification Type


POST
/verification/verification/manual/request
Request Manual Verification


POST
/verification/manual/send-bulk
Bulk Send Manual Verification Emails


POST
/verification/manual/resend/{request_id}
Resend Manual Verification Link


POST
/verification/manual/upload/{token}
Upload Manual Verification Report


POST
/verification/email-drafts
Create Email Draft



GET
/verification/email-drafts/{verification_type}
Get All Email Drafts by Verification Type



PUT
/verification/email-drafts/{draft_id}
Update an Email Draft



DELETE
/verification/email-drafts/{draft_id}
Delete an Email Draft



GET
/verification/products/warranty-template
Download Product Warranty Excel Template



POST
/verification/products/warranty-upload
Upload Product Warranty Excel



GET
/verification/products/warranty/{batch_id}
Get Warranty Status for All Products in a Batch



PATCH
/verification/products/warranty/{product_id}/status
Approve or Reject a Product Warranty


default


GET
/
Root


GET
/health
Health


Schemas
AuditLogResponseExpand allobject
BatchDetailResponseExpand allobject
BatchListResponseExpand allobject
BatchUserDetailExpand allobject
Body_bulk_upload_humans_verification_bulk_upload_postExpand allobject
Body_bulk_upload_products_verification_bulk_upload_products_postExpand allobject
Body_generate_human_template_verification_generate_human_template_postExpand allobject
Body_generate_product_template_verification_products_template_postExpand allobject
Body_upload_document_verification_upload_document_postExpand allobject
Body_upload_manual_verification_report_verification_manual_upload__token__postExpand allobject
Body_upload_photo_verification_upload_photo_postExpand allobject
Body_upload_warranty_excel_verification_products_warranty_upload_postExpand allobject
BulkSendRequestExpand allobject
BulkSendResponseExpand allobject
BulkSendResultExpand allobject
BulkUploadResponseExpand allobject
CreateSuperAdminRequestExpand allobject
CreateTemplateRequestExpand allobject
CreateUserRequestExpand allobject
DocumentInfoExpand allobject
DocumentUploadResponseExpand allobject
EmailDraftCreateExpand allobject
EmailDraftResponseExpand allobject
EmailDraftUpdateExpand allobject
ForgotPasswordRequestExpand allobject
GoogleAuthRequestExpand allobject
GroupedUserItemExpand allobject
HTTPValidationErrorExpand allobject
IndividualSignupRequestExpand allobject
LoginRequestExpand allobject
LoginResponseExpand allobject
ManualVerificationRequestCreateExpand allobject
ManualVerificationRequestResponseExpand allobject
MessageResponseExpand allobject
OnboardingRequestExpand allobject
OrganizationSignupRequestExpand allobject
OrganizationUsersResponseExpand allobject
PhotoUploadResponseExpand allobject
ProductCategoryResponseExpand allobject
ProductWarrantyItemExpand allobject
ProductWarrantyListResponseExpand allobject
PromoteSuperAdminRequestExpand allobject
QRGenerationResponseExpand allobject
ResendLinkResponseExpand allobject
ResendOTPRequestExpand allobject
ResetPasswordRequestExpand allobject
SignupResponseExpand allobject
SingleHumanUploadExpand allobject
SingleProductUploadExpand allobject
SingleUploadResponseExpand allobject
TemplateResponseExpand allobject
TemplateVersionResponseExpand allobject
ThirdPartyVerifierItemExpand allobject
ThirdPartyVerifiersResponseExpand allobject
UpdateTemplateRequestExpand allobject
UpdateUserRequestExpand allobject
UpdateVerificationStatusRequestExpand allobject
UserDetailsResponseExpand allobject
UserListItemExpand allobject
UserListResponseExpand allobject
ValidationErrorExpand allobject
VerificationListResponseExpand allobject
VerificationTypeCreateExpand allobject
VerificationTypeResponseExpand allobject
VerificationTypeUpdateExpand allobject
VerifierMappingExpand allobject
VerifyOTPRequestExpand allobject
WarrantyStatusUpdateExpand allobject



Verification


GET
/verification/categories
Get All Product Categories

Returns all available product categories with their warranty support settings.

No authentication required - public endpoint.
Parameters
Cancel
No parameters

Execute
Clear
Responses
Curl

curl -X 'GET' \
  'https://trumarkz-api-54038467488.asia-south1.run.app/verification/categories' \
  -H 'accept: application/json'
Request URL
https://trumarkz-api-54038467488.asia-south1.run.app/verification/categories
Server response
Code	Details
200	
Response body
Download
[
  {
    "id": "dffe8ddf-b037-425e-8211-32f29aa4690f",
    "category_name": "Agriculture Products",
    "warranty_support": "optional",
    "description": "Farming equipment and agricultural products"
  },
  {
    "id": "6f34a446-13ce-4f0f-a29a-e7c157c5ea47",
    "category_name": "Beauty & Cosmetics",
    "warranty_support": "disabled",
    "description": "Beauty products, cosmetics, and personal care"
  },
  {
    "id": "e6b1766e-e6d4-418c-83da-742876c1ac36",
    "category_name": "Consumer Goods",
    "warranty_support": "optional",
    "description": "General consumer products and goods"
  },
  {
    "id": "11eaca22-2af5-4a40-bfef-a5ea01feeac4",
    "category_name": "Electronics & Appliances",
    "warranty_support": "required",
    "description": "Electronic devices and home appliances"
  },
  {
    "id": "e226d156-9ae5-42a0-9b79-d69de7bbd182",
    "category_name": "EV & Automotive",
    "warranty_support": "required",
    "description": "Electric vehicles and automotive products"
  },
  {
    "id": "6291b8aa-6170-4215-959d-d1aef1c3debf",
    "category_name": "Healthcare Products",
    "warranty_support": "optional",
    "description": "Medical devices and healthcare products"
  },
  {
    "id": "a0828fae-cf5a-4b07-a380-cae4e484cac3",
    "category_name": "Industrial Equipment",
    "warranty_support": "required",
    "description": "Heavy machinery and industrial equipment"
  },
  {
    "id": "b0a20f9f-09ee-4462-ad6f-9bc822d628e6",
    "category_name": "Insurance Policies",
    "warranty_support": "disabled",
    "description": "Insurance documents and policies"
  },
  {
    "id": "0a67d4d5-b3ff-408a-85d9-590ea5a31f3b",
    "category_name": "Luxury Products",
    "warranty_support": "optional",
    "description": "High-end luxury goods and accessories"
  },
  {
    "id": "8ec4b18b-6155-4907-a6df-c8a46658b7bc",
    "category_name": "Others",
    "warranty_support": "optional",
    "description": "Other product categories"
  }
]
Response headers
 alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000 
 content-length: 1664 
 content-type: application/json 
 date: Tue,23 Jun 2026 10:21:59 GMT 
 server: Google Frontend 
 x-cloud-trace-context: 561357b76df60a00aad59b91bfacbc62 
Responses
Code	Description	Links
200	
Successful Response

Media type

application/json
Controls Accept header.
Example Value
Schema
[
  {
    "id": "string",
    "category_name": "string",
    "warranty_support": "string",
    "description": "string"
  }
]



POST
/verification/products/warranty-upload
Upload Product Warranty Excel


Org uploads the filled warranty Excel. Each product is created with warranty_status = 'pending'. Super admin then reviews and approves/rejects.

Parameters
Cancel
Reset
No parameters

Request body

multipart/form-data
batch_name *
string
new
description
string
description
Send empty value
file *
string($binary)
warranty_template_test
Execute
Clear
Responses
Curl

curl -X 'POST' \
  'https://trumarkz-api-54038467488.asia-south1.run.app/verification/products/warranty-upload' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyMzA1ODYxMC00YjhiLTQ2YTEtYjVjOC05ZWFhNDJiMjQ0MmMiLCJsb2dpbl90eXBlIjoic3VwZXJfYWRtaW4iLCJleHAiOjE3ODIyMTM4MjN9.lGKD-ohRoxlCdAbTCfCJOrOJkTLmtxv7b4k37XmRlw8' \
  -H 'Content-Type: multipart/form-data' \
  -F 'batch_name=new' \
  -F 'description=' \
  -F 'file=@warranty_template_test.xlsx;type=application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
Request URL
https://trumarkz-api-54038467488.asia-south1.run.app/verification/products/warranty-upload
Server response
Code	Details
200	
Response body
Download
{
  "message": "Warranty upload complete. 0 products uploaded, 1 skipped.",
  "batch_id": "0e81c02f-fa66-4676-8208-181682e99fae",
  "entity_type": "product",
  "total_uploaded": 0,
  "total_skipped": 1,
  "successful_users": [],
  "skipped_users": [
    {
      "row": 2,
      "reason": "Category 'Electronics' not found"
    }
  ],
  "errors": []
}
Response headers
 access-control-allow-credentials: true 
 access-control-allow-origin: * 
 alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000 
 content-length: 288 
 content-type: application/json 
 date: Tue,23 Jun 2026 10:24:02 GMT 
 server: Google Frontend 
 x-cloud-trace-context: 4f4726024af198d91f382b1563425da6;o=1 
Responses
Code	Description	Links
200	
Successful Response

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "message": "string",
  "batch_id": "string",
  "entity_type": "string",
  "total_uploaded": 0,
  "total_skipped": 0,
  "successful_users": [
    {}
  ],
  "skipped_users": [
    {}
  ],
  "errors": [
    {}
  ]
}
No links
422	
Validation Error

Media type

application/json
Example Value
Schema
{
  "detail": [
    {
      "loc": [
        "string",
        0
      ],
      "msg": "string",
      "type": "string"
    }
  ]
}



GET
/verification/products/warranty/{batch_id}
Get Warranty Status for All Products in a Batch


Returns all products in a warranty batch with their individual warranty status.

Parameters
Cancel
Name	Description
batch_id *
string
(path)
0e81c02f-fa66-4676-8208-181682e99fae
Execute
Clear
Responses
Curl

curl -X 'GET' \
  'https://trumarkz-api-54038467488.asia-south1.run.app/verification/products/warranty/0e81c02f-fa66-4676-8208-181682e99fae' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyMzA1ODYxMC00YjhiLTQ2YTEtYjVjOC05ZWFhNDJiMjQ0MmMiLCJsb2dpbl90eXBlIjoic3VwZXJfYWRtaW4iLCJleHAiOjE3ODIyMTM4MjN9.lGKD-ohRoxlCdAbTCfCJOrOJkTLmtxv7b4k37XmRlw8'
Request URL
https://trumarkz-api-54038467488.asia-south1.run.app/verification/products/warranty/0e81c02f-fa66-4676-8208-181682e99fae
Server response
Code	Details
200	
Response body
Download
{
  "batch_id": "0e81c02f-fa66-4676-8208-181682e99fae",
  "total": 0,
  "pending": 0,
  "approved": 0,
  "rejected": 0,
  "products": []
}
Response headers
 alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000 
 content-length: 113 
 content-type: application/json 
 date: Tue,23 Jun 2026 10:24:38 GMT 
 server: Google Frontend 
 x-cloud-trace-context: 3fc1f1ee4620cb41b631da6d532b1ad6;o=1 
Responses
Code	Description	Links
200	
Successful Response

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "batch_id": "string",
  "total": 0,
  "pending": 0,
  "approved": 0,
  "rejected": 0,
  "products": [
    {
      "product_id": "string",
      "batch_id": "string",
      "product_name": "string",
      "category_id": "string",
      "serial_number": "string",
      "purchase_date": "string",
      "warranty_start_date": "2026-06-23T10:24:38.062Z",
      "warranty_end_date": "2026-06-23T10:24:38.063Z",
      "warranty_status": "string",
      "warranty_reason": "string",
      "custom_fields": {},
      "created_at": "2026-06-23T10:24:38.063Z"
    }
  ]
}
No links
422	
Validation Error

Media type

application/json
Example Value
Schema
{
  "detail": [
    {
      "loc": [
        "string",
        0
      ],
      "msg": "string",
      "type": "string"
    }
  ]
}

POST
/verification/bulk-upload/products
Bulk Upload Products from Excel or CSV


Upload multiple products from Excel (.xlsx, .xls) or CSV (.csv) file.

**Required columns:** product_name, category
**Optional columns:** All other fields go into custom_fields (flexible)

Returns detailed report of successful and skipped products.
Parameters
Cancel
Reset
No parameters

Request body

multipart/form-data
batch_name *
string
new
description
string
description
Send empty value
verification_types
string
verification_types
Send empty value
file *
string($binary)
product_template_electronics_&_appliances.xlsx
Execute
Clear
Responses
Curl

curl -X 'POST' \
  'https://trumarkz-api-54038467488.asia-south1.run.app/verification/bulk-upload/products' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyMzA1ODYxMC00YjhiLTQ2YTEtYjVjOC05ZWFhNDJiMjQ0MmMiLCJsb2dpbl90eXBlIjoic3VwZXJfYWRtaW4iLCJleHAiOjE3ODIyMTM4MjN9.lGKD-ohRoxlCdAbTCfCJOrOJkTLmtxv7b4k37XmRlw8' \
  -H 'Content-Type: multipart/form-data' \
  -F 'batch_name=new' \
  -F 'description=' \
  -F 'verification_types=' \
  -F 'file=@product_template_electronics_&_appliances.xlsx;type=application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
Request URL
https://trumarkz-api-54038467488.asia-south1.run.app/verification/bulk-upload/products
Server response
Code	Details
400
Undocumented
Error: response status is 400

Response body
Download
{
  "detail": "Missing required columns: category"
}
Response headers
 access-control-allow-credentials: true 
 access-control-allow-origin: * 
 alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000 
 content-length: 47 
 content-type: application/json 
 date: Tue,23 Jun 2026 10:25:39 GMT 
 server: Google Frontend 
 x-cloud-trace-context: 28abdf88a7ad1f2cd03186f08199611d;o=1 
Responses
Code	Description	Links
200	
Successful Response

Media type

application/json
Controls Accept header.
Example Value
Schema
{
  "message": "string",
  "batch_id": "string",
  "entity_type": "string",
  "total_uploaded": 0,
  "total_skipped": 0,
  "successful_users": [
    {}
  ],
  "skipped_users": [
    {}
  ],
  "errors": [
    {}
  ]
}
No links
422	
Validation Error

Media type

application/json
Example Value
Schema
{
  "detail": [
    {
      "loc": [
        "string",
        0
      ],
      "msg": "string",
      "type": "string"
    }
  ]
}