#!/bin/bash

curl -v -u"administrator:test" -H "x-cdmi-specification-version: 1.1" -H "content-type: application/cdmi-capability" -X PUT "http://localhost:4000/cdmi/cdmi_capabilities/VendorCapability/" -d '{}' | python -mjson.tool
