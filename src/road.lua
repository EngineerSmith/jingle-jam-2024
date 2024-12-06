local g3d = require("libs.g3d")

local city = {
  base = g3d.newModel("assets/cells/zone_city.obj", "assets/cells/zone_city.png"),
  wall = g3d.newModel("assets/cells/wall_city.obj", "assets/cells/mist.png")
}

local road = { }
road.__index = road

road.addJunction = function(type)

end

local createRectCollider = function(hc, rect, offsetX, offsetY)
  local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
  for i = 1, 7, 2 do
    minX = math.min(minX, rect[i])
    maxX = math.max(maxX, rect[i])
    minY = math.min(minY, rect[i+1])
    maxY = math.max(maxY, rect[i+1])
  end

  local x, y = minX + offsetX, minY + offsetY
  local width, height = maxX - minX, maxY - minY
  local shape = hc:rectangle(x, y, width, height)
  shape.user = "building"
  shape.user2 = table.concat(rect, ", ")
end

road.createColliders = function(type, hc)
  if type == "city" then
    createRectCollider(hc, {
       146, -140, 146, -172,
      -146, -140, -146, -172
    }, 0, 0)
    createRectCollider(hc, {
      140,  145,  172, -145,
      140, -147,  172, -147
    }, 0, 0)
    createRectCollider(hc, {
     -146,  140, -146,  172,
      146,  140,  146,  172
    }, 0, 0)
    createRectCollider(hc, {
     -139, -147, -171, -147,
     -139,  145, -171,  145
    }, 0, 0)
  end
end

road.draw = function(type)
  if type == "city" then
    city.base:draw()
    city.wall:draw()
  end
end

return road