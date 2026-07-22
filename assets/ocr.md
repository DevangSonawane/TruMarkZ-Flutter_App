POST
/verification/humans/upload-doc
Org Upload Document for a Human


Organization uploads a document for a specific human in a batch, identified by user_id. The human counterpart of /products/upload-doc.

Supports multiple docs per user and versioning (re-upload same label = new
version). Use for aadhaar, pan, certificates, etc.
Parameters
Try it out
No parameters

Request body

multipart/form-data
user_id *
string
Batch user (human) id

document_label *
string
e.g. aadhaar, pan, certificate

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
  "document_id": "string",
  "document_url": "string",
  "version": 0,
  "user_id": "string",
  "full_name": "string"
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


for parsing 
POST
/ocr/extract
Extract fields from one or more document images (OCR)


Upload one OR MORE images of the SAME person and get back one merged JSON. Useful for front+back of a card, or multiple documents (aadhaar + pan) for a single person — each image is OCR'd and the fields are combined (an empty field is filled by whichever image has it).

Fully caller-driven fields:
- `fields` (comma-separated) = exactly what you want extracted.
- Leave `fields` empty to extract EVERY readable field the model finds.
- `doc_type` is an optional context hint only.
Parameters
Try it out
No parameters

Request body

multipart/form-data
files *
array
One or more images of the same person

fields
Comma-separated fields to extract; empty = extract everything

doc_type
Optional context hint about the document

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

after these there will be a review pop up where the user if indivual or multiple there will things which the user can edit or change , remember this cna be for single or multiple users so pop up will be designed like that there will be a pagination types so only 1 user pop up will be there first and then a go ahead back arrows keys to navigate


PATCH
/verification/batch-users/{user_id}
Edit a Batch User (review/correct OCR data)


Update a batch user's fields after reviewing OCR-extracted data. Only the fields sent are changed. By default this also clears the review flag (custom_fields.ocr_review_status -> "reviewed"); send mark_reviewed=false to save corrections while keeping it under review.

Parameters
Try it out
Name	Description
user_id *
string
(path)
user_id
Request body

application/json
Example Value
Schema
{
  "full_name": "string",
  "email": "string",
  "phone_number": "string",
  "dob": "string",
  "aadhar_number": "string",
  "pan_number": "string",
  "address_line1": "string",
  "address_line2": "string",
  "address_line3": "string",
  "pincode": "string",
  "state": "string",
  "country": "string",
  "custom_fields": {},
  "mark_reviewed": true
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

and this after reviewing and clicking on confirm