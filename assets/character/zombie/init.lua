local character = require("src.character")
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

local zombie = character.new()

zombie.clone = function(hc, x, y)
  local self = character.new()
  self.state = "walk"
  self.speed = 8
  self.timer = 0
  self.frame = 1
  self.shape = hc:circle(x+.5, y+.5, .3)
  self.clone = zombie.clone
  self.update = zombie.update
  self.draw = zombie.draw
  self.targetX, self.targetY = 0, 0
  return self
end

local hit = false
zombie.update = function(self, dt, hc)
  if not hit then
    --self.shape:move(-3 * dt, 0 * dt)
    for other, vector in pairs(hc:collisions(self.shape)) do
      self.shape:move(vector.x, vector.y)
      print("hit shape", other.user or "unknown", ":", other.user2 or "")
      --hit = true
    end
  end

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
  plane:setTranslation(x, y, 0.1)
  if self.state == "idle" then
    plane:setTexture(idle)
  elseif self.state == "walk" then
    plane:setTexture(walk_frames[self.frame])
  end
  plane:draw()
end

return zombie