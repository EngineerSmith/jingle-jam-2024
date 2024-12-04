local lg = love.graphics
local g3d = require("libs.g3d")

local plane = g3d.newModel("assets/character/character.obj", nil, { 0,0,0.04 })

lg.setDefaultFilter("nearest", "nearest")
local textures = {
  -- lg.newImage("assets/blood/blood_001.png"),
  -- lg.newImage("assets/blood/blood_002.png"),
  lg.newImage("assets/blood/blood_splat.png"),
}

local blood = { }
blood.__index = blood

blood.new = function(x, y, r)
  return {
    x = x or 0,
    y = y or 0,
    r = r or 0,
    texture = textures[love.math.random(1, #textures)]
  }
end

blood.draw = function(bloods)
  lg.setShader(g3d.shader)
  g3d.shader:send("modelMatrix", plane.matrix)
  local cam = g3d.camera:current()
  g3d.shader:send("viewMatrix", cam:getViewMatrix())
  g3d.shader:send("projectionMatrix", cam:getProjectionMatrix())
  for _, blood in ipairs(bloods) do
    plane.mesh:setTexture(blood.texture)
    lg.draw(plane.mesh, blood.x, blood.y, blood.r)
  end
  lg.setShader()
end

return blood