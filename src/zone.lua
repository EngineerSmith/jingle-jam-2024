local zone = { }
zone.__index = zone

zone.new = function()
  return setmetatable({ }, zone)
end

zone.draw = function()

end

return zone