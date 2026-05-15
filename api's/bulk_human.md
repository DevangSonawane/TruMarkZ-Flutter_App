POST
/verification/bulk-upload
Bulk Upload Users


Organization bulk uploads user details with batch_id. Creates invite tokens for each user.

Parameters
Try it out
No parameters

Request body

application/json
Example Value
Schema
{
  "batch_name": "string",
  "description": "string",
  "users": [
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
  ]
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