local g3d = require("libs.g3d")

local city = {
  base = g3d.newModel("assets/cells/zone_city.obj", "assets/cells/zone_city.png")
}

local road = { }
road.__index = road

road.addJunction = function(type)

end

road.draw = function(type)
  if type == "city" then
    city.base:draw()
  end
end

return road