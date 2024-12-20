local audioManager = require("util.audioManager")
local g3d = require("libs.g3d")

local plane = g3d.newModel("assets/character/character.obj")
local deadPlane = g3d.newModel("assets/character/death.obj")

local lg = love.graphics

local frames_1 = {
  lg.newImage("assets/character/zombie/zombie_000.png"),
  lg.newImage("assets/character/zombie/zombie_001.png"),
  lg.newImage("assets/character/zombie/zombie_002.png"),
  lg.newImage("assets/character/zombie/zombie_003.png"),
  lg.newImage("assets/character/zombie/zombie_004.png"),
  lg.newImage("assets/character/zombie/zombie_005.png"),
  lg.newImage("assets/character/zombie/zombie_006.png"),
  lg.newImage("assets/character/zombie/zombie_007.png"),
}
local death_1 = {
  lg.newImage("assets/character/zombie/zombie_death_000.png"),
  lg.newImage("assets/character/zombie/zombie_death_001.png"),
}

local frames_2 = {
  lg.newImage("assets/character/zombie/zombie1_000.png"),
  lg.newImage("assets/character/zombie/zombie1_001.png"),
  lg.newImage("assets/character/zombie/zombie1_002.png"),
  lg.newImage("assets/character/zombie/zombie1_003.png"),
  lg.newImage("assets/character/zombie/zombie1_004.png"),
  lg.newImage("assets/character/zombie/zombie1_005.png"),
  lg.newImage("assets/character/zombie/zombie1_006.png"),
  lg.newImage("assets/character/zombie/zombie1_007.png"),
}
local death_2 = {
  lg.newImage("assets/character/zombie/zombie1_death_000.png"),
  lg.newImage("assets/character/zombie/zombie1_death_001.png"),
}

local frames_3 = {
  lg.newImage("assets/character/zombie/zombie2_000.png"),
  lg.newImage("assets/character/zombie/zombie2_001.png"),
  lg.newImage("assets/character/zombie/zombie2_002.png"),
  lg.newImage("assets/character/zombie/zombie2_003.png"),
  lg.newImage("assets/character/zombie/zombie2_004.png"),
  lg.newImage("assets/character/zombie/zombie2_005.png"),
  lg.newImage("assets/character/zombie/zombie2_006.png"),
  lg.newImage("assets/character/zombie/zombie2_007.png"),
}
local death_3 = {
  lg.newImage("assets/character/zombie/zombie2_death_000.png"),
  lg.newImage("assets/character/zombie/zombie2_death_001.png"),
}

local character = require("src.character")
local zombie = character.new()

zombie.clone = function(hc, x, y)
  local self = character.new()
  self.state = "idle"

  self.speed = love.math.random(45, 60)/10
  self.health = 3

  self.timer, self.frame = 0, 1
  self.idleTimer, self.idleTimerTarget = 0, love.math.random(200, 500)/100
  self.attackTimer = 0

  self.shape = hc:circle(x+.5, y+.5, .3)
  self.shape.user = "character"
  self.shape.user2 = "zombie"
  self.shape.user3 = self
  self.pathShape = hc:circle(x+.5, y+.5, 2)
  self.pathShape.user = "collider"

  self.clone = zombie.clone
  self.hit = zombie.hit
  self.update = zombie.update
  self.draw = zombie.draw
  self.targetX, self.targetY = nil, nil

  local r = love.math.random(1, 3)
  self.frames = r == 1 and frames_1 or r == 2 and frames_2 or r == 3 and frames_3 or frames_1
  self.deathFrames = r == 1 and death_1 or r == 2 and death_2 or r == 3 and death_3 or death_1

  self:update(0, hc)
  return self
end

zombie.hit = function(self, damage, zone)
  if self.health == 0 then
    return
  end

  local x, y = self.shape:center()
  local r = self.shape:rotation()

  self.health = self.health - damage
  if self.health <= 0 then
    self.health = 0
    self.frame, self.timer = 1, 0
    self.x, self.y = x, y
    self.r = r
    zone.hc:remove(self.shape)
    self.shape = nil
    zone.hc:remove(self.pathShape)
    self.pathShape = nil
  end
  zone:addBlood(x, y, r-math.rad(270), self.health == 0)

  if self.health == 0 then
    audioManager.play("zombie.death")
  else
    audioManager.play("zombie.grunt")
  end
end

local feelerStrength = 2.3
local feelerPower = 1.05
zombie.update = function(self, dt, hc, player)
  if self.health ~= 0 then
    if player and self.pathShape:collidesWith(player.shape) then
      local px, py = player.shape:center()
      local zx, zy = self.shape:center()
      local dist2 = (px - zx)^2+(py - zy)^2
      if dist2 <= 0.4^2 then
        self.attackTimer = self.attackTimer + dt
        if self.attackTimer >= 0.3 then
          self.attackTimer = 0
          player.hit(0.5, "zombie")
        end
      else
        self.attackTimer = 0
      end
    else
      self.attackTimer = 0
    end
    if self.targetX and self.targetY then
      local mx, my = 0, 0

      local x, y = self.shape:center()
      local dx, dy = self.targetX - x, self.targetY - y
      local distToTarget = math.sqrt(dx^2 + dy^2)

      if distToTarget >= .3 then
        mx, my = mx + dx, my + dy

        -- feelers
        local fx, fy = 0, 0
        if distToTarget >= 1.5 and distToTarget <= 70 then
          for other, vector in pairs(hc:collisions(self.pathShape)) do
            if other.user == "building" or other.user == "egg" then
              local distToVec = math.sqrt(vector.x^2+vector.y^2)
              if distToVec > .2 then
                local scaledForce = (feelerStrength * 1-math.min(distToTarget,1)) * distToVec^feelerPower
                fx = fx + (vector.x * scaledForce)
                fy = fy + (vector.y * scaledForce)
              end
            end
          end
        end

        mx, my = mx + fx, my + fy
      end
      
      local mag = math.sqrt(mx^2 + my^2)
      if mag >= .3 then
        self.shape:move((mx/mag)*dt*self.speed, (my/mag)*dt*self.speed)
        self.shape:setRotation(math.atan2(-my, -mx))
        self.state = "walk"
      else
        self.targetX, self.targetY = nil, nil
        self.state = "idle"
      end
    end

    for other, vector in pairs(hc:collisions(self.shape)) do
      if other.user ~= "character" and other.user ~= "collider" then
        self.shape:move(vector.x, vector.y)
      elseif other.user2 == "zombie" then
        self.shape:move(vector.x/5, vector.y/5)
      end
    end

    self.pathShape:moveTo(self.shape:center())
  end
  if dt == 0 then return end

  if self.health == 0 then
    self.timer = self.timer + dt
    if self.timer >= 0.2 then
      self.timer = 0.2
      self.frame = 2
    end
  elseif self.state == "idle" then
    self.frame, self.timer = 1, 0

    self.idleTimer = self.idleTimer + dt
    if self.idleTimer >= self.idleTimerTarget then
      self.idleTimer, self.idleTimerTarget = 0, love.math.random(20, 60)/10
      local zx, zy = self.shape:center()
      for _ = 1, 5 do -- try X times to find wander point
        local rx, ry = love.math.random(-30,30)/10, love.math.random(-300,300)/100
        local hit = false
        for shape in pairs(hc:shapesAt(zx+rx, zy+ry)) do
          if shape.user == "building" or shape.user == "egg" then
            hit = true
            break
          end
        end
        if not hit then
          self.targetX, self.targetY = zx + rx, zy + ry
          self.reason = "wander"
          break
        end
      end
    end
  elseif self.state == "walk" then
    self.idleTimer, self.idleTimerTarget = 0, love.math.random(20, 60)/10

    self.timer = self.timer + dt
    while self.timer >= 0.1 do
      self.timer = self.timer - 0.1
      self.frame = self.frame + 1
      if self.frame > #self.frames then
        self.frame = 1
      end
    end
  end
end

zombie.draw = function(self)
  local x, y, r = self.x, self.y, self.r
  if self.shape then
    x, y = self.shape:center()
    r = self.shape:rotation()
  end

  local plane = self.health ~= 0 and plane or deadPlane
  plane:setTranslation(x, y, 0.05)
  
  plane:setRotation(0, 0, r-math.rad(90))
  if self.health == 0 then
    plane:setTranslation(x, y, 0.03)
    plane:setTexture(self.deathFrames[self.frame])
  elseif self.state == "idle" then
    plane:setTexture(self.frames[1])
  elseif self.state == "walk" then
    plane:setTexture(self.frames[self.frame])
  end
  plane:draw()
end

return zombie