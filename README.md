Nginx Guard - Verification of the JWT Token with mapping of the token claims values to the HTTP Headers
=======================================================================================================

**This library is under development, it is not ready for production use yet.**

Map claims values from the JWT Token to the HTTP Headers request, with
the ability to specify a custom mapping.

Installation
============

- via opm: `opm get dailymotion/lua-nginx-guard-jwt`

Table of Contents
=================

* [Synopsis](#synopsis)
* [Description](#description)
* [API - Methods](#api---methods)
    * [verify_and_map](#verify_and_map)
    * [raw_verify_and_map](#raw_verify_and_map)
* [Example: Gateway](#example-gateway)
* [Example: How to develop on GuardJWT ?](#example-how-to-develop-on-guardjwt-)

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
        local validators = require "resty.jwt-validators"

        j.GuardJWT.verify(
          {
            foo = {
              validators = validators.equals_any_of({ "bar", "baz" }),
              header = "X-DM-Foo"
            }
          },
          {
            secret = "guardjwt",
            is_token_mandatory = false
          }
        )
      ';

      proxy_pass http://target/;
    }
  }
}
```

This example above will:
1. Decrypt JWT token with the secret `guardjwt`
2. Get claim's value from the key `foo`
3. Verify if its value is equals to either "bar" or "baz"
4. Map the value to the `X-DM-Foo` HTTP Header.

![Schema of GuardJWT](https://raw.githubusercontent.com/dailymotion/lua-nginx-guard-jwt/master/doc/guardjwt.jpg)

Description
===========

This library implements a simple way to map the claim's values from a JWT Token
to the HTTP's Headers request.

Under the hood, this library uses:
* [lua-resty-jwt](https://github.com/cdbattags/lua-resty-jwt)

[Back to TOC](#table-of-contents)

API - Methods
=============

```lua
  local guard = require "guardjwt"
```

[Back to TOC](#table-of-contents)

verify_and_map
--------------

```
syntax: guard.GuardJWT.verify_and_map(claim_spec [, config])
```

Verify JTW Token from the 'Authorization' header with a specific specification.
Then, map claim values with associated header.

**`claim_spec` format**

```
{
  foo: {
    validators: [resty.jwt-validators] validator.
    header: optional [string] Header name used to map the claim value.
  },
  bar: {
    validators: [resty.jwt-validators] validator.
    header: optional [string] Header name used to map the claim value.
  },
}
```

Validators documentation is available directly on the [cdbattags repository](https://github.com/cdbattags/lua-resty-jwt#jwt-validators).

**`config` format**

```
{
  secret: [string] which describe private key to decode JWT,
  is_token_mandatory: [bool][default=false] is token is mandatory & valid.
  clear_authorization_header: [bool][default=true] Clear "Authorization" header
}
```

`secret`: Private key to decode JWT, if not present, the value is guessed from
the JWT_SECRET environment variable.
`is_token_mandatory`: Is token is mandatory & valid, false by default.
`clear_authorization_header`: Clear the "Authorization" header, true by default.

**example**

```lua
local j = require "guardjwt"
local validators = require "resty.jwt-validators"

j.GuardJWT.verify_and_map(
  {
    foo = {
      validators = validators.equals_any_of({ "bar" }),
      header = "X-DM-Foo"
    }
  },
  {
    secret = "guardjwt",
    is_token_mandatory = true,
    clear_authorization_header = true
  }
)
```

raw_verify_and_map
------------------

```
syntax: guard.GuardJWT.raw_verify_and_map(nginx, claim_spec [, config])
```

Verify JTW Token from the 'Authorization' header with a specific specification.
Then, map claim values with associated header.

* `nginx`: the NGINX object.
* `claim_spec` & `config`: Formats described above.

Example: Gateway
================

You can try the `guardjwt` module through the Gateway example _(./example/gateway)_.

```bash
# Run the target container (Where the traffic will be proxify)
docker-compose up target

# Run the gateway
docker-compose up gateway
```

When both containers are ready, you can send an HTTP Request to the gateway with a
JWT Token.

```bash
curl --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmb28iOiJiYXIifQ.DFmxCulxIMpi4fWbVbhnZLCJxvfSb6PhkGDQYsIyOks' http://localhost:8080/
```

You can see the HTTP Request proxify on the target log, with the decoded
headers.

```
target_1   | http GET /
target_1   | host: target
target_1   | connection: close
target_1   | user-agent: curl/7.47.1
target_1   | accept: */*
target_1   | x-dm-foo: bar
```

[Back to TOC](#table-of-contents)

Example: How to develop on GuardJWT ?
=====================================

As the method describe above, you have to start the target container first. It
will be used to handle proxify request. You should take a look of the logs to
debug the `guardjwt` module.

```bash
docker-compose up target
```

To develop, just update the file _(./lib/guardjwt.lua)_ and execute this commands.

```bash
make develop-run
```

[Back to TOC](#table-of-contents)
