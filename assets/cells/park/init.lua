local cell = require("src.cell")
local g3d = require("libs.g3d")

local model = g3d.newModel("assets/zones/park/model.obj", "assets/zones/park/texture.png")
local plane = g3d.newModel("assets/zones/plane.obj", "assets/zones/park/plane.png")
--local plane = love.graphics.newImage("assets/zones/park/plane.png")
--plane:setFilter("nearest", "nearest")

local park = cell.new()

park.draw = function()
  plane:draw()
  model:draw()
  --love.graphics.draw(plane, 0,0, 0, 1.5)
end

return park