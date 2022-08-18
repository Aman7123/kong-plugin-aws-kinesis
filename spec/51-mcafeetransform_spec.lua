local PLUGIN_NAME = "aws-kinesis"
local mcafee = require("kong.plugins."..PLUGIN_NAME..".mcafee-transform")
local sha256 = require("kong.plugins."..PLUGIN_NAME..".mcafee-sha256")
local cjson = require("cjson")

local dummy_simple_conf = {
  aws_key = "aws_key",
  aws_secret = "aws_secret",
  aws_region = "aws_region",
  stream_name = "stream_name"
}

local dummy_batched_simple_conf = {
  aws_key = "aws_key",
  aws_secret = "aws_secret",
  aws_region = "aws_region",
  stream_name = "stream_name",
  batched = true
}

local global_body = '{"hc21":"79b0d973","hsst":"2021-09-21T11:10:22.000Z","t":"event","eid":"cui_shortcuts_view_securevpn","hc1":"CUI - Shortcuts","hc4":"home"}'
local global_parition_key = "9024-2239e3a01ff7"
local body_with_data_and_parition_key = '{"Data":'..global_body..',"PartitionKey":"'..global_parition_key..'"}'
local batched_body = '{"records":[{"Data":'..global_body..'}]}'
local batched_body_and_partition_key = '{"records":[{"Data":'..global_body..',"PartitionKey":"'..global_parition_key..'"}]}'

describe('mcafee-transform', function()
  describe('global_body', function()
    it('works', function()
      local upstream_body = cjson.decode(global_body)
      local body = mcafee(dummy_simple_conf, upstream_body, nil, nil)
      
      assert(type(body.PartitionKey) == "string")
      assert(type(body.Data) == "string")
      assert(body.StreamName == dummy_simple_conf.stream_name)
    end)
  end)

  describe('body_with_data_and_parition_key', function()
    it('works', function()
      local upstream_body = cjson.decode(body_with_data_and_parition_key)
      local body = mcafee(dummy_simple_conf, upstream_body, nil, nil)
      
      assert(body.PartitionKey == global_parition_key)
      assert(type(body.Data) == "string")
      assert(body.StreamName == dummy_simple_conf.stream_name)
    end)
  end)

  describe('batched_body', function()
    it('works', function()
      local upstream_body = cjson.decode(batched_body)
      local body = mcafee(dummy_batched_simple_conf, upstream_body, nil, nil)
      
      assert(type(body["Records"][1]["PartitionKey"]) == "string")
      assert(type(body["Records"][1]["Data"]) == "string")
      assert(body.StreamName == dummy_simple_conf.stream_name)
    end)
  end)

  describe('batched_body_and_partition_key', function()
    it('works', function()
      local upstream_body = cjson.decode(batched_body_and_partition_key)
      local body = mcafee(dummy_batched_simple_conf, upstream_body, nil, nil)
      
      assert(body["Records"][1]["PartitionKey"] == global_parition_key)
      assert(type(body["Records"][1]["Data"]) == "string")
      assert(body.StreamName == dummy_simple_conf.stream_name)
    end)
  end)
end)