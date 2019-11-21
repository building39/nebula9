#!/bin/bash
clear
curl -v "http://nebriak2.fuzzcat.loc:8098/search/query/cdmi_idx?wt=json&q=sp:c8c17baf9a68a8dbc75b818b24269ebca06b0f31/cdmi_domains/Fuzzcat/" |python -m json.tool
