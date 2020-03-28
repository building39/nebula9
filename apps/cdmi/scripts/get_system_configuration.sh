#!/bin/bash

curl -u"administrator:test" -H "x-cdmi-specification-version: 1.1"  -H "Accept: application/cdmi-container" -X GET "http://localhost:4000/api/v1/container/system_configuration/" -v |python -m json.tool
#curl -v -uadministrator -H "x-cdmi-specification-version: 1.1" -H "content-type: application/cdmi-container" -H "Accept: application/api/v1-container" -X GET "http://localhost:4000/cdmi/container/system_configuration/?children"
