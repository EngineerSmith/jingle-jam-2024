local g3d = require("libs.g3d")

local plane = g3d.newModel("assets/character/character.obj")

local lg = love.graphics

local walk_frames = {
  lg.newImage("assets/character/zombie/zombie_000.png"),
  lg.newImage("assets/character/zombie/zombie_001.png"),
  lg.newImage("assets/character/zombie/zombie_002.png"),
  lg.newImage("assets/character/zombie/zombie_003.png"),
  lg.newImage("assets/character/zombie/zombie_004.png"),
  lg.newImage("assets/character/zombie/zombie_005.png"),
  lg.newImage("assets/character/zombie/zombie_006.png"),
  lg.newImage("assets/character/zombie/zombie_007.png"),
}
local idle = walk_frames[1] --lg.newImage("assets/black_tile.png")--

local character = require("src.character")
local zombie = character.new()

zombie.clone = function(hc, x, y)
  local self = character.new()
  self.state = "idle"
  self.speed = love.math.random(45, 55)/10
  self.timer = 0
  self.frame = 1
  self.shape = hc:circle(x+.5, y+.5, .3)
  self.shape.user = "character"
  self.shape.user2 = "zombie"
  self.clone = zombie.clone
  self.update = zombie.update
  self.draw = zombie.draw
  self.targetX, self.targetY = nil, nil

  self:update(0, hc)
  return self
end

zombie.update = function(self, dt, hc)
  if self.targetX and self.targetY then
    local x, y = self.shape:center()
    local dx, dy = self.targetX - x, self.targetY - y
    local mag = math.sqrt(dx^2 + dy^2)
    if mag >= 1 then
      self.shape:move((dx/mag)*dt*self.speed, (dy/mag)*dt*self.speed)
      self.shape:setRotation(math.atan2(-dy, -dx))
      self.state = "walk"
    else
      self.targetX, self.targetY = nil, nil
      self.state = "idle"
    end
  end

  for other, vector in pairs(hc:collisions(self.shape)) do
    if other.user ~= "character" then
      self.shape:move(vector.x, vector.y)
    elseif other.user2 == "zombie" then
      self.shape:move(vector.x/8, vector.y/8)
    end
  end

  if dt == 0 then return end

  if self.state == "idle" then
    self.frame = 1
    self.timer = 0
  elseif self.state == "walk" then
    self.timer = self.timer + dt
    while self.timer >= 0.1 do
      self.timer = self.timer - 0.1
      self.frame = self.frame + 1
      if self.frame > #walk_frames then
        self.frame = 1
      end
    end
  end
end

zombie.draw = function(self)
  local x, y = self.shape:center()
  plane:setTranslation(x, y, 0.05)
  plane:setRotation(0, 0, self.shape:rotation()-math.rad(90))
  if self.state == "idle" then
    plane:setTexture(idle)
  elseif self.state == "walk" then
    plane:setTexture(walk_frames[self.frame])
  end
  plane:draw()
end

return zombie