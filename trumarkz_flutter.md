# TruMarkZ Architecture & Handoff Guide for Flutter App

> **Target Audience**: Flutter / Mobile Application Developer  
> **Repository Context**: TruMarkZ Backend Services  
> **Document Purpose**: Integration & Handoff Guide for Organization-facing Mobile Functionality

---

## SECTION 1 — Organization User Scope

This document is specifically written for the **TruMarkZ Flutter Organization application**.

> [!IMPORTANT]
> The Flutter application contains **Organization user functionality ONLY**. The mobile application does **NOT** contain Super Admin features, administrative controls, or backend management tools.

### Explicitly Excluded Features (Do NOT Implement in Flutter)
The following administrative features exist strictly on the Super Admin web portal and **MUST NOT** be implemented in the Flutter app:
* Super Admin Management Dashboard
* Batch Monitor / System-wide Batch Operations
* Verifier Management (Creating, updating, or deleting third-party verifiers)
* Verifier Assignment UI
* Admin "Send to Organization" button or manual sharing triggers
* Admin Sharing Controls & Overrides

### Admin Action Impact on Organization Users
While Organization users cannot perform administrative actions, backend state changes triggered by a Super Admin directly affect what the Flutter application can access. Specifically, an admin must explicitly execute **"Send to Organization"** before SDC certificates, PDF download URLs, and verification links become accessible to the Organization user.

---

## SECTION 2 — Product Excel Upload Changes

### 1. Mandatory Fields
The Product Excel template flow in the Flutter application must support two mandatory columns:
* **`product_name`** (Required): Primary display name/title of the product.
* **`sku_no`** (Required): Stock Keeping Unit identifier.

```
┌────────────────────────────────────────────────────────┐
│ Product Excel Template Columns                         │
├─────────────────┬──────────┬───────────────────────────┤
│ Column Name     │ Status   │ Purpose                   │
├─────────────────┼──────────┼───────────────────────────┤
│ product_name    │ REQUIRED │ User-facing Product name  │
│ sku_no          │ REQUIRED │ Unique matching key       │
│ model_no        │ Optional │ Model specification       │
│ brand           │ Optional │ Manufacturing brand       │
│ third+party+qr2 │ Optional │ Secondary QR / doc link   │
│ phone_number    │ Optional │ Contact phone             │
│ email           │ Optional │ Contact email             │
└─────────────────┴──────────┴───────────────────────────┘
```

#### Rules & Backend Enforcement
1. **`product_name`**: Used for display and identifying the product in the mobile UI.
2. **`sku_no`**: Must be filled by the user for every Product row and **must be unique** within the uploaded Excel file.
3. **Missing Column Validation**: If `sku_no` column is absent from the Excel file, the backend returns HTTP 400 Bad Request (`"Missing required column: sku_no"`).
4. **Blank Cell Validation**: If a row has an empty `sku_no` cell, the backend skips that row and returns an explicit reason in `skipped_users` (`"Missing required field: sku_no"`).

### 2. Optional Product Fields
The backend currently supports the following optional Product fields:
* `model_no` (string)
* `brand` (string)
* `third+party+qr2` (string / URL)
* `phone_number` (string)
* `email` (string)
* Additional custom columns (dynamically captured into custom fields)

> [!CAUTION]
> **CRITICAL ARCHITECTURE RULE: SKU IS NOT PRODUCT IDENTITY**  
> `sku_no` is strictly used as an upload-time matching key for associating Product documents. It is **NOT** the Product identity.  
> The real backend Product identity remains **`BatchUser.id`** (UUID), and the Dhiway Product identity remains **`product_id = str(BatchUser.id)`**.  
> The Flutter app must **NEVER** generate, modify, or overwrite `product_id` or `BatchUser.id`.

---

## SECTION 3 — Product Document Upload Flow

### 1. End-to-End Association Flow Architecture

```
[ User selects Product Excel (product_name + unique sku_no) ]
                            │
                            ▼
[ User selects/attaches document file in Flutter UI ]
                            │
                            ▼
[ Flutter displays Product Name to user ]
                            │
                            ▼
[ Flutter internally maps selected document to sku_no ]
                            │
                            ▼
[ Upload request sends doc_sku_nos + doc_labels + doc_files ]
                            │
                            ▼
[ Backend creates BatchUser database records (BatchUser.id = UUID) ]
                            │
                            ▼
[ Backend matches document using sku_no against BatchUser.custom_fields["sku_no"] ]
                            │
                            ▼
[ Document attached to exact BatchUser record ]
                            │
                            ▼
[ Backend generates HTTPS view URL -> BatchUser.custom_fields["third+party+qr1"] ]
                            │
                            ▼
[ SDC Generation: third+party+qr1 URL sent to Dhiway Product record ]
```

### 2. Critical Flutter Mobile UI Requirement
* **User-Facing UI**: The Flutter app must display user-friendly identifiers such as **Product Name** and **SKU Number** (e.g. `Lakme Absolute Matte Lipstick (SKU: LAKME-001)`).
* **Hide Internal UUIDs**: The Flutter UI must **NOT** expose raw internal database UUIDs (`BatchUser.id`) to the user.
* **Internal SKU Mapping**: Flutter must preserve the exact `sku_no` internally for every selected Product document so it can be passed in the API request.

### 3. API Contract for Product Document Upload

When performing bulk upload with documents via `POST /verification/bulk-upload/products`, Flutter must pass `doc_sku_nos` alongside `doc_labels` and `doc_files` as multipart/form-data.

#### Form Parameters for Document Association:
* **`doc_sku_nos`** (string): Comma-separated list of SKU numbers matching the `sku_no` column in the Excel file.
* **`doc_labels`** (string): Comma-separated list of document labels (e.g. `"Spec Sheet,User Manual"`).
* **`doc_files`** (list of files): The actual binary document files (e.g. PDF / JPEG / PNG).

#### Array Positional Alignment Rule
Arrays and files **MUST** maintain exact 1-to-1 positional alignment:
```
Position 0: doc_sku_nos[0] ──► doc_labels[0] ──► doc_files[0]
Position 1: doc_sku_nos[1] ──► doc_labels[1] ──► doc_files[1]
```

*Example Multipart Request*:
* `file`: `products.xlsx`
* `batch_name`: `"July Product Batch"`
* `batch_type`: `"product"`
* `doc_sku_nos`: `"SKU-100,SKU-200"`
* `doc_labels`: `"Specification Sheet,User Manual"`
* `doc_files`: `[spec.pdf, manual.pdf]`

*(Note: `doc_product_names` is supported for legacy backward compatibility, but Flutter must use `doc_sku_nos` for all new product document uploads to avoid duplicate-name ambiguity).*

---

## SECTION 4 — Product Document Link (`third+party+qr1`)

After successful Product upload and document association:
1. The backend uploads the document file to Google Cloud Storage.
2. The backend generates an HTTPS public view URL (`https://<API_DOMAIN>/verification/documents/{doc_id}/view`).
3. The backend automatically saves this HTTPS URL into **`BatchUser.custom_fields["third+party+qr1"]`**.
4. During SDC credential generation, this URL is forwarded to Dhiway in the Product schema payload.

> [!NOTE]
> The Flutter application **MUST NOT** manually generate, construct, or format document URLs. The backend handles the complete lifecycle: Upload ──► Storage ──► `BatchUser` Association ──► `third+party+qr1` Storage ──► Dhiway Record.

---

## SECTION 5 — Product SDC Flow & Architecture Invariants

```
Product Excel Upload
        │
        ▼
BatchUser created in PostgreSQL
        │
        ▼
BatchUser.id generated by Backend (UUID)
        │
        ▼
product_id = str(BatchUser.id)
        │
        ▼
Product record payload sent to Dhiway CORD blockchain
        │
        ▼
Credential correlation matches credentialSubject.product_id == BatchUser.id
```

### DO NOT CHANGE — Mandatory Invariants for Flutter
The Flutter app must adhere strictly to these backend rules:
* ❌ **Do NOT** generate `product_id` on the mobile device.
* ❌ **Do NOT** generate UUIDs for products on the mobile device.
* ❌ **Do NOT** use `sku_no` as `product_id`.
* ❌ **Do NOT** use product name for credential identity matching.
* ❌ **Do NOT** attempt to alter the backend Product ID flow.

`sku_no` is strictly an upload-time matching key and a descriptive field inside the Product record.

---

## SECTION 6 — Current Product Dhiway Fields

When SDC credentials are generated for a Product batch, the backend maps the Product record into the following schema fields sent to Dhiway:

```json
{
  "product_id": "7b8e4f1a-3c2d-4e5f-9a0b-1c2d3e4f5a6b",
  "product_name": "UltraClean Water Purifier",
  "model_no": "UC-WP-2026",
  "brand": "AquaPure",
  "created_time": "Aug 31, 2026",
  "third+party+qr1": "https://api.trumarkz.com/verification/documents/11111111-2222-3333-4444-555555555555/view",
  "third+party+qr2": "",
  "sku_no": "SKU-UCWP-01"
}
```

### Field Definitions:
* **`product_id`**: Backend-generated UUID (`str(BatchUser.id)`). Identity anchor.
* **`product_name`**: Product name from Excel (`BatchUser.full_name`).
* **`model_no`**: Optional model specification string from Excel.
* **`brand`**: Optional brand string from Excel.
* **`created_time`**: Date string of batch creation.
* **`third+party+qr1`**: Backend-populated HTTPS document view URL.
* **`third+party+qr2`**: Optional secondary URL/string.
* **`sku_no`**: Product SKU string from Excel.

---

## SECTION 7 — Organization Certificate Visibility / Sharing Gate

The backend enforces a persisted **"Send to Organization"** security gate on every batch.

```
                                  [ Batch Created ]
                                          │
                                          ▼
                               [ SDC Credentials Issued ]
                                          │
                                          ▼
                      ┌───────────────────────────────────────┐
                      │ Check Batch.shared_with_org           │
                      └───────────────────┬───────────────────┘
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼                                               ▼
      shared_with_org == false                        shared_with_org == true
                  │                                               │
                  ▼                                               ▼
 ┌─────────────────────────────────┐             ┌─────────────────────────────────┐
 │ Hide Certificate Downloads      │             │ Enable Certificate Downloads    │
 │ certificate_ids = []            │             │ certificate_ids = [public_ids]  │
 │ Direct GET /sdc/records/ID ->   │             │ Direct GET /sdc/records/ID ->   │
 │ HTTP 403 Forbidden              │             │ HTTP 200 OK (PDF + Verify URL)  │
 └─────────────────────────────────┘             └─────────────────────────────────┘
```

### Flutter Application Behavior Rules

1. **Read `shared_with_org`**: The Flutter app must inspect `shared_with_org` (boolean) returned by batch endpoints (`GET /verification/batches`, `GET /verification/batches/{batch_id}`, `GET /sdc/batches/{batch_id}/status`).

2. **When `shared_with_org == false`**:
   * Do **NOT** enable certificate download or view buttons.
   * Display a clear status badge or banner: **"Certificates not yet shared with your organization"**.
   * Do **NOT** attempt direct calls to `/sdc/records/{public_id}` (the backend will reject the request with HTTP 403 Forbidden).

3. **When `shared_with_org == true`**:
   * Enable certificate view and PDF download features.
   * Use `certificate_ids` to fetch certificate details via `GET /sdc/records/{public_id}`.

> [!WARNING]
> This is a **server-side enforced security gate**, not merely a UI suggestion. Even if a user manually calls protected certificate/SDC routes, the backend will refuse to return PDF or verification URLs for unshared batches.

---

## SECTION 8 — APIs Flutter Needs to Review

Below is the complete inventory of Organization-facing backend APIs required for the Flutter application.

---

### 1. Download Product Excel Template
* **Method**: `GET`
* **Route**: `/verification/products/template`
* **Purpose**: One-click direct download of the standard Product Excel template containing canonical columns (`product_name`, `sku_no`, `model_no`, `brand`, `third+party+qr2`).
* **Authorization**: Authenticated Organization User
* **Response**: Binary Excel Streaming Response (`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`).

---

### 2. Product Bulk Upload (With Optional Documents)
* **Method**: `POST`
* **Route**: `/verification/bulk-upload/products`
* **Purpose**: Upload Product Excel and optional associated product document files.
* **Authorization**: Authenticated Organization User (`require_org`)
* **Content-Type**: `multipart/form-data`
* **Request Fields**:
  * `file` (File, required): The filled Product Excel `.xlsx` file.
  * `batch_name` (Form string, required): Name for the new batch.
  * `batch_type` (Form string, required): Must be `"product"`.
  * `description` (Form string, optional): Batch description.
  * `doc_sku_nos` (Form string, optional): Comma-separated list of `sku_no` values for attached documents.
  * `doc_labels` (Form string, optional): Comma-separated document labels.
  * `doc_files` (Files list, optional): Attached document files in positional order matching `doc_sku_nos`.
* **Response (200 OK)**:
  ```json
  {
    "batch_id": "7b8e4f1a-3c2d-4e5f-9a0b-1c2d3e4f5a6b",
    "batch_name": "July Product Batch",
    "total_uploaded": 10,
    "total_skipped": 0,
    "successful_users": [
      {
        "id": "11111111-2222-3333-4444-555555555555",
        "full_name": "UltraClean Water Purifier",
        "custom_fields": {
          "sku_no": "SKU-UCWP-01",
          "model_no": "UC-WP-2026",
          "third+party+qr1": "https://api.trumarkz.com/verification/documents/doc-uuid/view"
        }
      }
    ],
    "skipped_users": [],
    "errors": []
  }
  ```
* **Error Responses**:
  * `400 Bad Request`: Missing required column `sku_no` (`{"detail": "Missing required column: sku_no"}`).

---

### 3. List Organization Batches
* **Method**: `GET`
* **Route**: `/verification/batches`
* **Purpose**: List all batches belonging to the calling organization.
* **Authorization**: Authenticated Organization User (`require_org`)
* **Key Response Fields**:
  ```json
  [
    {
      "org_id": "org-uuid",
      "organization_name": "Acme Org",
      "batches": [
        {
          "batch_id": "7b8e4f1a-3c2d-4e5f-9a0b-1c2d3e4f5a6b",
          "batch_name": "July Product Batch",
          "batch_type": "product",
          "total_users": 10,
          "approved": 10,
          "rejected": 0,
          "status": "approved",
          "created_at": "2026-08-25T14:20:00Z",
          "shared_with_org": true,
          "shared_at": "2026-09-01T10:15:30Z",
          "shared_by": null
        }
      ]
    }
  ]
  ```
* **Flutter Note**: Use `shared_with_org` to display sharing status. `shared_by` returns `null` for Organization callers.

---

### 4. Fetch Batch Details
* **Method**: `GET`
* **Route**: `/verification/batches/{batch_id}`
* **Purpose**: Retrieve details, progress, and user records for a specific batch.
* **Authorization**: Authenticated Organization User (`require_org`)
* **Key Response Fields**:
  ```json
  {
    "batch_id": "7b8e4f1a-3c2d-4e5f-9a0b-1c2d3e4f5a6b",
    "batch_name": "July Product Batch",
    "batch_type": "product",
    "total_users": 10,
    "status": "approved",
    "sdc_status": "sdc_created",
    "shared_with_org": true,
    "shared_at": "2026-09-01T10:15:30Z",
    "workflow_step": 4,
    "users": []
  }
  ```

---

### 5. Fetch SDC Batch Status & Certificates
* **Method**: `GET`
* **Route**: `/sdc/batches/{batch_id}/status`
* **Purpose**: Poll SDC issuance status and retrieve certificate public IDs for a batch.
* **Authorization**: Authenticated Organization User (`require_org`)
* **Key Response Fields**:
  ```json
  {
    "batch_id": "7b8e4f1a-3c2d-4e5f-9a0b-1c2d3e4f5a6b",
    "total": 10,
    "ready": 10,
    "pending": 0,
    "done": true,
    "sdc_status": "sdc_created",
    "certificate_ids": ["cert-pub-1", "cert-pub-2"],
    "stalled": false,
    "shared_with_org": true,
    "shared_at": "2026-09-01T10:15:30Z"
  }
  ```
* **Flutter Note**: When `shared_with_org == false`, `certificate_ids` returns `[]` (empty list). Generation progress (`total`, `ready`, `done`) remains visible.

---

### 6. Fetch Single SDC Record (PDF & Verification Links)
* **Method**: `GET`
* **Route**: `/sdc/records/{public_id}?instance_key=de`
* **Purpose**: Fetch PDF view URL, verification URL, and verifiable credential JSON for a specific certificate.
* **Authorization**: Authenticated Organization User (`require_org`)
* **Key Response Fields**:
  ```json
  {
    "public_id": "cert-pub-1",
    "pdf": "https://dhiway.com/credentials/cert-pub-1.pdf",
    "verify": "https://dhiway.com/verify/cert-pub-1",
    "credential": {}
  }
  ```
* **Error Responses**:
  * `403 Forbidden`: Batch has not yet been shared (`{"detail": "Certificate has not yet been shared with the organization"}`).
  * `404 Not Found`: Certificate does not belong to your organization.

---

## SECTION 9 — Flutter UI Changes Checklist

### Product Upload
- [ ] Update Product template download flow to request `/verification/products/template`.
- [ ] Ensure Product Excel parsing and UI validation require both `product_name` and `sku_no`.
- [ ] Display `Product Name` and `SKU` clearly in the mobile UI.
- [ ] Retain `sku_no` internally for every Product record.

### Product Documents
- [ ] Associate document files using `sku_no` instead of product names or temporary IDs.
- [ ] Pass `doc_sku_nos` in multipart upload requests (`POST /verification/bulk-upload/products`).
- [ ] Ensure `doc_sku_nos`, `doc_labels`, and `doc_files` maintain exact 1-to-1 array index alignment.
- [ ] Remove user input fields for `third+party+qr1` from Product upload forms.

### Certificates & Security Gate
- [ ] Read `shared_with_org` from batch API responses.
- [ ] Disable certificate view/download actions when `shared_with_org == false`.
- [ ] Display status badge: *"Awaiting Organization Sharing"* when unshared.
- [ ] Enable certificate download features when `shared_with_org == true`.
- [ ] Handle HTTP 403 Forbidden errors gracefully if an unshared certificate route is called.

---

## SECTION 10 — Explicitly NOT Required for Flutter

The Flutter developer does **NOT** need to implement:
* ❌ Super Admin sharing button or "Send to Organization" action button.
* ❌ Super Admin batch monitoring screens.
* ❌ Verifier management or verifier assignment workflows.
* ❌ Database migrations or SQL scripts.
* ❌ Dhiway CORD blockchain credentials, schemas, or API keys.
* ❌ Product UUID generation (`BatchUser.id` / `product_id`).
* ❌ Document HTTPS URL generation (`third+party+qr1`).
* ❌ SDC credential correlation logic.
* ❌ Direct Dhiway API integration (consume TruMarkZ backend APIs only).

---

## SECTION 11 — End-to-End Product Flow for Flutter

```
1. Organization user initiates Product batch upload in Flutter app.
                             │
                             ▼
2. User fills Excel template with product_name and mandatory unique sku_no.
                             │
                             ▼
3. Flutter UI displays Product Names (and SKUs for disambiguation) in Document Attachment UI.
                             │
                             ▼
4. Flutter internally preserves each selected Product's sku_no.
                             │
                             ▼
5. Flutter calls POST /verification/bulk-upload/products with:
   - file (Excel)
   - batch_name & batch_type="product"
   - doc_sku_nos, doc_labels, doc_files
                             │
                             ▼
6. Backend creates BatchUser database records with generated UUIDs.
                             │
                             ▼
7. Backend matches doc_sku_nos to custom_fields["sku_no"] and attaches files.
                             │
                             ▼
8. Backend uploads files to cloud storage and stores HTTPS view URL in custom_fields["third+party+qr1"].
                             │
                             ▼
9. Standard Product verification and approval process completes.
                             │
                             ▼
10. Product SDC credentials generated on Dhiway (using product_id = BatchUser.id).
                             │
                             ▼
11. Super Admin reviews batch and clicks "Send to Organization" (sets shared_with_org = true).
                             │
                             ▼
12. Flutter app polls GET /sdc/batches/{batch_id}/status and sees shared_with_org == true.
                             │
                             ▼
13. Flutter displays Certificate Download buttons and loads PDF/Verify links via GET /sdc/records/{public_id}.
```
