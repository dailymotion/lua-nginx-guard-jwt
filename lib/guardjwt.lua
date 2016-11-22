local ngx = require "ngx"
local cjson = require "cjson"
local jwt = require "resty.jwt"

local _M = { _VERSION = '0.4' }

local GuardJWT = {}
_M.GuardJWT = GuardJWT


function _tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


--@function Get claims values from a authorization value (private method)
--@param nginx NGINX object
--@param authorization Value from header "authorization"
--@param secret Secret key to decrypt JWT Token
--@return Claims values (Available in the token's "payload" key)
function _get_claims(nginx, authorization, secret)
  if authorization == nil then
      nginx.log(nginx.NOTICE, "[JWTGuard] No authorization header")
      return nil
  end

  local _, _, token = string.find(authorization, "Bearer%s+(.+)")

  if token == nil then
      nginx.log(nginx.NOTICE, "[JWTGuard] Token is missing")
      return nil
  end

  local decoded_jwt = jwt:verify(secret, token)
  if decoded_jwt.verified == false then
      nginx.log(nginx.NOTICE, "[JWTGuard] JWT is not verified, reason: " .. decoded_jwt.reason)
      return nil
  end

  return decoded_jwt['payload']
end


--@function Purge HTTP Request's headers mapped with the claims's values to
-- avoid header's injections (private method)
--@param nginx NGINX object
--@param claims_to_headers_mapping Mapping between claims's values and headers
function _purge_headers(nginx, claims_to_headers_mapping)
  for _, claim_conf in pairs(claims_to_headers_mapping) do
    nginx.req.clear_header(string.lower(claim_conf.header))
  end
end


--@function Raw method to authenticate guest from the Authorization header.
--@param nginx NGINX object
--@param claims_to_headers_mapping Mapping configuration between claim's values
-- and HTTP Request's headers
--@param is_token_mandatory Set if JWT token must be valid et present,
-- false by default
--@param secret Secret used to decrypt JWT Token guess from JWT_SECRET env
-- variable if not present
function GuardJWT.raw_auth(nginx, claims_to_headers_mapping, is_token_mandatory, secret)
    assert(type(claims_to_headers_mapping) == 'table', "[JWTGuard] claims_to_headers_mapping is mandatory")
    assert(_tablelength(claims_to_headers_mapping) > 0, "[JWTGuard] claims_to_headers_mapping should not be empty")

    _purge_headers(nginx, claims_to_headers_mapping)

    local claims = _get_claims(nginx, nginx.req.get_headers()["authorization"], secret)

    if is_token_mandatory and (type(claims) ~= 'table' or _tablelength(claims) <= 0) then
        nginx.log(nginx.ERR, "[JWTGuard] No Authorization provided")
        return nginx.exit(nginx.HTTP_UNAUTHORIZED)
    end

    for claim_key, claim_conf in pairs(claims_to_headers_mapping) do
        claim_value = claims[claim_key]

        if claim_conf.mandatory and claim_value == nil then
          nginx.log(nginx.ERR, "[JWTGuard] Claim '" .. claim_key .. "' is not present into the JWT Token, it must be.")
          return nginx.exit(nginx.HTTP_UNAUTHORIZED)
        end

        if claim_value ~= nil then
          nginx.log(nginx.DEBUG, "Add Claim '" .. claim_value .. "' to header '" .. claim_conf.header .. "'")
          nginx.req.set_header(claim_conf.header, claim_value)
          nginx.req.clear_header("authorization")
        end
    end
end


--@function Method to authenticate guest from the Authorization header.
-- nginx object if guessed from the global scope
--@param claims_to_headers_mapping Mapping configuration between claim's values
-- and HTTP Request's headers
--@param is_token_mandatory Set if JWT token must be valid et present,
-- false by default
--@param secret Secret used to decrypt JWT Token, guessed from JWT_SECRET env
-- variable if not present
function GuardJWT.auth(claims_to_headers_mapping, is_token_mandatory, secret)
    if secret == nil then
      secret = os.getenv("JWT_SECRET")
    end

    GuardJWT.raw_auth(ngx, claims_to_headers_mapping, is_token_mandatory, secret)
end

return _M
