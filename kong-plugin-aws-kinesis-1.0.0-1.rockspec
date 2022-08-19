package = "kong-plugin-aws-kinesis"
version = "1.0.0-1"
supported_platforms = {"linux", "macosx"}

description = {
  summary = "Kong plugin to write to a AWS Kinesis Stream",
  homepage = "https://github.com/Aman7123/mcafee-aws-kinesis",
  license = "Apache"
}

dependencies = {
  "luapon >= 5.1",
  "jsonpath"
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.aws-kinesis.handler"] = "kong/plugins/aws-kinesis/handler.lua",
    ["kong.plugins.aws-kinesis.schema"] = "kong/plugins/aws-kinesis/schema.lua",
    ["kong.plugins.aws-kinesis.json-transform"] = "kong/plugins/aws-kinesis/json-transform.lua",
    ["kong.plugins.aws-kinesis.jsonpath"] = "kong/plugins/aws-kinesis/jsonpath.lua",
    ["kong.plugins.aws-kinesis.mcafee-transform"] = "kong/plugins/aws-kinesis/mcafee-transform.lua",
    ["kong.plugins.aws-kinesis.mcafee-sha256"] = "kong/plugins/aws-kinesis/mcafee-sha256.lua",
  }
}