local g3d = require("libs.g3d")
local cam = g3d.camera:current()
cam.fov = math.rad(50)
cam:updateProjectionMatrix()

local input = require("util.input")

do
 require("assets.cells.park")
 require("assets.cells.city_res")
end
local road = require("src.road")

local zone = require("src.zone").getZone("city")

local player = require("assets.character.player")
player.setZone(zone)

local scene = {
  posX = 0, posY = 0, speed = 15
}

local updateCamera = function()
  g3d.camera.current():lookAt(scene.posX, scene.posY, 25, scene.posX, scene.posY-0.000001, 0)
end

scene.load = function()
  updateCamera()
end

scene.resize = function(w, h)
  local cam = g3d.camera:current()
  cam.aspectRatio = (w/h)
  cam:updateProjectionMatrix()
end

scene.update = function(dt)

  -- TODO if mouse wiggle, show mouse?
    -- if suit.gamepadActive then
    --   love.mouse.setRelativeMode(true)
    --   love.mouse.setVisible(false)
    -- else
    --   love.mouse.setRelativeMode(false)
    --   love.mouse.setVisible(true)
    -- end
  --

  local tx, ty = player.shape:center()
  for i = 1, #zone.zombies/2 do
    local z = zone.zombies[i]
    z.targetX, z.targetY = tx, ty
  end

  zone:update(dt)
  player.update(dt)
  scene.posX, scene.posY = player.shape:center()
  updateCamera()
end

scene.draw = function()
  love.graphics.clear()
  road.draw("city")
  zone:draw()
  player.draw()
end

return scene