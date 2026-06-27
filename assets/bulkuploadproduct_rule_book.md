What This API Does
Allows an organization to upload products from an Excel file and attach documents (certificates, warranty
cards, compliance docs) to specific products — all in a single API call. No need for separate product
creation and doc upload steps.
POST /verification/bulk-upload/products
Auth: Bearer token (Organization login)
Content-Type: multipart/form-data
Field Type Required Description
batch_name string Yes Name for this batch
description string No Batch description
industry_type string No e.g. Electronics & Appliances
verification_types string No Comma-separated: Product Quality Check,Third Party Inspection
file file Yes Excel (.xlsx) or CSV with product_name column
doc_product_names string No Comma-separated product names matching Excel
doc_labels string No Comma-separated document labels
doc_files file[] No Document files in same order as names and labels
Payload Structure
Key rule: doc_product_names, doc_labels, and doc_files must be in the same order. First name matches first label matches
first file.


Example
Excel file (products.xlsx):
product_name model brand
Screw M8x50 Tata Steel
Bolts HexBolt-10 JSW
Nails Wire-6inch Kamdhenu
Form data sent:
batch_name: "My Product Batch"
industry_type: "Electronics & Appliances"
verification_types: "Product Quality Check"
file: products.xlsx
doc_product_names: "Screw,Bolts"
doc_labels: "certificate,warranty_card"
doc_files: [screw_certificate.pdf, bolts_warranty.pdf]
What happens:
1. Excel parsed → 3 products created (Screw, Bolts, Nails)
2. doc_product_names split → ['Screw', 'Bolts']
3. 'Screw' matched → screw_certificate.pdf uploaded as 'certificate'
4. 'Bolts' matched → bolts_warranty.pdf uploaded as 'warranty_card'
5. 'Nails' has no doc → created without document (fine, optional)
Response:
{
"message": "Bulk upload completed. 3 products uploaded, 0 skipped. 2 documents
attached.",
"batch_id": "uuid-xxx",
"total_uploaded": 3,
"total_skipped": 0,
"successful_users": [
{"id": "uuid-1", "product_name": "Screw", "invite_token": "..."},
{"id": "uuid-2", "product_name": "Bolts", "invite_token": "..."},
{"id": "uuid-3", "product_name": "Nails", "invite_token": "..."}
],
"skipped_users": [],
"errors": []
}
Frontend Integration Guide
User Flow (Step by Step)
1. User selects Excel file
2. Frontend parses Excel on client-side → extracts product_name column
3. Product names shown in a dropdown (replacing Product ID field)
4. User clicks '+ Add Documents':
→ Selects product from dropdown (e.g., 'Screw')
→ Selects document label (certificate / warranty_card / compliance_doc)
→ Chooses file to upload
5. User can add multiple docs (+ Add another document)
6. User clicks 'Create Batch'
7. Frontend sends ONE API call with Excel + all docs
Flutter / Dart Implementation
// 1. Parse Excel on client side to get product names
final excelBytes = await file.readAsBytes();
final excel = Excel.decodeBytes(excelBytes);
final sheet = excel.tables.keys.first;
final rows = excel.tables[sheet]!.rows;
// Find product_name column index
final headers = rows.first.map((e) => e?.value.toString()).toList();
final nameIdx = headers.indexOf('product_name');
// Extract product names for dropdown
final productNames = rows.skip(1)
.map((r) => r[nameIdx]?.value.toString() ?? '')
.where((n) => n.isNotEmpty).toList();
// 2. Build form data
final formData = FormData.fromMap({
'batch_name': 'New Product Batch',
'industry_type': 'Electronics & Appliances',
'verification_types': 'Product Quality Check',
'file': await MultipartFile.fromFile(excelPath),
// Doc mappings (only if user added docs)
'doc_product_names': selectedDocs.map((d) => d.productName).join(','),
'doc_labels': selectedDocs.map((d) => d.label).join(','),
});
// Add doc files
for (final doc in selectedDocs) {
formData.files.add(MapEntry(
'doc_files',
await MultipartFile.fromFile(doc.filePath),
));
}
// 3. Send request
final response = await dio.post(
'/verification/bulk-upload/products',
data: formData,
options: Options(headers: {'Authorization': 'Bearer $token'}),
);



I Changes Required
Current UI New UI
'Product ID' text input field 'Product Name' dropdown populated from Excel
User manually types UUID User selects from parsed Excel product names
Doc upload is separate step Doc upload happens with batch creation
Calls 2 APIs (bulk-upload + upload-doc) Calls 1 API (bulk-upload with docs)
Important Notes
1. Product names must match exactly between dropdown selection and Excel product_name column
2. Documents are optional — batch can be created without any docs
3. Multiple docs per product — same product name can appear multiple times in doc_product_names
4. Order matters — doc_product_names[0] + doc_labels[0] + doc_files[0] go together
5. Products without docs are still created — they just won't have documents attached
6. The separate POST /verification/products/{id}/upload-doc API still works for uploading docs later


API 1: Bulk Upload Products with Documents
POST /verification/bulk-upload/products

This API is used when an organization creates a new batch of products. It accepts an Excel file containing product details and optionally allows attaching documents (like certificates, warranty cards, or compliance docs) to specific products in the same API call. The frontend parses the Excel on the client side to extract product names and shows them in a dropdown. The user selects a product, chooses a document label, and attaches a file. On clicking "Create Batch", the Excel and all documents are sent together. The backend creates the products from Excel, then matches each document to its product by name and uploads it. No product ID or batch ID is needed since the batch is being created in this very call.


