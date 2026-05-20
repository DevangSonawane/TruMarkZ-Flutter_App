POST
/verification/products/template
Generate Product Excel Template


Generate an Excel template for bulk product upload.

Frontend sends column headers, backend generates downloadable Excel file.

**Required:** category_id, headers (list of column names)
Parameters
Try it out
No parameters

Request body

application/x-www-form-urlencoded
category_id *
string
headers *
string
Responses
Code	Description	Links
200	
Successful Response

Media type

application/json
Controls Accept header.
Example Value
Schema
"string"
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
No links


POST
/verification/bulk-upload/products
Bulk Upload Products from Excel or CSV


Upload multiple products from Excel (.xlsx, .xls) or CSV (.csv) file.

**Required columns:** product_name, category
**Optional columns:** All other fields go into custom_fields (flexible)

Returns detailed report of successful and skipped products.
Parameters
Try it out
No parameters

Request body

multipart/form-data
batch_name *
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


for single product

POST
/verification/single/product
Upload Single Product


Upload a single product for verification.

Creates one product record with custom fields and returns an invite token
for document/image upload.

**Required fields:** category_id, product_name
**Optional:** custom_fields (any key-value pairs)
Parameters
Try it out
No parameters

Request body

application/json
Example Value
Schema
{
  "category_id": "string",
  "product_name": "string",
  "custom_fields": {}
}
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
  "entity_id": "string",
  "entity_type": "string",
  "invite_token": "string",
  "invite_link": "string"
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