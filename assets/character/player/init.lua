local lg = love.graphics
local g3d = require("libs.g3d")

local blackTexture = lg.newImage("assets/black_tile.png")

local plane = g3d.newModel("assets/character/character.obj", blackTexture)

local walk_frames = {
  lg.newImage("assets/character/player/player_000.png"),
  lg.newImage("assets/character/player/player_001.png"),
  lg.newImage("assets/character/player/player_002.png"),
  lg.newImage("assets/character/player/player_003.png"),
  lg.newImage("assets/character/player/player_004.png"),
  lg.newImage("assets/character/player/player_005.png"),
  lg.newImage("assets/character/player/player_006.png"),
  lg.newImage("assets/character/player/player_007.png"),
}

local idle_texture = walk_frames[1]

local character = require("src.character")
local player = character.new()
player.x, player.y = 0,0
player.speed = 6
player.frame, player.timer = 1,0

player.setZone = function(zone)
  player.x, player.y = 0, 0
  player.hc = zone.hc
  player.shape = player.hc:circle(player.x, player.y, 0.3)
  player.shape.user = "character"
end

local input = require("util.input")
player.update = function(dt)

  local mx, my = love.mouse.getPosition()
  local cw, ch = love.graphics.getDimensions()
  cw, ch = cw/2, ch/2

  local dx, dy = mx - cw, my - ch
  local angle = math.atan2(dy*-1, dx)
  player.shape:setRotation(angle)

  local x, y = input.baton:get("move")
  player.shape:move(x * player.speed * dt, y * player.speed * dt)
  local moved = x ~= 0 or y ~= 0

  for other, vector in pairs(player.hc:collisions(player.shape)) do
    if other.user ~= "character" and other.user ~= "collider" then
      player.shape:move(vector.x, vector.y)
      moved = moved or (vector.x ~= 0 or vector.y ~= 0)
    end
  end

  if moved then
    player.state = "walk"
  else
    player.state = "idle"
  end

  if player.state == "idle" then
    player.frame = 1
    player.timer = 0
  elseif player.state == "walk" then
    player.timer = player.timer + dt
    while player.timer >= 0.06 do
      player.timer = player.timer - 0.06
      player.frame = player.frame + 1
      if player.frame > #walk_frames then
        player.frame = 1
      end
    end
  end
end

player.draw = function()
  local x, y = player.shape:center()
  plane:setTranslation(x, y, 0.1)
  plane:setRotation(0, 0, player.shape:rotation()-math.rad(90))
  if player.state == "idle" then
    plane:setTexture(idle_texture)
  elseif player.state == "walk" then
    plane:setTexture(walk_frames[player.frame])
  else
    plane:setTexture(blackTexture)
  end
  plane:draw()
end

return player