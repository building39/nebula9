#!/bin/bash

curl -uadministrator:test -H "x-cdmi-specification-version: 1.1.1" -H "Accept: application/json" -X GET "http://cdmi.localhost.net:4000/cdmi/v1/cdmi_objectid/0000b0b900282f513ac73be740a84d75876daded6d25cb52" -v |python -m json.tool
