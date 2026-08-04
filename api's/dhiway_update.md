PATCH
/auth/me/dhiway-space
Update Dhiway Space


Save/update the Dhiway space id on the organization's profile.

Each organization is given its own space id; every batch it creates uses this value for SDC generation. Can be updated any time (unlike onboarding).

Parameters
Try it out
No parameters

Request body

application/json
Example Value
Schema
{
  "dhiway_space_id": "string"
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
  "data": {}
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