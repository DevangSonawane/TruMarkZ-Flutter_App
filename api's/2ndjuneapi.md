


now when clicking on upload on the batch selection uploading from excel this api will be called, i want you to make sure that the verification types are being selecting locatally and then added here


POST
/verification/bulk-upload
Bulk Upload Humans from Excel


Upload multiple humans from Excel (.xlsx) file.

**Required columns:** full_name, email, phone_number
**Optional columns:** dob, aadhar_number, pan_number, address fields
**Photo column:** Embed images directly in the Photo column cells using
                  Insert → Image → Place in Cell. They are extracted and
                  uploaded to GCS automatically per user.

Skips rows with missing required fields and returns a detailed report.
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
credential_visibility
string
template_id
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




now this api when clicking on download template, if the user has not selected ny headers the user should first add the headers needed for that excel, and putting the headers how many the user wants (the headers will be seperted by a comma ",") there wiill be a save button and then the user can generate template and then upload the template, kindl fetch the verification type aas the headrs as well, the ones which the users select those headers will be automatcially added in the excel
make sure to use the same UI which we are doing currently 

POST
/verification/generate-human-template
Generate Human Template


Parameters
Try it out
No parameters

Request body

application/x-www-form-urlencoded
headers *
string
verification_types
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

POST
/verification/templates
Save Template


Parameters
Try it out
No parameters

Request body

application/json
Example Value
Schema
{
  "template_name": "string",
  "verification_types": [
    "string"
  ],
  "json_data": {},
  "html_code": "string"
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
  "id": "string",
  "template_name": "string",
  "verification_types": [
    "string"
  ],
  "json_data": {},
  "html_code": "string",
  "version": 0
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

GET
/verification/templates/{template_id}
Get Template


Parameters
Try it out
Name	Description
template_id *
string
(path)
template_id
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
  "id": "string",
  "template_name": "string",
  "verification_types": [
    "string"
  ],
  "json_data": {},
  "html_code": "string",
  "version": 0
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

PUT
/verification/templates/{template_id}
Update Template


Parameters
Try it out
Name	Description
template_id *
string
(path)
template_id
Request body

application/json
Example Value
Schema
{
  "template_name": "string",
  "verification_types": [
    "string"
  ],
  "json_data": {},
  "html_code": "string"
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
  "id": "string",
  "template_name": "string",
  "verification_types": [
    "string"
  ],
  "json_data": {},
  "html_code": "string",
  "version": 0
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


now these api's will be called respectively in the certificate preview page you can apply your brain for this let me knwo if you have any doubts in here