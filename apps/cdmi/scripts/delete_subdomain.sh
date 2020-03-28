#!/bin/bash

curl -v -uadministrator:test -H "x-cdmi-specification-version: 1.1" -X DELETE "http://localhost:4000/api/v1/cdmi_domains/Fuzzcat/catbox/" #|python -mjson.tool
