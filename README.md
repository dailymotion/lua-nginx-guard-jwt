Name
====

lua-nginx-guard-jwt - Map JWT claims values to the HTTP Headers request, with
the ability to specify a custom mapping.

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsis](#synopsis)
* [Description](#description)

Status
======

This library is still under early development and is production ready.

Synopsis
========

```lua
# nginx.conf

http {
  server {
    listen 80;
    server_name localhost;

    location = / {
      access_by_lua '
        local j = require "guardjwt"
        j.GuardJWT.auth(
          ngx,
          {
            foo = {
              mandatory = false,
              header = 'X-DM-Foo'
            }
          },
          true
        )
      ';

      proxy_pass http://target/;
    }
  }
}
```

Description
===========

This library implements a simple way to map the claims values from a JWT Token
with the HTTP Headers.

Under the hood, this library uses:
* [lua-resty-jwt](https://github.com/SkyLothar/lua-resty-jwt)
* cjson

[Back to TOC](#table-of-contents)
