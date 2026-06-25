API 1: Add a Skill
POST /skills/add
Who: Individual (logged in)
Individual adds a new skill. Uses multipart/form-data (not JSON) because it supports optional file uploads.
Request Payload:
Form Fields:
skill_type: "technical" | "soft" | "education" | "project" (required)
skill_name: "Python" (required)
skill_info: "3 years experience" (optional)
institution_name: "IIT Delhi" (required for education only)
degree: "Computer Science" (optional, education only)
document_label: "certificate" (optional)
files: [file1, file2...] (optional, multiple files allowed)
Response:
{
"id": "uuid",
"skill_type": "technical",
"skill_name": "Python",
"skill_info": "3 years experience",
"institution_name": null,
"degree": null,
"status": "pending",
"documents_uploaded": 1,
"created_at": "2026-06-25T..."
}
Frontend Integration:
const formData = new FormData();
formData.append('skill_type', 'technical');
formData.append('skill_name', 'Python');
formData.append('skill_info', '3 years exp');
formData.append('files', fileInput.files[0]); // optional
fetch('/skills/add', {
method: 'POST',
headers: { 'Authorization': 'Bearer ' + token },
body: formData
});

Skills


POST
/skills/add
Add a Skill


Individual adds a skill to their profile.

**skill_type:** technical, soft, education, project

- **technical/soft:** skill_name (required), skill_info (optional), docs (optional)
- **education:** skill_name = qualification type (e.g. "10th", "12th", "B.Tech"), institution_name = school/university (required), degree (optional), docs (optional)
- **project:** skill_name = project name (required), skill_info (optional), docs (optional)

Documents are optional — can also be uploaded later via /skills/{id}/upload-doc
Parameters
Try it out
No parameters

Request body

multipart/form-data
skill_type *
string
technical, soft, education, or project

skill_name *
string
Skill/qualification/project name

skill_info
Description or details (optional)

institution_name
School/University name (required for education)

degree
Degree (optional, only for education)

document_label
Label for the document e.g. certificate, marksheet

files
Supporting documents (optional)

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
  "skill_type": "string",
  "skill_name": "string",
  "skill_info": "string",
  "institution_name": "string",
  "degree": "string",
  "status": "string",
  "created_at": "2026-06-25T17:58:02.285Z",
  "documents_uploaded": 0
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





API 2: Get My Skills
GET /skills/me
Who: Individual (logged in)
Returns all skills for the currently logged-in individual, grouped by type with documents.
Response:
{
"individual_id": "uuid",
"total": 5,
"skills": [
{
"id": "uuid",
"skill_type": "technical",
"skill_name": "Python",
"status": "pending",
"documents": [{ "id": "...", "document_url": "...", "version": 1 }]
}
]
}
Frontend Integration:
fetch('/skills/me', {
headers: { 'Authorization': 'Bearer ' + token }
}).then(res => res.json())
.then(data => {
const technical = data.skills.filter(s => s.skill_type === 'technical');
const education = data.skills.filter(s => s.skill_type === 'education');
// render each group
});



GET
/skills/me
Get My Skills


Returns all skills for the logged-in individual.

Parameters
Try it out
No parameters

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
  "individual_id": "string",
  "total": 0,
  "skills": [
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
      "verified_at": "2026-06-25T17:58:33.114Z",
      "created_at": "2026-06-25T17:58:33.114Z",
      "updated_at": "2026-06-25T17:58:33.114Z",
      "documents": []
    }
  ]
}



API 4: Upload Document for Skill
POST /skills/{skill_id}/upload-doc
Who: Individual
Upload or re-upload a document for an existing skill. Supports versioning — same label = new version.
Request Payload:
Form Fields:
document_label: "certificate" (required)
file: (required, single file)
Response:
{
"message": "Document 'certificate' uploaded successfully",
"document_id": "uuid",
"document_url": "gs://...",
"version": 2
}
Frontend Integration:
const formData = new FormData();
formData.append('document_label', 'certificate');
formData.append('file', fileInput.files[0]);
fetch('/skills/' + skillId + '/upload-doc', {
method: 'POST',
headers: { 'Authorization': 'Bearer ' + token },
body: formData
});


POST
/skills/{skill_id}/upload-doc
Upload Document for a Skill


Upload or re-upload a document for a skill.

Uses individual_id + skill_id for identification.
Supports versioning — same document_label re-uploaded gets a new version.
Parameters
Try it out
Name	Description
skill_id *
string
(path)
skill_id
Request body

multipart/form-data
document_label *
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
  "document_id": "string",
  "document_url": "string",
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