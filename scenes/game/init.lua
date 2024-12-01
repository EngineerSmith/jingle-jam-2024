local g3d = require("libs.g3d")
local cam = g3d.camera:current()
cam.fov = math.rad(50)
cam:updateProjectionMatrix()

local input = require("util.input")

local park = require("assets.zones.park")

local scene = {
  posX = 0, posY = 0, speed = 15
}

local updateCamera = function()
  g3d.camera.current():lookAt(scene.posX, scene.posY, 20, scene.posX, scene.posY-.000001, 0)
end

scene.load = function()
  updateCamera()
end

scene.draw = function()
  love.graphics.clear()
  park:draw()
end

scene.resize = function(w, h)
  local cam = g3d.camera:current()
  cam.aspectRatio = (w/h)
  cam:updateProjectionMatrix()
end

scene.update = function(dt)
  local x, y = input.baton:get("move")

  scene.posX, scene.posY = scene.posX + x * scene.speed * dt, scene.posY + y * scene.speed * dt
  updateCamera()
end

return scene