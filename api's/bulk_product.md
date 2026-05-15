POST
/verification/bulk-upload/products
Bulk Upload Products from Excel


Upload multiple products from Excel file with dynamic custom fields.

- First row must be headers (will become custom field keys)
- Skips rows with missing required data
- All columns stored in custom_fields JSONB
- Returns detailed upload report
Parameters
Try it out
No parameters

Request body

multipart/form-data
batch_name *
string
category_id *
string
description
string
file *
string($binary)
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