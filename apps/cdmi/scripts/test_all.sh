#!/bin/bash

export NEBULA_PATH=/data/git/nebula
export NEBULA_BOOTSTRAP_PATH=/data/git/nebula_bootstrap
echo "clearing memcached..."
echo 'flush_all' | nc localhost 11211
echo "removing old logs..."
rm /var/log/nebula/*
echo "Clearing all CDMI data..."
${NEBULA_PATH}/scripts/deleteall.py
sleep 1
echo "Bootstrapping CDMI..."
MIX_ENV=dev ${NEBULA_BOOTSTRAP_PATH}/nebula_bootstrap --adminid administrator --adminpw test >/tmp/bootstrap
sleep 5

echo "Creating domains..."
curl -v -uadministrator:test \
    -H "x-cdmi-specification-version: 1.1" \
    -H "content-type: application/cdmi-domain" \
    -H "Accept: application/cdmi-domain" \
    -X PUT "http://localhost:4000/api/v1/cdmi_domains/Fuzzcat/" \
    -d '{"metadata": {"cdmi_domain_enabled": "true"}}' | python -mjson.tool
sleep 1
curl -v -uadministrator:test \
    -H "x-cdmi-specification-version: 1.1" \
    -H "content-type: application/cdmi-container" \
    -H "Accept: application/cdmi-container" \
    -X PUT "http://localhost:4000/api/v1/cdmi_domains/Fuzzcat/cdmi_domain_members/" \
    -d '{"metadata": {"cdmi_domain_enabled": "true"}}' | python -mjson.tool
sleep 1

curl -v -uadministrator:test \
    -H "x-cdmi-specification-version: 1.1" \
    -H "content-type: application/cdmi-domain" \
    -H "Accept: application/cdmi-domain" \
    -X PUT "http://localhost:4000/api/v1/cdmi_domains/Fuzzcat/catbox/" \
    -d '{"metadata": {"cdmi_domain_enabled": "true"}}' | python -mjson.tool
sleep 1
curl -v -uadministrator:test \
    -H "x-cdmi-specification-version: 1.1" \
    -H "content-type: application/cdmi-container" \
    -H "Accept: application/cdmi-container" \
    -X PUT "http://localhost:4000/api/v1/cdmi_domains/Fuzzcat/catbox/cdmi_domain_members/" \
    -d '{"metadata": {"cdmi_domain_enabled": "true"}}' | python -mjson.tool
sleep 1

echo "Creating containers in Fuzzcat domain..."
curl -v -u"administrator:test;realm=Fuzzcat,another=option" \
    -H "x-cdmi-specification-version: 1.1" \
    -H "content-type: application/cdmi-container" \
    -H "Accept: application/cdmi-container" \
    -X PUT "http://localhost:4000/api/v1/new_container1/" \
    -d '{"metadata": {"cdmi_domain_enabled": "true"}}' | python -mjson.tool
sleep 1
curl -v -u"administrator:test;realm=Fuzzcat,another=option" -H "x-cdmi-specification-version: 1.1" -H "content-type: application/cdmi-container" -H "Accept: application/cdmi-container" -X PUT "http://localhost:4000/api/v1/new_container1/childz/" -d '{"metadata": {"cdmi_domain_enabled": "true"}}' | python -mjson.tool

echo "Creating containers in Fuzzcat/catbox domain..."
curl -v -u"administrator:test;realm=Fuzzcat/catbox" \
    -H "x-cdmi-specification-version: 1.1" \
    -H "content-type: application/cdmi-container" \
    -H "Accept: application/cdmi-container" \
    -X PUT "http://localhost:4000/api/v1/new_container1/" \
    -d '{"metadata": {"cdmi_domain_enabled": "true"}}' | python -mjson.tool
sleep 1
curl -v -u"administrator:test;realm=Fuzzcat/catbox/" \
    -H "x-cdmi-specification-version: 1.1" \
    -H "content-type: application/cdmi-container" \
    -H "Accept: application/cdmi-container" \
    -X PUT "http://localhost:4000/api/v1/new_container1/childz/" \
    -d '{"metadata": {"cdmi_domain_enabled": "true"}}' | python -mjson.tool

