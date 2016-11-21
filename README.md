Nginx Guard - Map JWT Claims to HTTP's headers request
====

Map claims values from the JWT Token to the HTTP Headers request, with
the ability to specify a custom mapping.

**:exclamation: We are using [SkyLothar/lua-resty-jwt](https://github.com/SkyLothar/lua-resty-jwt) as a
dependency, but as it is not available on OPM yet, we imported it under the lib
folder. When [it will be available on OPM](https://github.com/SkyLothar/lua-resty-jwt/issues/55), we could add it as an OPM dependency.**

Table of Contents
=================

* [Synopsis](#synopsis)
* [Description](#description)

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
          {
            foo = {
              mandatory = false,
              header = 'X-DM-Foo'
            }
          }
        )
      ';

      proxy_pass http://target/;
    }
  }
}
```

This example above will map the "foo" key from the JWT claims's values (into the
payload) to the `X-DM-Foo` HTTP Request's headers.

![Schema of GuardJWT](https://raw.githubusercontent.com/dailymotion/lua-nginx-guard-jwt/master/doc/guardjwt.jpg)

Description
===========

This library implements a simple way to map the claims values from a JWT Token
to the HTTP's Headers request.

Under the hood, this library uses:
* [lua-resty-jwt](https://github.com/SkyLothar/lua-resty-jwt)
* cjson

[Back to TOC](#table-of-contents)
