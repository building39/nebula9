#!/bin/bash

# curl -uadministrator:test -H "x-cdmi-specification-version: 1.1.1" -H "content-type: application/cdmi-container" -H "Accept: application/cdmi-container" -X GET "http://localhost:4000/cdmi/v1/" -v |python -m json.tool

curl -u"administrator:test;realm=system_domain" -H "x-cdmi-specification-version: 1.1.1" -H "Accept: application/json" -X GET "http://localhost:4000/cdmi/v1/" -v |python -m json.tool
