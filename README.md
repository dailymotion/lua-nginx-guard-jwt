Nginx Guard - Verification of the JWT Token with mapping of the token claims
values to the HTTP Headers of Query.
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
curl --header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJmb28iOiJiYXIifQ.CJRON1D28gXmufyx-Z7Erm_hvx480yhw5KwFrZkfKoM' http://localhost:8080/
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
