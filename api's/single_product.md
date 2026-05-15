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