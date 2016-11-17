local ngx = require "ngx"
local cjson = require "cjson"
local jwt = require "resty.jwt"

local _M = { _VERSION = '0.4' }

local GuardJWT = {}
_M.GuardJWT = GuardJWT

function _get_claims(nginx, authorization, secret)
  if secret == nil then
    secret = os.getenv("JWT_SECRET")
  end

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

function _purge_headers(nginx, claims_to_headers_mapping)
  for _, claim_conf in pairs(claims_to_headers_mapping) do
    nginx.req.clear_header(string.lower(claim_conf.header))
  end
end

function GuardJWT.auth(nginx, claims_to_headers_mapping, is_token_mandatory)
    assert(type(claims_to_headers_mapping) == 'table', "[JWTGuard] claims_to_headers_mapping is mandatory")
    assert(#claims_to_headers_mapping <= 0, "[JWTGuard] claims_to_headers_mapping should not be empty")

    _purge_headers(nginx, claims_to_headers_mapping)

    local claims = _get_claims(nginx, nginx.req.get_headers()["authorization"])

    if is_token_mandatory and type(claims) ~= 'table' and #claims <= 0 then
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
        end
    end
end

return _M
