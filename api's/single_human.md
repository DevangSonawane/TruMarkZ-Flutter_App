POST
/verification/single/human
Upload Single Human


Upload a single human for verification.

Creates one human record with all required fields and returns an invite token
for document upload.

**Required fields:** full_name, phone_number, email
Parameters
Try it out
No parameters

Request body

application/json
Example Value
Schema
{
  "full_name": "string",
  "dob": "string",
  "phone_number": "string",
  "email": "user@example.com",
  "aadhar_number": "string",
  "pan_number": "string",
  "address_line1": "string",
  "address_line2": "string",
  "address_line3": "string",
  "pincode": "string",
  "state": "string",
  "country": "string"
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
No links

