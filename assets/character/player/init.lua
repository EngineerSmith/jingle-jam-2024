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

local pistolCooldown, pistolNoise, pistolDamage = 0.2, 40, 3
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
local pistol_flash = lg.newImage("assets/character/player/player_pistol_flash.png")

local batCooldown, batNoise, batDamage, batSizeW, batSizeH = 0.12, 5, 1.5, 0.4, 0.7
local bat_frames = {
  lg.newImage("assets/character/player/player_bat_000.png"),
  lg.newImage("assets/character/player/player_bat_001.png"),
  lg.newImage("assets/character/player/player_bat_002.png"),
  lg.newImage("assets/character/player/player_bat_003.png"),
  lg.newImage("assets/character/player/player_bat_004.png"),
  lg.newImage("assets/character/player/player_bat_005.png"),
  lg.newImage("assets/character/player/player_bat_006.png"),
  lg.newImage("assets/character/player/player_bat_007.png"),
}
local bat_swing = {
  lg.newImage("assets/character/player/player_bat_swing_000.png"),
  lg.newImage("assets/character/player/player_bat_swing_001.png"),
  lg.newImage("assets/character/player/player_bat_swing_002.png"),
  lg.newImage("assets/character/player/player_bat_swing_003.png"),
  lg.newImage("assets/character/player/player_bat_swing_004.png"),
  lg.newImage("assets/character/player/player_bat_swing_005.png"),
}

local character = require("src.character")
local player = character.new()
player.x, player.y = 0,0
player.speed, player.size = 6, 0.3
player.frame, player.timer = 1,0
player.attackCooldown = 0
player.attack = "bat" -- "pistol"

player.frames = player.attack == "pistol" and pistol_frames or player.attack == "bat" and bat_frames or walk_frames

player.setZone = function(zone)
  player.zone = zone
  player.x, player.y = 0, 0
  player.hc = zone.hc
  player.shape = player.hc:circle(player.x, player.y, player.size)
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

  if player.state ~= "swing_bat" then
    if moved then
      player.state = "walk"
    else
      player.state = "idle"
    end
  end

  player.attackCooldown = player.attackCooldown - dt
  if player.attackCooldown <= 0 then
    player.attackCooldown = 0
  end
  if player.specialTexture == pistol_flash and player.attackCooldown <= pistolCooldown-0.1 then
    player.specialTexture = nil
  end

  if player.rect then
    local x, y = player.shape:center()
    player.rect:moveTo(x, y)
    player.rect:setRotation(player.shape:rotation(), x, y)
    player.rect:moveTo(x-nx*batSizeH, y+ny*batSizeH)
  end

  if player.attack == "bat" then
    if input.baton:pressed("attack") then
      if player.attackCooldown == 0 then
        player.attackCooldown = batCooldown
        player.state = "swing_bat"
        player.timer, player.frame = 0, 1

        local x, y = player.shape:center()
        player.zone:makeNoise(batNoise, x, y)

        player.rect = player.rect or player.hc:rectangle(0, 0, batSizeH*2, batSizeW)
        local rect = player.rect
        rect.user = "collider"
        rect:moveTo(x, y)
        rect:setRotation(player.shape:rotation(), x, y)
        rect:moveTo(x-nx*batSizeH, y+ny*batSizeH)
        for shape in pairs(player.hc:collisions(rect)) do
          if shape.user == "character" and shape.user2 == "zombie" and shape.user3.health ~= 0 then
            shape.user3:hit(batDamage, player.zone)
          end
        end
        --player.hc:remove(rect)
      end
    end
  elseif player.attack == "pistol" then
    if input.baton:pressed("attack") then
      if player.attackCooldown == 0 then
        player.attackCooldown = pistolCooldown
        local x, y = player.shape:center()
        player.zone:makeNoise(pistolNoise, x, y)

        local bullet = player.hc:point(x, y)
        bullet:move(-nx*player.size, ny*player.size)
        local dist, step = 0, .05
        while dist <= 20 do
          for shape in pairs(player.hc:collisions(bullet)) do
            if shape.user == "character" and shape.user2 == "zombie" and shape.user3.health ~= 0 then
              shape.user3:hit(pistolDamage, player.zone)
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
      end
    end
  end

  if player.state == "idle" then
    player.frame, player.timer = 1, 0
  elseif player.state == "walk" then
    player.timer = player.timer + dt
    while player.timer >= 0.06 do
      player.timer = player.timer - 0.06
      player.frame = player.frame + 1
      if player.frame > #player.frames then
        player.frame = 1
      end
    end
  elseif player.state == "swing_bat" then
    player.timer = player.timer + dt
    while player.timer >= batCooldown/#bat_swing do
      player.timer = player.timer - 0.06
      player.frame = player.frame + 1
      if player.frame > #bat_swing then
        player.state = "idle"
        player.timer, player.frame = 0, 1
        break
      end
    end
  end
end

player.draw = function()
  local x, y = player.shape:center()
  plane:setTranslation(x, y, 0.1)
  plane:setRotation(0, 0, player.shape:rotation()-math.rad(90))
  if player.specialTexture then
    plane:setTexture(player.specialTexture)
  elseif player.state == "swing_bat" then
    plane:setTexture(bat_swing[player.frame])
  elseif player.state == "idle" then
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