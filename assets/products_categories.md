


GET
/verification/categories
Get All Product Categories

Returns all available product categories with their warranty support settings.

No authentication required - public endpoint.
Parameters
Cancel
No parameters

Execute
Clear
Responses
Curl

curl -X 'GET' \
  'https://trumarkz-api-54038467488.asia-south1.run.app/verification/categories' \
  -H 'accept: application/json'
Request URL
https://trumarkz-api-54038467488.asia-south1.run.app/verification/categories
Server response
Code	Details
200	
Response body
Download
[
  {
    "id": "dffe8ddf-b037-425e-8211-32f29aa4690f",
    "category_name": "Agriculture Products",
    "warranty_support": "optional",
    "description": "Farming equipment and agricultural products"
  },
  {
    "id": "6f34a446-13ce-4f0f-a29a-e7c157c5ea47",
    "category_name": "Beauty & Cosmetics",
    "warranty_support": "disabled",
    "description": "Beauty products, cosmetics, and personal care"
  },
  {
    "id": "e6b1766e-e6d4-418c-83da-742876c1ac36",
    "category_name": "Consumer Goods",
    "warranty_support": "optional",
    "description": "General consumer products and goods"
  },
  {
    "id": "11eaca22-2af5-4a40-bfef-a5ea01feeac4",
    "category_name": "Electronics & Appliances",
    "warranty_support": "required",
    "description": "Electronic devices and home appliances"
  },
  {
    "id": "e226d156-9ae5-42a0-9b79-d69de7bbd182",
    "category_name": "EV & Automotive",
    "warranty_support": "required",
    "description": "Electric vehicles and automotive products"
  },
  {
    "id": "6291b8aa-6170-4215-959d-d1aef1c3debf",
    "category_name": "Healthcare Products",
    "warranty_support": "optional",
    "description": "Medical devices and healthcare products"
  },
  {
    "id": "a0828fae-cf5a-4b07-a380-cae4e484cac3",
    "category_name": "Industrial Equipment",
    "warranty_support": "required",
    "description": "Heavy machinery and industrial equipment"
  },
  {
    "id": "b0a20f9f-09ee-4462-ad6f-9bc822d628e6",
    "category_name": "Insurance Policies",
    "warranty_support": "disabled",
    "description": "Insurance documents and policies"
  },
  {
    "id": "0a67d4d5-b3ff-408a-85d9-590ea5a31f3b",
    "category_name": "Luxury Products",
    "warranty_support": "optional",
    "description": "High-end luxury goods and accessories"
  },
  {
    "id": "8ec4b18b-6155-4907-a6df-c8a46658b7bc",
    "category_name": "Others",
    "warranty_support": "optional",
    "description": "Other product categories"
  }
]
Response headers
 alt-svc: h3=":443"; ma=2592000,h3-29=":443"; ma=2592000 
 content-length: 1664 
 content-type: application/json 
 date: Tue,23 Jun 2026 10:12:23 GMT 
 server: Google Frontend 
 x-cloud-trace-context: e510958e87bfcba88bfe46da0a6c998c;o=1 
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
    "category_name": "string",
    "warranty_support": "string",
    "description": "string"
  }
]