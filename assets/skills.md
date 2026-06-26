PATCH
/skills/{skill_id}/edit
Edit a Skill


Individual edits their own skill. Status resets to pending after edit.

Parameters
Try it out
Name	Description
skill_id *
string
(path)
skill_id
Request body

application/json
Example Value
Schema
{
  "skill_name": "string",
  "skill_info": "string",
  "institution_name": "string",
  "degree": "string"
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
  "individual_id": "string",
  "skill_type": "string",
  "skill_name": "string",
  "skill_info": "string",
  "institution_name": "string",
  "degree": "string",
  "status": "string",
  "status_reason": "string",
  "verified_at": "2026-06-26T07:29:23.828Z",
  "created_at": "2026-06-26T07:29:23.828Z",
  "updated_at": "2026-06-26T07:29:23.828Z",
  "documents": []
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

DELETE
/skills/{skill_id}
Delete a Skill


Individual deletes one of their own skills. Superadmin can delete any skill.

Parameters
Try it out
Name	Description
skill_id *
string
(path)
skill_id
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

DELETE
/skills/all/{individual_id}
Delete All Skills