#!/bin/bash

curl -v -u"administrator:test;realm=system_domain/" \
    -H "x-cdmi-specification-version: 1.1" \
    -H "content-type: application/cdmi-domain" \
    -H "Accept: application/cdmi-domain" \
    -X PUT "http://localhost:4000/cdmi/v1/cdmi_domains/Fuzzcat/sub/" \
    -d '{"metadata": {"cdmi_domain_enabled": "true"}}' | python -mjson.tool
