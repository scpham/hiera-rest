Introduction
============

Hiera is a configuration data store with pluggable back ends; hiera-rest is a backend written to tie into a specific configuration management database. Although this database is proprietary, you could easily use it as a base for any other REST based database by editing the queries in the restquery method. This allows you to glue Hiera to an existing database via a REST API.

Configuration
=============
Here is a sample hiera.yaml file that will work with hiera_rest and fall back to yaml

<pre>
---
:hierarchy:
  - host/%{hostname}
  - superpod/%{superpod}
  - superpod/%{superpod}/pod/%{pod}
  - %{environment}/%{operatingsystem}
  - common

:backends:
  - rest
  - yaml

:yaml:
  :datadir: '/etc/puppetlabs/puppet/hieradata'

:rest:
  :server: 'configurations.domain.net'
  :port:  8080
  :api: '/api'
  
  # SSL options are optional, but if you specify one, specify all
  :cacrt: '/path/to/ca'    # CA certificate
  :crt: '/path/to/cert'    # Client certificate
  :crtkey: '/path/to/key'  # Client certificate key
</pre>

If the :cacrt key is set, then hiera-rest will attempt to make a valid SSL connection to your REST endpoint.

API Response
============

This is designed to make a REST query and will expect JSON in response. That JSON should look like:

    {
      "success" : true,
      "data" : [ {
        "@hostId" : "9e72f9d4-ed3a-3cba-904a-c25bd4e2b1a5",
        "id" : "8a8176466ab41c2d013ab41c32d4000b",
        "versionNumber" : 0,
        "createdBy" : "jing",
        "modifiedBy" : "jing",
        "createdDate" : 1351641498067,
        "modifiedDate" : 1351641498067,
        "name" : "na2-batch1-10-was",
        "smbiosguid" : "batch10",
        "assetTag" : "batch10",
        "operationalStatus" : "PRE_PRODUCTION",
        "cluster" : null,
        "make" : "dell",
        "model" : "r610",
        "deviceRole" : "BATCH",
        "networkInterfaces" : null
      } ],
      "total" : 1
    }'

You will almost certainly have to update the code path to match your own API and JSON response.

Limitations
============

Any queries it makes against your database must be hard coded into the restquery method. I am investigating more flexible alternatives, but don't hold your breath.

Contact
=======

* Author: Ben Ford
* Email: ben.ford@puppetlabs.com
* Twitter: @binford2k
* IRC (Freenode): binford2k

Credit
=======

The development of this code was sponsored by the ISD group at Salesforce.com.