local audioManager = require("util.audioManager")
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

  self.chargeCooldown = 2
  self.chargeDamage, self.chargeSpeed = 1.5, 25
  self.isCharging = false

  self.timer, self.frame = 0, 1
  self.cooldown, self.attackCooldown = 0, 0
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
  self.health = self.health - damage
  local x, y = self.body:center()
  local r = self.body:rotation()
  if self.health <= 0 then
    self.state = "dead"
    self.health = 0
    self.frame, self.timer = 1, 0
    self.x, self.y = x, y
    self.r = r
    zone.hc:remove(self.body)
    self.body = nil
    zone.hc:remove(self.pathShape)
    self.pathShape = nil
    zone:addBlood(x, y, r, self.health == 0)
    zone:addBlood(x, y, r, self.health == 0)
  end
  zone:addBlood(x, y, r, self.health == 0, 100, 100)
  zone:addBlood(x, y, r, self.health == 0, 100, 100)

  if self.health == 0 then
    audioManager.play("zombie.death")
  else
    audioManager.play("zombie.grunt")
  end
end

boss.move = function(self, dx, dy)
  self.body:move(dx, dy)
  self.pathShape:moveTo(self.body:center())
end

local feelerStrength = 2.3
local feelerPower = 1.05
boss.update = function(self, dt, hc, zone, player)
  if self.health ~= 0 then
    self.attackCooldown = self.attackCooldown - dt
    if self.attackCooldown <= 0 then
      self.attackCooldown = 0
    end

    if player and self.body:collidesWith(player.shape) and self.state == "attack_charge" and self.attackCooldown == 0 then
      player.hit(1.5)
      self.attackCooldown = 3
      print(self.state)
    end

    if self.targetX and self.targetY then
      self.lastAttack = self.lastAttack + dt

      local mx, my = 0, 0
      local distToTarget = 0

      if self.state == "charging" and self.attackCooldown == 0 then
        self.state = "attack_charge"
        self.timer, self.frame = 0, 1
        self.lastAttack = 0
      end

      local x, y = self.body:center()
      local dx, dy = self.targetX - x, self.targetY - y
      distToTarget = math.sqrt(dx^2+dy^2)
      
      mx, my = mx + dx, my + dy

      local fx, fy = 0, 0
      if distToTarget >= 2 and self.state ~= "attack_right" and self.state ~= "charging" and self.state ~= "attack_charge" then
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
      
      local mag = math.sqrt(mx^2+my^2)

      local targetRotation = math.atan2(-my, -mx)
      local currentRotation = self.body:rotation()

      local rotationSpeed = self.state == "charging" and self.rotationSpeed/8 or self.rotationSpeed

      local rotationDiff = math.atan2(math.sin(targetRotation - currentRotation), math.cos(targetRotation - currentRotation))
      local rotationChange = math.min(math.max(-rotationSpeed*dt, rotationDiff), rotationSpeed*dt)

      if self.state == "attack_charge" then
        if self.lastAttack >= 0.6 then
          self.state = "idle"
          self.timer, self.frame = 0, 1
          self.lastAttack = 0
        else
          local r = self.body:rotation()
          local dx, dy = -math.cos(r), -math.sin(r)
          self:move(dx*dt*self.chargeSpeed, dy*dt*self.chargeSpeed)
        end
      elseif self.state ~= "attack_right" and self.state ~= "charging" and self.state ~= "attack_charge" and self.attackCooldown == 0 and
         (self.lastAttack >= 10 or (distToTarget >= 5 and self.lastAttack >= 5)) then
        self.state = "charging"
        self.timer, self.frame = 0, 1
        self.lastAttack = 0
        self.attackCooldown = self.chargeCooldown
      elseif distToTarget <= 1.5 and self.state ~= "attack_right" and self.state ~= "charging" and self.state ~= "attack_charge" and math.abs(rotationDiff) <= math.rad(20) and self.lastAttack >= 0.4 then
        self.state = "attack_right"
        self.timer, self.frame = 0, 1
        self.lastAttack = 0
      elseif self.state ~= "attack_right" then
        self.body:rotate(rotationChange)
        if math.abs(rotationDiff) <= math.rad(20) and self.state ~= "charging" and self.state ~= "attack_charge" and distToTarget > 1.5 then
          self:move((mx/mag)*dt*self.speed, (my/mag)*dt*self.speed)
          self.state = "walk"
        end
      end
    end
  end

  if self.body then
    for other, vector in pairs(hc:collisions(self.body)) do
      if other.user == "building" or other.user == "egg" then
        self:move(vector.x, vector.y)
        if self.state == "attack_charge" then
          self.state = "idle"
          self.timer, self.frame = 0, 1
          self.lastAttack = 0
          self:hit(1, zone)
        end
      end
    end
  end

  if dt == 0 then return end

  local looped = false
  self.timer = self.timer + dt
  local animationSpeed = self.state == "attack_charge" and 0.02 or 0.1
  while self.timer >= animationSpeed do
    self.timer = self.timer - animationSpeed
    self.frame = self.frame + 1
    local n = self.state == "walk" and #frames_walk or self.state == "attack_right" and #frames_attack_right or #frames_walk
    if self.frame > n then
      self.frame = 1
      looped = true
    end
  end

  if looped and self.state == "attack_right" then
    self.state = "idle"
    self.frame = 1
    self.lastAttack = 0
    local px, py = player.shape:center()
    local zx, zy = self.body:center()
    local r = self.body:rotation()
    zx, zy = -math.cos(r) + zx, -math.sin(r) + zy
    if (px-zx)^2+(py-zy)^2 <= (1.5)^2 then
      player.hit(1)
    end
  end
end

boss.draw = function(self)
  local x, y = self.x, self.y
  local r = self.r
  if self.body then
    x, y = self.body:center()
    r = self.body:rotation()
  end

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