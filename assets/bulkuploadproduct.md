POST
/verification/bulk-upload/products
Bulk Upload Products from Excel or CSV


Upload multiple products from Excel (.xlsx, .xls) or CSV (.csv) file.

**Required columns:** product_name
**Optional columns:** All other fields go into custom_fields (flexible)

**Optional: Upload docs along with products**
- doc_product_names: comma-separated product names (must match Excel)
- doc_labels: comma-separated document labels (certificate, warranty_card, etc.)
- doc_files: files in same order as doc_product_names and doc_labels

Example: doc_product_names="Screw,Bolts" doc_labels="certificate,warranty" doc_files=[screw_cert.pdf, bolts_warranty.pdf]
Parameters
Try it out
No parameters

Request body

multipart/form-data
batch_name *
string
description
string
industry_type
string
verification_types
string
file *
string($binary)
doc_product_names
Comma-separated product names for docs (must match Excel)

doc_labels
Comma-separated document labels

doc_files
Document files in same order as product names and labels

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