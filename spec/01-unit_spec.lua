local PLUGIN_NAME = "aws-kinesis"

-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end

describe(PLUGIN_NAME .. ": (schema)", function()
  it("minimal configuration", function()
    local ok, err = validate({
      aws_key = "key",
      aws_secret = "secret",
      aws_region = "us-east-1",
      stream_name = "stream",
    })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

  it("minimal configuration - with data-template", function()
    local ok, err = validate({
      aws_key = "key",
      aws_secret = "secret",
      aws_region = "us-east-1",
      stream_name = "stream",
      data_template = '{"ip": "clientip|", "payload": "param|$", "host": "header|$.host"}'
    })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)
end)
