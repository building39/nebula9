#!/bin/bash

curl -v -u"administrator:test;realm=default_domain" -H "x-cdmi-specification-version: 1.1" -H "content-type: application/cdmi-object" -H "Accept: application/cdmi-object" -X PUT "http://localhost:4000/cdmi/v1/cdmi_domains/default_domain/cdmi_domain_members/mmartin" -d '{"metadata": {"cdmi_member_type": "user"}}' | python -mjson.tool
#curl -v -u"administrator:test;realm=system_domain" -H "x-cdmi-specification-version: 1.1" -H "content-type: application/cdmi-object" -H "Accept: application/cdmi-object" -X PUT "http://localhost:4000/cdmi/v1/cdmi_domains/default_domain/cdmi_domain_members/mmartin" -d '{"metadata": {"cdmi_member_type": "user"}}' | python -mjson.tool
