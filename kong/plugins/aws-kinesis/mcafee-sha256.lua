local resty_sha256 = require "resty.sha256"

-- utils for sha256 hash
local CHAR_TO_HEX = {};
for i = 0, 255 do
  local char = string.char(i)
  local hex = string.format("%02x", i)
  CHAR_TO_HEX[char] = hex
end

local function hex_encode(str) -- From prosody's util.hex
  return (str:gsub(".", CHAR_TO_HEX))
end

return function(str)
  local sha256 = resty_sha256:new()
  sha256:update(str or "")
  local digest = sha256:final()
  return hex_encode(digest)
end