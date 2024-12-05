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
  love.mouse.setRelativeMode(false)
  love.mouse.setVisible(true)

  -- can zombie see player
  local tx, ty = player.shape:center()
  for i = 1, #zone.zombies do
    local z = zone.zombies[i]
    if z.health > 0 then
      local zx, zy = z.shape:center()
      if (tx - zx)^2 + (ty - zy)^2 <= (8)^2 then
        z.targetX, z.targetY = tx, ty
        --zombie.reason = "vision"
      end
    end
  end

  zone:update(dt)
  player.update(dt)
  scene.posX, scene.posY = player.shape:center()
  updateCamera()
end

local lg = love.graphics
scene.drawui = function()
  lg.setColor(1,1,1,1)
  lg.print(("%.2f"):format(player.attackCooldown))
end

scene.draw = function()
  lg.clear()
  lg.origin()
  road.draw("city")
  zone:draw()
  player.draw()
  lg.setDepthMode("always", true)
  lg.push("all")
  lg.origin()
  local ww, wh = love.graphics.getDimensions()
  lg.translate(ww/2, wh/2)
  -- if player.rect then
  --   lg.getLineWidth(1/50)
  --   lg.scale(50)
  --   player.rect:draw('line', true)
  --   lg.scale(0.5)
  --   player.shape:draw('line')
  -- end
  lg.pop()

  scene.drawui()
  lg.setDepthMode("lequal", true)
end

return scene