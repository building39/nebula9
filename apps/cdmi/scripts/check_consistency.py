#!/usr/bin/env python
from base64 import encodestring
import getopt
import getpass
import json
import requests
import sys
import traceback

HEADERS = {"X-CDMI-Specification-Version": "1.1"}

OBJECT_TYPE_CAPABILITY = 'application/cdmi-capability'
OBJECT_TYPE_CONTAINER  = 'application/cdmi-container'
OBJECT_TYPE_DATAOBJECT = 'application/cdmi-object'
OBJECT_TYPE_DOMAIN     = 'application/cdmi-domain'

VERSION = '1.0.0'


class CheckNebula(object):

    def __init__(self,
                 host,  # Nebula host url
                 adminid,
                 adminpw,
                 port,  # Nebula host port
                 verbose):
        self.host = host
        self.port = int(port)
        self.adminid = adminid
        self.adminpw = adminpw
        self.verbose = verbose
        self.url = 'http://%s:%d/cdmi/v1' % (self.host, self.port)
        self.system_domain = 'Basic %s' % encodestring('%s:%s;realm=system_domain' % (self.adminid, self.adminpw))
        self.default_domain = 'Basic %s' % encodestring('%s:%s;realm=default_domain' % (self.adminid, self.adminpw))
        self.headers = HEADERS.copy()
        self.objects_found = 0
        self.children_found = 0
        self.parents_found = 0
        self.capabilities_found = 0
        self.capabilities_used = 0
        self.domains_found = 0
        self.domains_used = 0
        self.children_missing = 0
        self.parents_missing = 0
        self.capabilities_missing = 0
        self.domains_missing = 0
        self.child_count_mismatch = 0
        self.containers_found = 0
        self.dataobjects_found = 0
        self.unknown_objects = 0

    def check(self, objectName='/', domainURI='/cdmi_domains/system_domain/'):
        if objectName == 'default_domain/':
            domainURI = '/cdmi_domains/default_domain/'
        elif objectName in ['/', 'cdmi_domains', 'system_domain', 'cdmi_capabilities', 'system_congfiguration']:
            domainURI = '/cdmi_domains/system_domain/'

        (status, body) = self.get(objectName, domainURI)
        # print("1. Status: %s, Object: %s" % (status, body))
        if status in [200, 201, 204]:
            body = json.loads(body)
            if objectName == 'default_domain/':
                domainURI = '/cdmi_domains/default_domain/'
            # print("Found object named '%s'" % objectName)
            # print("in domain '%s'" % domainURI)
            # print("Object: %s" % body)
            objectType = body.get('objectType', None)
            if objectType == 'application/cdmi-container':
                self.containers_found += 1
            elif objectType == 'application/cdmi-object':
                self.dataobjects_found += 1
            elif objectType == 'application/cdmi-domain':
                self.domains_found += 1
            elif objectType == 'application/cdmi-capability':
                self.capabilities_found += 1
            else:
                self.unknown_objects += 1
            self.objects_found += 1
            capUri = body.get('capabilitiesURI', None)
            if capUri:
                (status2, body2) = self.get(capUri, domainURI)
                if status2 in [200, 201, 204]:
                    # print("2. Found valid capabilities object")
                    self.capabilities_used += 1
                else:
                    print("3. No capabilities object found")
                    self.capabilities_missing += 1
                    print("Capability %s missing" % capUri)
            parentUri = body.get('parentURI', None)
            if parentUri:
                if parentUri in ["/", "/system_configuration/"]:
                    parentUri = "/"
                (status3, body3) = self.get(parentUri, domainURI)
                if status3 in [200, 201, 204]:
                    # print("4. Found the parent object")
                    self.parents_found += 1
                else:
                    print("5. No parent object found")
                    self.parents_missing += 1
                    print('Object %s is missing parent %s status: %d' % (body.get('objectName'), parentUri, status3))
            domainUri = body.get('domainURI', None)
            if domainUri:
                (status4, body4) = self.get(domainUri, domainURI)
                if status4 in [200, 201, 204]:
                    # print("6. Found valid domain object")
                    self.domains_used += 1
                else:
                    print("7. could not find domain %s status: %d" %
                          (domainUri, status4))
                    self.domains_missing += 1
            children = body.get('children', [])
            # print("Found children: %s" % children)
            childrenrange = body.get('childrenrange', None)
            # print("Children range: %s" % childrenrange)
            num_children = len(children)
            if childrenrange:
                (start, end) = childrenrange.split('-')
                x = int(end) - int(start) + 1
                if x != num_children:
                    print("Actual number of children: %d" % num_children)
                    print("Calculated number of children: %d" % x)
                    self.child_count_mismatch += 1
            else:
                if num_children:
                    print("No childrenrange found for object with %d children" % num_children)
                    self.child_count_mismatch += 1
            dURI = body.get('domainURI', domainURI)
            for child in children:
                nextobject = '%s%s' % (objectName, child)
                # print("...next object: %s" % nextobject)
                # print("...in domain: %s" % dURI)
                (status5, body) = self.get(nextobject, dURI)
                if status5 in [200, 201, 204]:
                    # print('8. ...found: %s' % nextobject)
                    self.children_found += 1
                    self.check(objectName=nextobject)
                else:
                    self.children_missing += 1
                    print('9. ...missing child %s status: %d' % (child, status5))
        else:
           print("listnebula received status code %d - exiting..." % status)
           print("Found %d objects" % self.objects_found)

    def get(self, objectName, domainURI):
        headers = self.headers.copy()
        realm = domainURI.split('/')[2]
        if domainURI == '/cdmi_domains/system_domain/':
            headers["Authorization"] = self.system_domain.rstrip()
        else:
            headers["Authorization"] = self.default_domain.rstrip()
        url = '%s%s' % (self.url, objectName)

        r = requests.get(url=url,
                         headers=headers,
                         allow_redirects=True)
        # print("Requests response: %s" % r)
        if r.status_code == 404:
            print("++++++++++++++++++ NOT FOUND ++++++++++++++++++++++++++++++")
            print repr(traceback.format_stack())
        return(r.status_code, r.text)

def usage():
    print ('List contents of Nebula server using CDMI')
    print ('Version : %s' % VERSION)
    print ('')
    print ('Usage: '
           '%s --host=[hostname] --port=[port] --adminid --adminpw'
           % sys.argv[0])
    print ('')
    print (' Command Line options:')
    print ('  --adminpw   - Password for the "admin" user. If absent, will be prompted for.')
    print ('  --adminid   - User name for the administrator user. Default: administrator')
    print ('  --help      - Print this enlightening message')
    print ('  --host      - Nebula host url. Required.')
    print ('  --port      - Nebula host port. Optional, defaults to 8080.')

def main(argv):

    if (len(sys.argv) < 3):
        usage()

    adminid = 'administrator'
    adminpw = ''
    host = None
    port = 8080
    verbose = False

    try:
        opts, _args = getopt.getopt(argv,
                                   '',
                                   ['adminid=',
                                    'adminpw=',
                                    'help',
                                    'debug',
                                   'host=',
                                    'port=',
                                    'verbose'])
    except getopt.GetoptError, e:
        print ('opt error %s' % e)
        print ('')
        usage()

    for opt, arg in opts:
        if opt in ("--adminid"):
            adminid = arg
        elif opt in ("--adminpw"):
            adminpw = arg
        elif opt in ("-h", "--help"):
            usage()
        elif opt == '--debug':
            global DEBUG
            DEBUG = True
        elif opt == '--host':
            host = arg
        elif opt == '--port':
            port = arg

    if host is None:
        usage()
        sys.exit(1)

    while adminpw == '':
        adminpw = getpass.getpass('Please enter a password for the admin user')

    check = CheckNebula(host,  # Nebula host url
                        adminid,
                        adminpw,
                        port,     # Nebula host port
                        verbose)  # print verbose information on progress

    check.check()

    print("Found a total of %d objects" % check.objects_found)
    print("Containers:                       %d" % check.containers_found)
    print("Data Objects:                     %d" % check.dataobjects_found)
    print("Domains:                          %d" % check.domains_found)
    print("Objects with valid domains:       %d" % check.domains_used)
    print("Capabilities:                     %d" % check.capabilities_found)
    print("Objects with valid Capabilities:  %d" % check.capabilities_used)
    print("Children with valid parents:      %d" % check.parents_found)
    print("Children:                         %d" % check.children_found)
    if check.unknown_objects:
        print("Unknown objects:      %d" % check.unknown_objects)
    if check.children_missing:
        print("Children missing:     %d" % check.children_missing)
    if check.capabilities_missing:
        print("Capabilities missing: %d" % check.capabilities_missing)
    if check.domains_missing:
        print("Domains missing:      %d" % check.domains_missing)
    if check.parents_missing:
        print("Parents missing:      %d" % check.parents_missing)
    if check.child_count_mismatch:
        print("Child count errors:   %d" % check.child_count_mismatch)

if __name__ == "__main__":
    main(sys.argv[1:])
1111
