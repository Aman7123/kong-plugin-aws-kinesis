local cjson = require "cjson.safe"
local jsont = require "kong.plugins.aws-kinesis.json-transform"
local sha256 = require "kong.plugins.aws-kinesis.mcafee-sha256"

return function(config, params, headers, client_ip)
  if(type(params) ~= "table") then
    return nil, "params must be a table"
  end
  -- Init output value
  local upstreamKinesisBody = {}
  -- Transforming JSON or multipart body to Lua Table
  local paramsAsString = cjson.encode(params)

  ngx.log(ngx.INFO, "In Body Request: "..paramsAsString)

  -- Obtain Kinesis "Data" from known locations (x4 methods)
  local inputData = {} -- Array of upstream objects
  if config.batched then
    if (params["records"] ~= nil) or (params["Records"] ~= nil) then
      inputData = params["records"] or params["Records"]
    end
  else
    inputData[1] = {}
    if params["Data"] ~= nil then
      inputData[1] = params
    elseif #paramsAsString > 2 then
      inputData[1]["Data"] = params
    end
  end
  if config.data_template ~= nil then
    local template = cjson.decode(config.data_template)
    inputData[1]["Data"] = jsont.transform(template, params, headers, client_ip)
  end

  -- Obtain Kinesis "PartitionKey" from known locations
  for _, record in pairs(inputData) do
    -- Get "Data" from record and make string
    local recordData = {}
    if record["Data"] ~= nil then
      recordData = record["Data"]
    end
    local recordDataAsString = cjson.encode(recordData)

    -- If "PartitionKey" was not found calculate it from sha256 of "Data"
    if record["PartitionKey"] == nil then
      local checksum = sha256(recordDataAsString)
      record["PartitionKey"] = checksum
    end

    -- Base64 encode "Data"
    record["Data"] = ngx.encode_base64(recordDataAsString)
  end

  -- Get stream name from config
  upstreamKinesisBody["StreamName"] = config.stream_name

  -- Process final outbound Kinesis body
  if config.batched then
    upstreamKinesisBody["Records"] = inputData
  else
    upstreamKinesisBody["Data"] = inputData[1]["Data"]
    upstreamKinesisBody["PartitionKey"] = inputData[1]["PartitionKey"]
  end
   

  return upstreamKinesisBody, nil
end