POST
/verification/products/warranty-upload
Upload Product Warranty Excel


Org uploads the filled warranty Excel after first reserving serial numbers. Each product is created with warranty_status = 'pending'. Super admin then reviews and approves/rejects.

**Required:** batch_name, file (Excel), batch_type, use_reserved_serials, reserved_serial_nos
**Optional:** description, doc_serial_nos, doc_labels, doc_files

**Documents:** Warranty documents are attached by reserved serial number.
- reserved_serial_nos: comma-separated serial_no values returned by /verification/products/warranty-reserve-serials
- doc_serial_nos: comma-separated serial_no values in the same order as doc_labels and doc_files
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
batch_type *
string
warranty
use_reserved_serials *
string
true
reserved_serial_nos *
string
Comma-separated reserved warranty serial numbers
doc_serial_nos
string
Comma-separated serial numbers for docs

doc_labels
string
Comma-separated document labels

doc_files
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
