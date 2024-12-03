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
  self.state = "walk"
  self.speed = 5
  self.timer = 0
  self.frame = 1
  self.shape = hc:circle(x+.5, y+.5, .3)
  self.shape.user = "character"
  self.clone = zombie.clone
  self.update = zombie.update
  self.draw = zombie.draw
  self.targetX, self.targetY = nil, nil
  return self
end

zombie.update = function(self, dt, hc)
    for other, vector in pairs(hc:collisions(self.shape)) do
      if other.user ~= "character" then
        self.shape:move(vector.x, vector.y)
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
  plane:setTranslation(x, y, 0.05)
  if self.state == "idle" then
    plane:setTexture(idle)
  elseif self.state == "walk" then
    plane:setTexture(walk_frames[self.frame])
  end
  plane:draw()
end

return zombie