local g3d = require("libs.g3d")

local plane = g3d.newModel("assets/boss/boss.obj")

local lg = love.graphics
lg.setDefaultFilter("nearest", "nearest")

local frames_walk = {
  lg.newImage("assets/boss/fat/boss_fat_walk_000.png"),
  lg.newImage("assets/boss/fat/boss_fat_walk_001.png"),
  lg.newImage("assets/boss/fat/boss_fat_walk_002.png"),
  lg.newImage("assets/boss/fat/boss_fat_walk_003.png"),
}

local frames_attack_right = {
  lg.newImage("assets/boss/fat/boss_fat_attack_right_000.png"),
  lg.newImage("assets/boss/fat/boss_fat_attack_right_001.png"),
  lg.newImage("assets/boss/fat/boss_fat_attack_right_002.png"),
  lg.newImage("assets/boss/fat/boss_fat_attack_right_003.png"),
  lg.newImage("assets/boss/fat/boss_fat_attack_right_004.png"),
  lg.newImage("assets/boss/fat/boss_fat_attack_right_005.png"),
}

local character = require("src.character")
local boss = character.new()

boss.clone = function(hc, x, y)
  local self = character.new()
  self.health = 30
  self.speed, self.rotationSpeed = 5.5, math.rad(220)
  self.state = "idle"

  self.chargeCooldown, self.chargeTime = 10, 1.5
  self.chargeDamage = 1.5
  self.isCharging = false

  self.timer, self.frame = 0, 1
  self.cooldown = 0
  self.lastAttack = 0

  self.body = hc:circle(x, y, .4)
  self.body:setRotation(math.rad(90))
  self.body.user = "character"
  self.body.user2 = "boss"
  self.body.user3 = self

  self.pathShape = hc:circle(x, y, 2.2)
  self.pathShape.user = "collider"

  self.clone = boss.clone
  self.hit = boss.hit
  self.move = boss.move
  self.update = boss.update
  self.draw = boss.draw

  return self
end

boss.hit = function(self, damage, zone)

end

boss.move = function(self, dx, dy)
  self.body:move(dx, dy)
  self.pathShape:moveTo(self.body:center())
end

local feelerStrength = 2.3
local feelerPower = 1.05
boss.update = function(self, dt, hc)
  if self.health ~= 0 then
    if self.targetX and self.targetY then
      self.lastAttack = self.lastAttack + dt

      local mx, my = 0, 0
      local distToTarget = 0

      if self.state ~= "attack_right" and self.state ~= "charge" then
        local x, y = self.body:center()
        local dx, dy = self.targetX - x, self.targetY - y
        distToTarget = math.sqrt(dx^2+dy^2)
        
        mx, my = mx + dx, my + dy

        local fx, fy = 0, 0
        if distToTarget >= 2 then
          for other, vector in pairs(hc:collisions(self.pathShape)) do
            if other.user == "building" or other.user == "egg" then
              local distToVec = math.sqrt(vector.x^2+vector.y^2)
              local scaledForce = (feelerStrength * 1-math.min(distToTarget,1)) * distToVec^feelerPower
              fx = fx + (vector.x * scaledForce)
              fy = fy + (vector.y * scaledForce)
            end
          end
        end

        mx, my = mx + fx, my + fy
      end
      
      local mag = math.sqrt(mx^2+my^2)

      local targetRotation = math.atan2(-my, -mx)
      local currentRotation = self.body:rotation()

      local rotationDiff = math.atan2(math.sin(targetRotation - currentRotation), math.cos(targetRotation - currentRotation))
      local rotationChange = math.min(math.max(-self.rotationSpeed*dt, rotationDiff), self.rotationSpeed*dt)

      if distToTarget <= 1.5 and self.state ~= "attack_right" and math.abs(rotationDiff) <= math.rad(20) then
        self.state = "attack_right"
        self.timer, self.frame = 0, 1
        self.lastAttack = 0
      elseif self.state ~= "attack_right" then
        self.body:rotate(rotationChange)
        if math.abs(rotationDiff) <= math.rad(20) then
          self:move((mx/mag)*dt*self.speed, (my/mag)*dt*self.speed)
          self.state = "walk"
        end
      end
    end
  end

  for other, vector in pairs(hc:collisions(self.body)) do
    if other.user == "building" or other.user == "egg" then
      self:move(vector.x, vector.y)
    end
  end

  if dt == 0 then return end

  local looped = false
  self.timer = self.timer + dt
  while self.timer >= 0.1 do
    self.timer = self.timer - 0.1
    self.frame = self.frame + 1
    local n = self.state == "walk" and #frames_walk or self.state == "attack_right" and #frames_attack_right or 1
    if self.frame > n then
      self.frame = 1
      looped = true
    end
  end

  if looped and self.state == "attack_right" then
    self.state = "idle"
    self.frame = 1
  end
end

boss.draw = function(self)
  local x, y = self.body:center()
  local r = self.body:rotation()

  plane:setTranslation(x, y, 0.11)
  plane:setRotation(0,0, r-math.rad(90))

  if self.state == "attack_right" then
    plane:setTexture(frames_attack_right[self.frame])
  else
    plane:setTexture(frames_walk[self.frame])
  end

  plane:draw()
end

return boss