local PLUGIN_NAME = "aws-kinesis"
local sha256 = require("kong.plugins."..PLUGIN_NAME..".mcafee-sha256")
local cjson = require("cjson")

local gloabl_value = "test"
local global_value_sha256 = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"

describe('mcafee-sha256', function()
  describe('validate sha256', function()
    it('works', function()
      local body = sha256(gloabl_value)
      assert(body == global_value_sha256)
    end)
  end)
end)