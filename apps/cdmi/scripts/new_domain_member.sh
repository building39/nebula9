#!/bin/bash

curl -u"administrator:test;realm=default_domain" -H "x-cdmi-specification-version: 1.1" -H "content-type: application/cdmi-object" -H "Accept: application/cdmi-object" -X PUT "http://localhost:4000/cdmi/v1/cdmi_domains/default_domain/cdmi_domain_members/mmartin" -d '{"metadata": {"cdmi_member_credentials": "278998758d36583a2e2d3a0676e5cb4974fe4186", "cdmi_member_enabled": "true", "cdmi_member_groups": [], "cdmi_member_name": "mmartin", "cdmi_member_principal": "mmartin", "cdmi_member_privileges": [], "cdmi_member_type": "user", "cdmi_owner": "mmartin"}}' -v | python -mjson.tool
