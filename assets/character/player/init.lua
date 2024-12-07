local lg = love.graphics
local g3d = require("libs.g3d")
local audioManager = require("util.audioManager")
local assetManager = require("util.assetManager")
local logger = require("util.logger")

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
local pistol_flash = lg.newImage("assets/character/player/player_pistol_flash.png")

local batSizeW, batSizeH = 0.4, 0.7
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

local knifeSizeW, knifeSizeH = 0.4, 0.5
local knife_frames = {
  lg.newImage("assets/character/player/player_knife_000.png"),
  lg.newImage("assets/character/player/player_knife_001.png"),
  lg.newImage("assets/character/player/player_knife_002.png"),
  lg.newImage("assets/character/player/player_knife_003.png"),
  lg.newImage("assets/character/player/player_knife_004.png"),
  lg.newImage("assets/character/player/player_knife_005.png"),
  lg.newImage("assets/character/player/player_knife_006.png"),
  lg.newImage("assets/character/player/player_knife_007.png"),
}
local knife_swing = {
  lg.newImage("assets/character/player/player_knife_swing_000.png"),
  lg.newImage("assets/character/player/player_knife_swing_001.png"),
  lg.newImage("assets/character/player/player_knife_swing_002.png"),
  lg.newImage("assets/character/player/player_knife_swing_003.png"),
}

local character = require("src.character")
local player = character.new()
player.x, player.y = 0,0
player.speed, player.size = 6, 0.3
player.frame, player.timer = 1,0
player.attackCooldown = 0
player.attack = "bat" -- "bat", "knife", "pistol"
player.frames = player.attack == "pistol" and pistol_frames or player.attack == "bat" and bat_frames or player.attack == "knife" and knife_frames or walk_frames

player.setWeapons = function(weapons)
  player.weapons = weapons
  -- for k, v in pairs(player.weapons) do
  --   print(k, v)
  --   if type(v) == "table" then
  --     for k, v in pairs(v) do
  --       print(">", k, v)
  --     end
  --   end
  -- end
  player.setWeaponIndex(1)
end

player.setWeaponIndex = function(index)
  if index < 1 then index = 1 end
  if index > 2 then index = 2 end
  player.weaponIndex = index
  player.attack = player.weapons[index].type
  player.frames = player.attack == "pistol" and pistol_frames or player.attack == "bat" and bat_frames or player.attack == "knife" and knife_frames or walk_frames
end

player.setZone = function(zone, x, y)
  player.zone = zone
  player.x, player.y = x or 0, y or 0
  player.hc = zone.hc
  player.shape = player.hc:circle(player.x, player.y, player.size)
  player.shape.user = "character"

  player.audioShape = player.hc:circle(player.x, player.y, 25)
  player.audioShape.user = "collider"
  player.audioShape.user2 = "playerListener"

  player.audioZombieGroanTimer = 0

  player.health = 5
end

player.hit = function(damage)
  player.health = player.health - damage
  logger.info("Player hit for", damage, "damage!", player.health, "left!")
  if player.health <= 0 then
    logger.warn("TODO Player death handle")
    player.health = 0
  end
  local x, y = player.shape:center()
  local r = player.shape:rotation()
  player.zone:addBlood(x, y, r, player.health == 0)
end

local Nx, Ny = 0, 0
local input = require("util.input")
local audioZombies = 0
player.update = function(dt, allowInput)

  player.audioZombieGroanTimer = player.audioZombieGroanTimer + dt
  if player.audioZombieGroanTimer >= 1/math.sqrt(math.max(audioZombies, 1)) then
    player.audioZombieGroanTimer = 0
    audioZombies = 0
    for other in pairs(player.hc:collisions(player.audioShape)) do
      if other.user == "character" and other.user2 == "zombie" then
        audioZombies = audioZombies + 1
      end
    end
    --local chance = 0.5 + math.log(audioZombies + 1) * 0.08
    local chance = 0.5
    if audioZombies <= 10 then
      chance =  chance + audioZombies * 0.02
    else
      chance = chance + math.exp((audioZombies-10) * 0.1) - 1
    end
    chance = math.max(math.min(chance, .9), 0)
    for _ = 1, math.min(math.floor(audioZombies/3), 5) do
      if love.math.random() >= chance then
        audioManager.play("zombie.groan")
      end
    end
  end

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

  local x, y = 0, 0
  if allowInput then
    x, y = input.baton:get("move")
  end
  player.shape:move(x * player.speed * dt, y * player.speed * dt)
  local moved = x ~= 0 or y ~= 0

  for other, vector in pairs(player.hc:collisions(player.shape)) do
    if other.user ~= "character" and other.user ~= "collider" or
      (other.user == "character" and other.user2 == "boss") then
      player.shape:move(vector.x, vector.y)
      moved = moved or (vector.x ~= 0 or vector.y ~= 0)
    end
  end
  player.audioShape:moveTo(player.shape:center())

  if player.state ~= "swing_bat" and player.state ~= "swing_knife" then
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
  if player.specialTexture == pistol_flash and player.attackCooldown <= player.weapons[player.weaponIndex].cooldown-0.1 then
    player.specialTexture = nil
  end

  -- if player.rect then
  --   local x, y = player.shape:center()
  --   player.rect:moveTo(x, y)
  --   player.rect:setRotation(player.shape:rotation(), x, y)
  --   player.rect:moveTo(x-nx*batSizeH, y+ny*batSizeH)
  -- end
  if allowInput then
    if player.attack == "bat" then
      if input.baton:pressed("attack") then
        if player.attackCooldown == 0 then
          audioManager.play("weapon.bat")
          player.attackCooldown = player.weapons[player.weaponIndex].cooldown
          player.state = "swing_bat"
          player.timer, player.frame = 0, 1

          local x, y = player.shape:center()
          player.zone:makeNoise(player.weapons[player.weaponIndex].noise, x, y)

          local rect = player.hc:rectangle(0, 0, batSizeH*2, batSizeW)
          rect.user = "collider"
          rect:moveTo(x, y)
          rect:setRotation(player.shape:rotation(), x, y)
          rect:moveTo(x-nx*batSizeH, y+ny*batSizeH)
          local hit = 0
          for shape in pairs(player.hc:collisions(rect)) do
            if shape.user == "character" and (shape.user2 == "zombie" or shape.user2 == "boss") and shape.user3.health ~= 0 then
              shape.user3:hit(player.weapons[player.weaponIndex].damage, player.zone)
              hit = hit + 1
            end
          end
          for _ = 1, math.min(hit, 2) do
            audioManager.play("zombie.hit.bat")
          end
          player.hc:remove(rect)
        end
      end
    elseif player.attack == "knife" then
      if input.baton:pressed("attack") then
        if player.attackCooldown == 0 then
          audioManager.play("weapon.knife")
          player.attackCooldown = player.weapons[player.weaponIndex].cooldown
          player.state = "swing_knife"
          player.timer, player.frame = 0, 1

          local x, y = player.shape:center()
          player.zone:makeNoise(player.weapons[player.weaponIndex].noise, x, y)

          local rect = player.hc:rectangle(0, 0, knifeSizeH*2, knifeSizeW)
          rect.user = "collider"
          rect:moveTo(x, y)
          rect:setRotation(player.shape:rotation(), x, y)
          rect:moveTo(x-nx*knifeSizeH, y+ny*knifeSizeH)
          local hit = 0
          for shape in pairs(player.hc:collisions(rect)) do
            if shape.user == "character" and (shape.user2 == "zombie" or shape.user2 == "boss") and shape.user3.health ~= 0 then
              shape.user3:hit(player.weapons[player.weaponIndex].damage, player.zone)
              hit = hit + 1
            end
          end
          for _ = 1, math.min(hit, 2) do
            audioManager.play("zombie.hit.knife")
          end
          player.hc:remove(rect)
        end
      end
    elseif player.attack == "pistol" then
      if input.baton:pressed("attack") then
        if player.attackCooldown == 0 then
          audioManager.play("weapon.pistol")
          player.attackCooldown = player.weapons[player.weaponIndex].cooldown
          player.specialTexture = pistol_flash

          local x, y = player.shape:center()
          player.zone:makeNoise(player.weapons[player.weaponIndex].noise, x, y)

          local bullet = player.hc:point(x, y)
          bullet:move(-nx*player.size, ny*player.size)
          local dist, step = 0, .05
          while dist <= 20 do
            for shape in pairs(player.hc:collisions(bullet)) do
              if shape.user == "character" and (shape.user2 == "zombie" or shape.user2 == "boss") and shape.user3.health ~= 0 then
                audioManager.play("zombie.hit.bullet")
                shape.user3:hit(player.weapons[player.weaponIndex].damage, player.zone)
                goto breakOut
              end
              if shape.user == "building" or shape.user == "egg" then
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
    while player.timer >= (0.15)/#bat_swing do
      player.timer = player.timer - 0.06
      player.frame = player.frame + 1
      if player.frame > #bat_swing then
        player.state = "idle"
        player.timer, player.frame = 0, 1
        break
      end
    end
  elseif player.state == "swing_knife" then
    player.timer = player.timer + dt
    while player.timer >= (0.15)/#knife_swing do
      player.timer = player.timer - 0.06
      player.frame = player.frame + 1
      if player.frame > #knife_swing then
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
  elseif player.state == "swing_knife" then
    plane:setTexture(knife_swing[player.frame])
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