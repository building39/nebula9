#!/bin/bash

curl -v -uadministrator:test -H "x-cdmi-specification-version: 1.1" -H "content-type: application/cdmi-container" -X DELETE "http://localhost:8080/cdmi/new_container2/" 
#curl -v -uadministrator -H "x-cdmi-specification-version: 1.1" -X DELETE "http://localhost:8080/cdmi/system_configuration/new_container2/" 
