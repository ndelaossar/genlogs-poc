## Problem 2
Build a Proof of concept (POC) infrastructure in AWS. It should include the following:

- One VPC
- One ELB
- One Application Server
In the server install nginx which will serve a simple html page via the ELB
Bonus: build uwsgi and server the page from it

### Note 
Before running the code create backend bucket manually on Ministack

$ aws s3 mb s3://bucket-local --endpoint-url=http://localhost:4566