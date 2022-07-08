local ngx = require "ngx"
local jwt = require "resty.jwt"

local _M = { _VERSION = '0.7.2' }

local GuardJWT = {}
_M.GuardJWT = GuardJWT


local function _tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


--@function Purge HTTP Request's headers mapped with the claim's values to
-- avoid header's injections (private method)
--@param nginx NGINX object
--@param claim_spec Mapping between claim's values and headers
local function _purge_headers(nginx, claim_spec)
  for _, claim_conf in pairs(claim_spec) do
    if claim_conf.header ~= nil then
      nginx.req.clear_header(string.lower(claim_conf.header))
    end
  end
end


--@function Get claim values from an authorization value (private method)
--@param nginx NGINX object
--@param claim_spec Claim's spec (Claim config, validators & header name)
--@param secret Secret key to decrypt JWT Token
--@param authorization Value from header "authorization"
--@return Claim values (Available in the token's "payload" key)
local function _guess_claim(nginx, claim_spec, secret, authorization)
  if authorization == nil then
    nginx.log(nginx.NOTICE, "[JWTGuard] No authorization header")
    return nil
  end

  local _, _, token = string.find(authorization, "Bearer%s+(.+)")

  if token == nil then
    nginx.log(nginx.NOTICE, "[JWTGuard] Token is missing")
    return nil
  end

  local jwt_claim_spec = {}
  for claim_key, claim_conf in pairs(claim_spec) do
    if claim_conf.validators ~= nil then
      jwt_claim_spec[claim_key] = claim_conf.validators
    end
  end

  local decoded_jwt = jwt:verify(secret, token, jwt_claim_spec)
  if decoded_jwt.verified == false then
    nginx.log(
      nginx.NOTICE,
      "[JWTGuard] JWT is not verified, reason: " .. decoded_jwt.reason
    )
    return nginx.exit(nginx.HTTP_UNAUTHORIZED)
  end

  return decoded_jwt['payload']
end


--@function Raw method to verify guest from the Authorization header then map
-- the claim values to the associated header. nginx object is guessed from the
-- global scope
--@param claim_spec Claim's spec (Claim config, validators & header name)
--   {
--     foo: {
--       validators: [resty.jwt-validators] validator.
--       header: [optional] Header name used to map the claim value.
--     },
--     bar: {
--       validators: [resty.jwt-validators] validator.
--       header: [optional] Header name used to map the claim value.
--     },
--   }
--@param cfg GuardJWT Configuration (Secret + Is token mandatory)
-- Format of cfg record:
--   {
--     secret: [string] which describe private key to decode JWT,
--     is_token_mandatory: [bool] is token is mandatory & valid,
--     clear_authorization_header: [bool] Clear "Authorization" header
--   }
function GuardJWT.verify_and_map(claim_spec, cfg)
  GuardJWT.raw_verify_and_map(ngx, claim_spec, cfg)
end


--@function Raw method to verify guest from the Authorization header then map
-- the claim values to the associated header.
--@param nginx NGINX object
--@param claim_spec Claim's spec (Claim config, validators & header name)
--   {
--     foo: {
--       validators: [resty.jwt-validators] validator.
--       header: [optional] Header name used to map the claim value.
--     },
--     bar: {
--       validators: [resty.jwt-validators] validator.
--       header: [optional] Header name used to map the claim value.
--     },
--   }
--@param cfg GuardJWT Configuration (Secret + Is token mandatory)
-- Format of cfg record:
--   {
--     secret: [string] which describe private key to decode JWT,
--     is_token_mandatory: [bool] is token is mandatory & valid.
--     clear_authorization_header: [bool] Clear "Authorization" header
--   }
function GuardJWT.raw_verify_and_map(nginx, claim_spec, cfg)
  assert(type(claim_spec) == 'table', "[JWTGuard] claim_spec is mandatory")
  assert(
    _tablelength(claim_spec) > 0,
    "[JWTGuard] claim_spec should not be empty"
  )

  if type(cfg) ~= 'table' then
    cfg = {}
  end

  if cfg.secret == nil then
    cfg['secret'] = os.getenv("JWT_SECRET")
  end

  if cfg.is_token_mandatory == nil then
    cfg['is_token_mandatory'] = false
  end

  if cfg.clear_authorization_header == nil then
    cfg['clear_authorization_header'] = true
  end

  _purge_headers(nginx, claim_spec)

  local claim = _guess_claim(
    nginx,
    claim_spec,
    cfg.secret,
    nginx.req.get_headers()["authorization"]
  )

  if cfg.is_token_mandatory == false and claim == nil then
    nginx.log(nginx.DEBUG, "[JWTGuard] No JWT provided")
    return
  end

  if cfg.is_token_mandatory and (type(claim) ~= 'table' or _tablelength(claim) <= 0) then
    nginx.log(nginx.ERR, "[JWTGuard] No Authorization provided")
    return nginx.exit(nginx.HTTP_UNAUTHORIZED)
  end

  for claim_key, claim_conf in pairs(claim_spec) do
    local claim_value = claim[claim_key]

    if claim_value ~= nil and type(claim_value) ~= 'userdata' and claim_conf.header ~= nil then
      nginx.log(nginx.DEBUG, "[JWTGuard] Add Claim '" .. claim_value .. "' to header '" .. claim_conf.header .. "'")
      nginx.req.set_header(claim_conf.header, claim_value)
    end
  end

  if cfg.clear_authorization_header then
    nginx.req.clear_header("authorization")
  end

  return claim
end

return _M
