#!/bin/bash

curl -uadministrator:test -H "x-cdmi-specification-version: 1.1"  -H "Accept: application/cdmi-domain" -X GET "http://localhost:4000//api/v1/system_configuration/domain_maps" -v |python -m json.tool
