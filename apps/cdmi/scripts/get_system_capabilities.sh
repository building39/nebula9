#!/bin/bash

curl -uadministrator:test -H "Accept: application/cdmi-capability" -H "x-cdmi-specification-version: 1.1" -X GET "http://localhost:4000/api/v1/cdmi_capabilities/" -v |python -m json.tool
