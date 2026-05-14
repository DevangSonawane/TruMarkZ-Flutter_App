I'm working on a Flutter app called TruMarkZ. The codebase uses:
- **Riverpod** (AsyncNotifierProvider / StateNotifierProvider pattern)  
- **Dio** via `ApiClient` in `lib/core/network/api_client.dart` (base URL: `https://trumarkz-api-54038467488.asia-south1.run.app`, second base URL for verification endpoints: `https://trumarkz-api.asynk.in`)
- **GoRouter** for navigation
- **Repository pattern**: `AuthRepository` in `lib/features/auth/data/auth_repository.dart` is the reference implementation
- **TokenStorage** (`lib/core/services/token_storage.dart`) for secure JWT persistence
- Existing models in `lib/core/models/auth_models.dart`

I need to wire ALL API endpoints end-to-end. No mock data should remain in any integrated screen after this work. Work file by file, create what's needed.

---

## STEP 1 — EXTEND `ApiClient`

The current `ApiClient` only handles `get` and `post` with JSON. Add the following methods to `lib/core/network/api_client.dart`:

```dart
// For multipart (file upload) requests — no Content-Type override, let Dio set boundary
Future<Map<String, dynamic>> postMultipart(String path, FormData formData) async { ... }

// For PATCH requests
Future<Map<String, dynamic>> patch(String path, {Object? data}) async { ... }
```

Both must use the same try/catch and `_toApiException` pattern as the existing `post` method.

Also add a second `Dio` instance `_verificationDio` that has base URL `https://trumarkz-api.asynk.in` with the same auth interceptor. Add corresponding methods:
```dart
Future<Map<String, dynamic>> verificationGet(String path) async { ... }
Future<Map<String, dynamic>> verificationPost(String path, {Object? data}) async { ... }
Future<Map<String, dynamic>> verificationPatch(String path, {Object? data}) async { ... }
Future<Map<String, dynamic>> verificationPostMultipart(String path, FormData formData) async { ... }
```

---

## STEP 2 — ADD VERIFICATION MODELS

Create `lib/core/models/verification_models.dart` with these classes (all with `fromJson` factories and `toJson` where needed):

```dart
// Document inside a verification user record
class VerificationDocument {
  final String id;
  final String documentLabel;
  final String documentUrl;
  final int version;
  final String verificationStatus; // 'pending' | 'verified' | 'failed'
  final String? verificationReason;
  final String? verifiedAt;
  final String uploadedAt;
}

// A user in the verification system
class VerificationUser {
  final String id;
  final String batchId;
  final String orgId;
  final String fullName;
  final String? dob;
  final String phoneNumber;
  final String email;
  final String? aadharNumber;
  final String? panNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? pincode;
  final String? state;
  final String? country;
  final String verificationStatus; // 'pending_verification' | 'verified' | 'failed'
  final String? verificationReason;
  final String? verifiedAt;
  final String? photoUrl;
  final String storagePath;
  final bool inviteAccepted;
  final String createdAt;
  final String updatedAt;
  final List<VerificationDocument> documents;
}

// Response from GET /verification/all
class VerificationListResponse {
  final int total;
  final int pending;
  final int verified;
  final int failed;
  final List<VerificationUser> users;
}

// A successfully uploaded user from POST /verification/bulk-upload
class BulkUploadSuccessUser {
  final int row;
  final String userId;
  final String email;
  final String phoneNumber;
  final String fullName;
  final String token;
  final String inviteLink;
}

// A skipped user row
class BulkUploadSkippedUser {
  final int row;
  final String reason;
}

// An error row
class BulkUploadErrorRow {
  final int row;
  final String field;
  final String error;
}

// Full response from POST /verification/bulk-upload
class BulkUploadResponse {
  final String message;
  final String batchId;
  final int totalUploaded;
  final int totalSkipped;
  final List<BulkUploadSuccessUser> successfulUsers;
  final List<BulkUploadSkippedUser> skippedUsers;
  final List<BulkUploadErrorRow> errors;
}

// Response from POST /verification/user/{id}/generate-qr
class GenerateCertificateResponse {
  final String message;
  final String pdfUrl;
  final String qrCodeData;
}

// Response from POST /verification/upload/photo
class UploadPhotoResponse {
  final String message;
  final String photoUrl;
}

// Response from POST /verification/upload/document
class UploadDocumentResponse {
  final String message;
  final String documentId;
  final String documentUrl;
  final int version;
}
```

---

## STEP 3 — CREATE `VerificationRepository`

Create `lib/features/orgs/data/verification_repository.dart`:

```dart
final verificationRepositoryProvider = Provider<VerificationRepository>(...);

class VerificationRepository {
  VerificationRepository(this._api);
  final ApiClient _api;

  // POST /verification/bulk-upload  (multipart, base: trumarkz-api.asynk.in)
  Future<BulkUploadResponse> bulkUpload({
    required String batchName,
    String? description,
    required Uint8List fileBytes,
    required String fileName,
  }) async { ... }

  // GET /verification/all  (with optional filters)
  Future<VerificationListResponse> getAllVerifications({
    String? orgId,
    String? batchId,
    String? status,
    int limit = 100,
    int offset = 0,
  }) async { ... }

  // GET /verification/user/{user_id}
  Future<VerificationUser> getUserVerification(String userId) async { ... }

  // PATCH /verification/user/{user_id}/status
  Future<void> updateVerificationStatus({
    required String userId,
    required String status, // 'verified' | 'failed' | 'pending_verification'
    String? reason,
  }) async { ... }

  // POST /verification/user/{user_id}/generate-qr
  Future<GenerateCertificateResponse> generateCertificate(String userId) async { ... }

  // POST /verification/upload/photo  (no auth — uses token field)
  Future<UploadPhotoResponse> uploadPhoto({
    required String inviteToken,
    required Uint8List fileBytes,
    required String fileName,
  }) async { ... }

  // POST /verification/upload/document  (no auth — uses token field)
  Future<UploadDocumentResponse> uploadDocument({
    required String inviteToken,
    required String documentLabel,
    required Uint8List fileBytes,
    required String fileName,
  }) async { ... }
}
```

For `uploadPhoto` and `uploadDocument`, do NOT add the Authorization header — send the `token` as a form field only.

For `bulkUpload`, use `verificationPostMultipart` (base URL: `https://trumarkz-api.asynk.in`). The form fields are `batch_name`, optional `description`, and `file`.

---

## STEP 4 — FILE PICKING

Add `file_picker: ^8.1.2` to `pubspec.yaml` dependencies (check if already present first, don't duplicate).

Create a shared utility `lib/core/utils/file_picker_util.dart`:

```dart
class PickedFile {
  final String name;
  final Uint8List bytes;
  final String extension; // 'xlsx', 'pdf', 'jpg', etc.
}

class FilePickerUtil {
  // Pick Excel file (.xlsx, .xls)
  static Future<PickedFile?> pickExcel() async { ... }

  // Pick image file
  static Future<PickedFile?> pickImage() async { ... }

  // Pick document file (PDF, image)
  static Future<PickedFile?> pickDocument() async { ... }
}
```

Use `FilePicker.platform.pickFiles(withData: true)` for all — this gives bytes on all platforms including web.

---

## STEP 5 — INTEGRATE HUMAN VERIFICATION BULK UPLOAD

**File to modify: `lib/features/orgs/verification_flow/presentation/pages/bulk_upload_page.dart`**

Replace the mock "Use Sample File" / "Confirm & Upload" flow with a real implementation:

1. Replace the "File Picker (Coming Soon)" button with a real call to `FilePickerUtil.pickExcel()`. When a file is picked, store `_pickedFile` (a `PickedFile?`) and update the UI to show the file name.

2. In `_confirmAndCreateBatch()`, after validation:
   - Show a loading state (`_isUploading = true`)
   - Call `verificationRepository.bulkUpload(batchName: ..., description: null, fileBytes: _pickedFile!.bytes, fileName: _pickedFile!.name)`
   - On success: navigate to `batchCreatedSuccessPath` passing `batch_id`, `total_uploaded`, `total_skipped` as query params. Also pass error count.
   - On `ApiException`: show a `SnackBar` with `e.message`
   - Reset loading state in finally block

3. The "Use Sample File" option can remain for testing but should be clearly labeled as "Demo Mode".

The Riverpod provider for `VerificationRepository` should be accessed via `ref` — convert `BulkUploadPage` to a `ConsumerStatefulWidget`.

---

## STEP 6 — INTEGRATE `BatchProgressPage` (Batch List)

**File to modify: `lib/features/orgs/presentation/pages/batch_progress_page.dart`**

Replace all static `_BatchDirectoryItem.sample()` data with real API data.

1. Convert to `ConsumerStatefulWidget`.

2. Create a Riverpod `FutureProvider.family` or `StateNotifierProvider` in a new file `lib/features/orgs/application/verification_list_notifier.dart`:

```dart
// Holds filter state and fetches from API
class VerificationListState {
  final AsyncValue<VerificationListResponse> data;
  final String? statusFilter; // null = all
  final int offset;
}

class VerificationListNotifier extends StateNotifier<VerificationListState> { ... }
```

3. In `BatchProgressPage`:
   - On init, call `ref.read(verificationListNotifierProvider.notifier).load()`
   - Show real `total`, `pending`, `verified`, `failed` counts in the summary carousel (replace the hardcoded 12, 3, 1)
   - Map `VerificationUser` records grouped by `batch_id` to `_BatchDirectoryCard` items. Since the API returns users (not batches), group by `batch_id` and show: batch name = use `batch_id` (truncated UUID for now — note in a comment that a dedicated batch list endpoint is pending), records = count of users in batch, progress = `verified / total` for that group.
   - Add a filter row (chips: All, Pending, Verified, Failed) that calls `notifier.setFilter(status)` and reloads.
   - Show `CircularProgressIndicator` while loading, error text on failure with a retry button.
   - Tapping a batch card navigates to `appBatchTrackingDetailPath` passing `batch_id` as a query param.

---

## STEP 7 — INTEGRATE `BatchTrackingDetailPage`

**File to modify: `lib/features/orgs/verification_flow/presentation/pages/batch_tracking_detail_page.dart`**

This page currently reads only query params and shows static sample records. Replace with:

1. Convert to `ConsumerStatefulWidget`.
2. Read `batch_id` from query params.
3. On init, call `GET /verification/all?batch_id={batch_id}` via `VerificationRepository`.
4. Show real users from `response.users` in the records list.
5. Each record row shows: `full_name`, `email`, verification status badge (color-coded: green=verified, yellow=pending, red=failed), `invite_accepted` indicator, and a chevron to tap into detail.
6. The summary bar at top shows real `response.verified`, `response.pending`, `response.failed` counts.
7. Tapping a record navigates to `individualRecordDetailPath?user_id={user.id}`.

---

## STEP 8 — INTEGRATE `IndividualRecordDetailPage`

**File to modify: `lib/features/orgs/verification_flow/presentation/pages/individual_record_detail_page.dart`**

Replace static data with real API data:

1. Convert to `ConsumerStatefulWidget`.
2. Read `user_id` from query params (the page currently reads `name`, `status`, etc. — replace with a single `user_id` param).
3. On init, call `GET /verification/user/{user_id}` via `VerificationRepository`.
4. Display all real fields: `full_name`, `email`, `phone_number`, `dob`, `aadhar_number`, `pan_number`, full address, `photo_url` (show as a `CircleAvatar` with `NetworkImage` if available), `invite_accepted` chip, `verification_status` badge.
5. Documents section: show each `VerificationDocument` as a card with: label, version pill, status badge, and a "View" button that opens the `document_url` via `url_launcher` (`launchUrl`).
6. At the bottom, show an "Actions" section (only visible if the logged-in user's `loginType == 'super_admin'` OR for org for now just show for everyone as the backend will gate it):
   - "Approve" button → calls `PATCH /verification/user/{id}/status` with `{status: 'verified'}`. On success, refresh the user data and show a success snackbar.
   - "Reject" button → shows a dialog with a TextField for reason → calls `PATCH` with `{status: 'failed', reason: ...}`. On success, refresh.
7. If `verificationStatus == 'verified'`: show a "Generate Certificate" button → calls `POST /verification/user/{id}/generate-qr`. On success, show a bottom sheet with:
   - "Download PDF" button → `launchUrl(Uri.parse(response.pdfUrl))`
   - The QR code URL shown as text and a "Copy Link" button

Add `url_launcher` to `pubspec.yaml` if not already present.

---

## STEP 9 — CREATE INDIVIDUAL DOCUMENT UPLOAD PAGE (new file)

This is the page that users land on from their invite link: `https://trumarkz.asynk.in/upload?token=xxx`

Create `lib/features/orgs/verification_flow/presentation/pages/user_document_upload_page.dart`

**Route**: Add `static const String userDocumentUploadPath = '/user-upload';` to `AppRouter` and register the route. The page reads `token` from query params.

**Page design** (match existing app style — white cards, blue brand, same typography):

AppBar: "Upload Your Documents" — no back button (this is a standalone flow)

Body:
1. **Header card**: "Hello! Your organisation has requested document verification. Please upload the following." — simple info card.

2. **Photo upload section**:
   - Large dashed-border upload zone (reuse `_DashedBorderPainter` style from `BulkUploadPage`)
   - Label: "Your Photo"
   - Tap → `FilePickerUtil.pickImage()` → call `verificationRepository.uploadPhoto(inviteToken: token, fileBytes: ..., fileName: ...)`
   - On success: show a `CircleAvatar` preview with `MemoryImage(bytes)` and a green checkmark overlay
   - On error: SnackBar with error message

3. **Documents section** — a list of upload tiles for: Aadhar Card (`document_label: 'aadhar'`), PAN Card (`document_label: 'pan'`), Degree/Certificate (`document_label: 'degree_certificate'`), Driving License (`document_label: 'driving_license'`)
   - Each tile has: label, icon, upload status (pending/done), tap to pick file via `FilePickerUtil.pickDocument()`
   - On pick → call `verificationRepository.uploadDocument(inviteToken: token, documentLabel: label, fileBytes: ..., fileName: ...)`
   - Each tile updates independently — show a green checkmark when that document's upload succeeds
   - Show version number if already uploaded (from `UploadDocumentResponse.version`)

4. **Bottom "Done" button** — always enabled, tapping shows a bottom sheet: "Your documents have been submitted. The organisation will review them and notify you."

State management: Use `ConsumerStatefulWidget` with local `Map<String, bool> _uploadedDocs` to track which docs are done.

---

## STEP 10 — PRODUCT BULK UPLOAD API INTEGRATION

**File to modify: `lib/features/orgs/verification_flow/presentation/pages/product_bulk_upload_page.dart`**

Replace the mock "Use Sample File" with a real file picker:

1. Replace `_openUploadSheet`'s "File Picker (Coming Soon)" with a real call to `FilePickerUtil.pickExcel()`.
2. When file is picked, store `_pickedFile` and show the filename + size.
3. In `_createBatch()`:
   - Call `verificationRepository.bulkUpload(batchName: _batchName, description: _sector, fileBytes: _pickedFile!.bytes, fileName: _pickedFile!.name)` — reuse the same endpoint (the API is agnostic to product vs human).
   - On success: navigate to `productBatchCreatedPath` with real `records: response.totalUploaded`, `skipped: response.totalSkipped`, `batchId: response.batchId`.
   - On error: SnackBar with `e.message`.
   - Convert to `ConsumerStatefulWidget`.

Update `ProductBatchCreatedPage` to also show: "X skipped" if `skipped > 0` (read from query params).

---

## STEP 11 — BATCH CREATED SUCCESS PAGE

**File to modify: `lib/features/orgs/verification_flow/presentation/pages/batch_created_success_page.dart`**

This page is reached after the human verification bulk upload succeeds. Update it to:
1. Read and display real query params: `total_uploaded`, `total_skipped`, `batch_id` (show truncated batch ID as a monospace reference).
2. If `total_skipped > 0`, show a yellow warning card: "X records were skipped — check your Excel file for missing required fields (full_name, email, phone_number)."
3. If there were errors (pass `errors` count as a query param from bulk upload), show a red info card: "X rows had errors."
4. "View Batch" button navigates to `appBatchTrackingDetailPath?batch_id={batch_id}`.

---

## ROUTING ADDITION

In `lib/core/router/app_router.dart`, add:
```dart
static const String userDocumentUploadPath = '/user-upload';
```
And register the route pointing to `UserDocumentUploadPage`. This route should NOT require authentication (it's for external users via invite link) — add it to the `isOnAuthPage` check in the redirect guard so it bypasses auth.

---

## FILES TO CREATE (summary)
1. `lib/core/models/verification_models.dart`
2. `lib/core/utils/file_picker_util.dart`
3. `lib/features/orgs/data/verification_repository.dart`
4. `lib/features/orgs/application/verification_list_notifier.dart`
5. `lib/features/orgs/verification_flow/presentation/pages/user_document_upload_page.dart`

## FILES TO MODIFY (summary)
1. `lib/core/network/api_client.dart` — add `postMultipart`, `patch`, `verificationGet/Post/Patch/PostMultipart`
2. `lib/pubspec.yaml` — add `file_picker`, `url_launcher` if not present
3. `lib/core/router/app_router.dart` — add `userDocumentUploadPath`, update redirect guard
4. `lib/features/orgs/verification_flow/presentation/pages/bulk_upload_page.dart` — real file pick + API call
5. `lib/features/orgs/presentation/pages/batch_progress_page.dart` — real API data
6. `lib/features/orgs/verification_flow/presentation/pages/batch_tracking_detail_page.dart` — real API data
7. `lib/features/orgs/verification_flow/presentation/pages/individual_record_detail_page.dart` — real API data + approve/reject/generate cert
8. `lib/features/orgs/verification_flow/presentation/pages/product_bulk_upload_page.dart` — real file pick + API call
9. `lib/features/orgs/verification_flow/presentation/pages/product_batch_created_page.dart` — show skipped count
10. `lib/features/orgs/verification_flow/presentation/pages/batch_created_success_page.dart` — real params + skipped warning

## IMPORTANT CONSTRAINTS
- Follow the existing repository + Riverpod `AsyncNotifierProvider` / `StateNotifierProvider` pattern exactly as seen in `auth_notifier.dart` and `auth_repository.dart`
- All API errors must be caught as `ApiException` and shown via `ScaffoldMessenger` SnackBar — never crash silently
- Do NOT remove any existing UI widget classes unless replacing them with functionally equivalent real-data versions
- `uploadPhoto` and `uploadDocument` endpoints use the token as a form field — do NOT add `Authorization` header for those two calls
- For `url_launcher`, use `launchUrl(uri, mode: LaunchMode.externalApplication)`
- The `userDocumentUploadPath` must be in the auth bypass list in the GoRouter redirect so unauthenticated users (invite recipients) can access it
- Keep all existing navigation paths — only add, don't remove route constants