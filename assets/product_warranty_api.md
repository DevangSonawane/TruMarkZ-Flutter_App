POST
/verification/products/warranty-upload
Upload Product Warranty Excel


Org uploads the filled warranty Excel with warranty documents. Each product is created with warranty_status = 'pending'. Super admin then reviews and approves/rejects.

**Required:** batch_name, file (Excel), doc_product_names, doc_labels, doc_files
**Optional:** description

**Documents:** Each product must have warranty documents attached.
- doc_product_names: comma-separated product names (must match Excel exactly)
- doc_labels: comma-separated document labels (warranty_card, warranty_certificate, etc.)
- doc_files: files in same order as names and labels
Parameters
Try it out
No parameters

Request body

multipart/form-data
batch_name *
string
description
file *
string($binary)
doc_product_names *
string
Comma-separated product names for docs

doc_labels *
string
Comma-separated document labels

doc_files *
array
Document files in same order

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