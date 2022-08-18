-- load the base plugin object and create a subclass
local plugin = require("kong.plugins.base_plugin"):extend()
local cjson = require "cjson.safe"
local bodyt = require "kong.plugins.aws-kinesis.mcafee-transform"
local aws_v4 = require "kong.plugins.aws-lambda.v4"
local http = require "resty.http"
local Multipart = require "multipart"
local CONTENT_TYPE = "content-type"

-- constructor
function plugin:new()
  plugin.super.new(self, "aws-kinesis")  
end

-- McAfee / Kong PoC function
-- Can be found: https://github.com/rbang1/kong-plugin-aws-kinesis
local function retrieve_parameters()
  ngx.req.read_body()
  local body_parameters, err
  local content_type = ngx.req.get_headers()[CONTENT_TYPE]
  if content_type and string.find(content_type:lower(), "multipart/form-data", nil, true) then
    body_parameters = Multipart(ngx.req.get_body_data(), content_type):get_all()
  elseif content_type and string.find(content_type:lower(), "application/json", nil, true) then
    body_parameters, err = cjson.decode(ngx.req.get_body_data())
    if err then
      body_parameters = {}
    end
  else
    body_parameters = ngx.req.get_post_args()
  end

  return utils.table_merge(ngx.req.get_uri_args(), body_parameters)
end

-- runs in the 'access_by_lua_block'
function plugin:access(config)
  plugin.super.access(self)

  local params = retrieve_parameters()
  -- set client ip
  local client_ip = ngx.var.remote_addr
  if ngx.req.get_headers()['x-forwarded-for'] then
    client_ip = string.match(ngx.req.get_headers()['x-forwarded-for'], "[^,%s]+")
  end
  -- get headers
  local headers = ngx.req.get_headers()

  -- set request type i.e. record vs records
  local request_type = "Kinesis_20131202.PutRecord"
  local body = bodyt(config, params, headers, client_ip)
  local bodyJson = cjson.encode(body)
  if config.batched then
    request_type = "Kinesis_20131202.PutRecords"
  end

  local opts = {
    region = config.aws_region,
    service = "kinesis",
    method = "POST",
    headers = {
      ["X-Amz-Target"] = request_type,
      ["Content-Type"] = "application/x-amz-json-1.1",
      ["Content-Length"] = tostring(#bodyJson)
    },
    body = bodyJson,
    path = "/",
    access_key = config.aws_key,
    secret_key = config.aws_secret,
  }

  if config.aws_debug then
    ngx.log(ngx.INFO, "AWS Request: "..cjson.encode(opts))
  end

  local request, err = aws_v4(opts)
  if err then
    return kong.response.exit(500,  err)
  end

  -- Trigger request
  local host = string.format("kinesis.%s.amazonaws.com", config.aws_region)
  local client = http.new()
  -- client:connect(host, 443)
  -- client:set_timeout(config.timeout)
  -- local ok, err = client:ssl_handshake()
  -- if not ok then
  --   return kong.response.exit(500,  err)
  -- end

  -- Replaced request to mockbin
  local upstreamHost = request.headers["Host"]
  request.headers["Host"] = "mockbin.org"
  request.headers["X-Kinesis-URL"] = host
  request.headers["X-Host-Original"] = upstreamHost
  local res, err = client:request_uri("https://mockbin.org/bin/27f1ffd0-fedb-4774-9bc6-fa870ef4e31d", {
    method = "POST",
    body = request.body,
    headers = request.headers,
    ssl_verify = false
  })
  return kong.response.exit(res.status, res.body, {["Content-Type"] = "application/json"})

  -- local res, err = client:request {
  --   method = "POST",
  --   path = request.url,
  --   body = request.body,
  --   headers = request.headers
  -- }

  -- if not res then
  --   return kong.response.exit(500,  err)
  -- end

  -- local resp_body = res:read_body()
  -- local resp_headers = res.headers

  -- local ok, err = client:set_keepalive(config.keepalive)
  -- if not ok then
  --   return kong.response.exit(500,  err)
  -- end

  -- ngx.status = res.status

  -- -- Send response to client
  -- for k, v in pairs(resp_headers) do
  --   ngx.header[k] = v
  -- end

  -- ngx.say(resp_body)

  -- return ngx.exit(res.status)
end

-- set the plugin priority, which determines plugin execution order
plugin.PRIORITY = 750

-- return our plugin object
return plugin