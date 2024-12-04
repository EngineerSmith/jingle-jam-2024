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

local pistol_frames = {
  lg.newImage("assets/character/player/player_pistol_000.png"),
  lg.newImage("assets/character/player/player_pistol_001.png"),
  lg.newImage("assets/character/player/player_pistol_002.png"),
  lg.newImage("assets/character/player/player_pistol_003.png"),
  lg.newImage("assets/character/player/player_pistol_004.png"),
  lg.newImage("assets/character/player/player_pistol_005.png"),
  lg.newImage("assets/character/player/player_pistol_006.png"),
  lg.newImage("assets/character/player/player_pistol_007.png"),
}

local character = require("src.character")
local player = character.new()
player.x, player.y = 0,0
player.speed = 6
player.frame, player.timer = 1,0
player.frames = pistol_frames
player.attackCooldown = 0
player.attackDamage = 3

player.setZone = function(zone)
  player.zone = zone
  player.x, player.y = 0, 0
  player.hc = zone.hc
  player.shape = player.hc:circle(player.x, player.y, 0.3)
  player.shape.user = "character"
end

local Nx, Ny = 0, 0
local input = require("util.input")
player.update = function(dt, zombies)

  local mx, my = love.mouse.getPosition()
  local cw, ch = love.graphics.getDimensions()
  cw, ch = cw/2, ch/2

  local dx, dy = mx - cw, my - ch
  local nx, ny = dx, dy
  local mag = math.sqrt(nx^2+ny^2)
  nx, ny = nx/mag, ny/mag
  Nx, Ny = nx, ny

  local angle = math.atan2(ny*-1, nx)
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

  player.attackCooldown = player.attackCooldown - dt
  if player.attackCooldown <= 0 then
    player.attackCooldown = 0
  end

  if input.baton:pressed("attack") then
    if player.attackCooldown == 0 then
      player.attackCooldown = 0.1

      local bullet = player.hc:point(player.shape:center())
      bullet:move(-nx*.3, ny*.3)
      local dist, step = 0, .1
      while dist <= 20 do
        for shape in pairs(player.hc:collisions(bullet)) do
          if shape.user == "character" and shape.user2 == "zombie" and shape.user3.health ~= 0 then
            shape.user3:hit(player.attackDamage, player.zone)
            goto breakOut
          end
          if shape.user == "building" then
            goto breakOut
          end
        end
        bullet:move(-nx*step, ny*step)
        dist = dist + step
      end
      ::breakOut::
    else

    end
  end

  if player.state == "idle" then
    player.frame = 1
    player.timer = 0
  elseif player.state == "walk" then
    player.timer = player.timer + dt
    while player.timer >= 0.06 do
      player.timer = player.timer - 0.06
      player.frame = player.frame + 1
      if player.frame > #player.frames then
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
    plane:setTexture(player.frames[1])
  elseif player.state == "walk" then
    plane:setTexture(player.frames[player.frame])
  else
    plane:setTexture(blackTexture)
  end
  plane:draw()
end

-- player.draw2 = function()
--   lg.push("all")
--   lg.setShader()
--   lg.origin()
--   local ww, wh = love.graphics.getDimensions()
--   lg.translate(ww/2, wh/2)
--   local x, y = player.shape:center()
--   lg.line(x, y, x + Nx*20, y + Ny*20)
--   --lg.rectangle("fill", x,y,50,50)
--   lg.pop()
-- end

return player