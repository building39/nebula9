# Nebula

This project aims to provide a full featured Cloud Data Management (CDMI) API
for data storage andretrieval. More information on CDMI, including the latest
CDMI reference, can be found at the [`Storage Network Industry Association's`](http://www.snia.org)
[`CDMI Cloud Storage Standard`](https://www.snia.org/cloud/cdmi) webpage.

The CDMI standard defines an API for storing, retrieving, modifying and deleting
data and related objects in the cloud. Related objects include:

  * containers for organizing data objects (analogous to file system directories)
  * domains for providing administrative ownership of objects
  * queues for first-in, first-out access to data
  * system-wide capabilities objects that define features of the cloud storage system.

Objects stored in the cloud storage system can then be accessed either by path
or by the object identifier, a globally unique identifier assigned at object
creation time. This identifier does not change during the life of the object.
The CDMI standard also allows (but does not require) the cloud storage system
to provide data management services such as:

  * Exported protocols, such as iSCSI, Webdav, etc.
  * Snap shots - point-in-time copies of containers and their contents
  * Serialization/deserialization for bulk movement of data into or out of a cloud
  * Metadata, including Access Control Lists for authorization, and user defined
    metadata
  * Retention and hold management
  * Logging
  * Scope and results specifications
  * Notification and query queues

## Current State

The current state of this project is in its infancy. Boot strapping basic
required obects, and the creation of new domains and domain members (users) is
working, as is the creation of new containers and data objects. Container and
data object metadata retrieval is working, as is retrieving the data stored
for a data object. Basic HTTP authentication of users (domain members) on
object creation/read is provided, and the plumbing for ACL authorization is in
place but not yet activated - more work needed there. That's about it for
current functionality.

## Roadmap

The following new development tasks are planned for the immediate future (in
no particular order):

  * Domain maps.
  * Implementation of object deletion.
  * Implementation of object updates.
  * Queue implementation:
    * User queues
    * Notification queues
    * Query queues
  * Enforcement of system capability specifications
  * Enforcement of ACLs
  * Scope and results specifications
  * Logging
  * Retention and hold management
  * Serialization/deserialization

Further down the road:

  * Exported protocols
  * Snap shots

## Installation

This version of Nebula relies on an installed and configured Riak cluster. you
will need the latest Riak, version 2.2.3 or later. My development environment
includes a three node riak cluster - three Ubuntu virtual machines.

  * Install riak on each node
  * Edit /etc/riak/riak.conf on each node:
    * Set the node name by changing `nodename = riak@127.0.0.1`. change
      `127.0.0.1` to a name that is resolvable in your network.
    * Change the IP addresses for the listeners:
      * `listener.http.internal = 127.0.0.1:8098` - replace `127.0.0.1`
      * `listener.protobuf.internal = 127.0.0.1:8087` - replace `127.0.0.1`
    * Turn search on by changing `search = off` to `search = on`
    * Set the SOLR JVM options to
      `search.solr.jvm_options = -d64 -Xms1g -Xmx1g -XX:+UseStringCache -XX:+UseCompressedOops`
    * Restart riak on each node
    * Join the nodes into a cluster: see (https://docs.basho.com/riak/kv/2.0.9/using/cluster-operations/adding-removing-nodes/)  

Nebula also expects to have `memcached` running. Query results from the riak
cluster are cached in `memcached` and accessed from there on subsequent reads,
so make sure that you have `memcached` installed and running.

Install Nebula:
  * Clone this repository, as well as the [`bootstrapper`](git@github.com:building39/nebula_bootstrap.git)
  * cd to the nebula directory and:
    * Install Nebula bucket types and indices to the riak cluster:
      * cd to `./scripts`
      * edit `setup_riak_indexing.sh` and change `RIAK_HOST=nebriak1.fuzzcat.loc`
        to point to one of the nodes in your riak cluster.
      * run the `setup_riak_indexing.sh` script.
    * Install dependencies with `mix deps.get`
    * Configure `nebula_metadata`:
      * cd to `deps\nebula_metadata\config\` and edit `config.exs`, changing
        `start_mfa: { Riak.Connection, :start_link, ['nebriak1.fuzzcat.loc', 8087] }`
        to point to one of your riak nodes. Replace 'nebriak1.fuzzcat.loc'.
    * Start Nebula with `mix phx.server`
  * cd to the nebula_bootstrap directory and:
    * Make the same change in `nebula_bootstrap\deps\nebula_metadata\config\config.exs`
      mentioned above.
    * Build the bootstrapper with `mix escript.build`
    * Bootstrap the system objects with `./nebula_bootstrap --adminid administrator --adminpw test`.
      Adjust `--adminid` and `--adminpw` to suit your needs. Note that all of the
      test and example scripts default to these credentials - if you change them
      here, you will need to change them in the scripts to match.

At this point, you should have a running Nebula cluster (Nebula plus the riak nodes).
As bootstrapped, there will be two domains defined, `system_domain` which is meant
for system-related objects, and `default_domain`, which is intended to be a user
domain. The `system_domain` will have a single user, defined when you ran the
bootstrapper. The `default_domain` will have no users at this time.

## Playing with Nebula

You will find a number of examples in `nebula\scripts`. Some of these are bash
shell scripts, and some are python scripts. You will want to install `curl`
if you don't already have it, and a (hopefully) complete list of python
libraries can be found in `./scripts/python_package_dependencies.txt`.

A few of the more interesting scripts:

  * deleteall.py - Deletes all data stored in the riak cluster. Typically used
    to return Nebula to the initial state. Run this script followed by the
    bootstrapper script described above.
  * listall.py - Dumps all data from the riak cluster. Useful for debugging
    purposes.
  * new_domain.sh - Creates a new domain
  * new_domain_member.sh - Creates a new domain member (user) in a domain.
  * get_root_container.sh - Returns the metadata for the root container.
  * new_container.sh - Creates a new container.
  * new_dataobject.sh - Creates a new data object.
  * check_consistency.py - Checks the consistency of the objects - that data
    objects have the correct parent information, etc.

There are several scripts in the `./scripts` directory - some of them work,
some of them may not. All will likely need changing to reflect your riak
node names, administrator and user names and passwords, and the domain to
direct the request to. Domains are currently specified in the authorization
header. Here is an example using `curl` to make the request:

  `curl -u"userid:password;realm=default_domain"`

In the above example, `userid` is the user name, `password` is the user's
password, and `realm=default_domain` defines the target domain as the default
domain. In the future, domain maps will be supported to resolve the domain by
mapping against the Nebula URL.

## Bug reporting

Please log any issues that you run across here, and I'll try to get to them
as quickly as I can.
