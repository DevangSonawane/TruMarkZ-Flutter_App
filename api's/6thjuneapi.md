GET
/verification/verification-types
List Verifications

Parameters
Cancel
No parameters

Execute
Clear
Responses
Curl

curl -X 'GET' \
  'https://trumarkz-api-54038467488.asia-south1.run.app/verification/verification-types' \
  -H 'accept: application/json'
Request URL
https://trumarkz-api-54038467488.asia-south1.run.app/verification/verification-types
Server response
Code	Details
200	
Response body
Download
[
  {
    "id": "6fc4cb8b-9796-4bd9-9a37-9334f37b78f3",
    "name": "Address Verification",
    "label": "manual",
    "category": "human",
    "email_address": "verifier@lab.com",
    "api_link": null,
    "price": 499,
    "timeline": "3 days"
  },
  {
    "id": "83378473-33ff-4cd4-a487-071df3ad258b",
    "name": "BIS Certificate",
    "label": "manual",
    "category": "product",
    "email_address": null,
    "api_link": null,
    "price": null,
    "timeline": null
  },
  {
    "id": "55b174b4-826d-4af9-b70c-e27aa1f9aad1",
    "name": "Company Verification",
    "label": "manual",
    "category": "human",
    "email_address": "verifier@lab.com",
    "api_link": null,
    "price": 499,
    "timeline": "3 days"
  },
  {
    "id": "b4497cd2-8936-4a77-9cc5-8a5cf6f33976",
    "name": "Criminal Record Verification",
    "label": "manual",
    "category": "human",
    "email_address": "verifier@lab.com",
    "api_link": null,
    "price": 499,
    "timeline": "3 days"
  },
  {
    "id": "13da422d-5b7a-4fa3-a856-cbfd5d9cf7b5",
    "name": "DOB Verification",
    "label": "automatic",
    "category": "human",
    "email_address": null,
    "api_link": "mock_dob_api",
    "price": 10,
    "timeline": "5 minutes"
  },
  {
    "id": "3a3eec70-8c72-40bc-a522-f046e1a39e81",
    "name": "Driving License Verification",
    "label": "manual",
    "category": "human",
    "email_address": "verifier@lab.com",
    "api_link": null,
    "price": 499,
    "timeline": "3 days"
  },
  {
    "id": "87e9189f-34c8-46af-92f7-98b89cfbec0c",
    "name": "Drug Test",
    "label": "manual",
    "category": "human",
    "email_address": "verifier@lab.com",
    "api_link": null,
    "price": 499,
    "timeline": "3 days"
  },
  {
    "id": "e55039f0-24b4-4bfb-b8da-bf49affd33eb",
    "name": "Drug Test Verification",
    "label": "manual",
    "category": "human",
    "email_address": "verifier@lab.com",
    "api_link": null,
    "price": 499,
    "timeline": "3 days"
  },
  {
    "id": "3a2cc903-43d2-45a5-b723-2d5a9dc3b51b",
    "name": "Education Verification",
    "label": "manual",
    "category": "human",
    "email_address": "verifier@lab.com",
    "api_link": null,
    "price": 499,
    "timeline": "3 days"
  },
  {
    "id": "9119370e-26ef-4a0c-9437-da89c205a2f0",
    "name": "Electrical Safety Report",
    "label": "manual",
    "category": "product",
    "email_address": null,
    "api_link": null,
    "price": null,
    "timeline": null
  },
  {
    "id": "97d2e06d-3c80-4598-a5fa-51bbc6836243",
    "name": "Experience Verification",
    "label": "manual",
    "category": "human",
    "email_address": "verifier@lab.com",
    "api_link": null,
    "price": 499,
    "timeline": "3 days"
  },
  {
    "id": "864f5086-211f-4828-b0f9-2449f309890e",
    "name": "Extended Warranty Eligibility",
    "label": "manual",
    "category": "product",
    "email_address": null,
    "api_link": null,
    "price": null,
    "timeline": null
  },
  {
    "id": "73cdf4ca-8769-4e74-a5d8-b87a0493b067",
    "name": "Factory Quality Test Report",
    "label": "manual",
    "category": "product",
    "email_address": null,
    "api_link": null,
    "price": null,
    "timeline": null
  },
  {
    "id": "72b05233-936b-479e-93cc-cbb235cf2f7f",
    "name": "Installation Certificate",
    "label": "manual",
    "category": "product",
    "email_address": null,
    "api_link": null,
    "price": null,
    "timeline": null
  },
  {
    "id": "fa9d4197-f70b-4bb5-996d-78343aa65fcd",
    "name": "Manufacturer Verification",
    "label": "manual",
    "category": "product",
    "email_address": null,
    "api_link": null,
    "price": null,
    "timeline": null
  },
  {
    "id": "08ae13b0-1600-416d-9c74-d6538284f189",
    "name": "Police Verification",
    "label": "manual",
    "category": "human",
    "email_address": "verifier@lab.com",
    "api_link": null,
    "price": 499,
    "timeline": "3 days"
  },
  {
    "id": "ec3c0f75-bde9-4e96-9883-346e982cec44",
    "name": "Repair History",
    "label": "manual",
    "category": "product",
    "email_address": null,
    "api_link": null,
    "price": null,
    "timeline": null
  },
  {
    "id": "c762c9c3-3860-44a2-8575-d87fc9c3ed7a",
    "name": "Service Centre Details",
    "label": "manual",
    "category": "product",
    "email_address": null,
    "api_link": null,
    "price": null,
    "timeline": null
  },
  {
    "id": "6d4f475f-ef90-4957-a924-e1f39b7bebcd",
    "name": "Skills Verification",
    "label": "manual",
    "category": "human",
    "email_address": "verifier@lab.com",
    "api_link": null,
    "price": 499,
    "timeline": "3 days"
  },
  {
    "id": "52f65a41-e5ff-4f9c-a5d3-419023f7864a",
    "name": "Warranty Card",
    "label": "manual",
    "category": "product",
    "email_address": null,
    "api_link": null,
    "price": null,
    "timeline": null
  }
]
Response headers
 alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000 
 content-length: 3808 
 content-type: application/json 
 date: Sat,06 Jun 2026 07:55:12 GMT 
 server: Google Frontend 
 x-cloud-trace-context: 11fb680354be4e5d42abaf20897a7e30;o=1 
Responses
Code	Description	Links
200	
Successful Response

Media type

application/json
Controls Accept header.
Example Value
Schema
[
  {
    "id": "string",
    "name": "string",
    "label": "string",
    "category": "string",
    "email_address": "string",
    "api_link": "string",
    "price": 0,
    "timeline": "string"
  }
]