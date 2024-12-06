local flux = require("libs.flux")
local g3d = require("libs.g3d")

local egg = g3d.newModel("assets/boss/egg.obj", "assets/boss/egg.png")
local eggShader = love.graphics.newShader("assets/boss/egg.glsl")

local cell = {
  width = 60,
  height = 60,
}
cell.__index = cell

cell.new = function()
  return setmetatable({
    x = 0, y = 0,
    eggTimer = love.math.random(0, 10000)/1000,
    eggRed = .8,
  }, cell)
end

cell.clone = function(self)
  local newCell = cell.new()
  newCell.createCollider = self.createCollider
  newCell.update = self.update
  newCell.spawnBoss = self.spawnBoss
  newCell.draw = self.draw
  return newCell
end

cell.createCollider = function(self, hc)
  -- implemented by cell
end

cell.update = function(self, dt)
  -- implemented by cell
end

cell.updateEgg = function(self, dt, hc)
  self.eggTimer = self.eggTimer + dt
  eggShader:send("time", self.eggTimer/2)
  -- if egg activated
  -- self:spawnBoss(hc)
end

cell.spawnBoss = function(self, hc)
  -- implemented by cell
end

cell.draw = function(self)
  -- implemented by cell
end

cell.createEggCollider = function(self, hc)
  self.eggCollider = hc:circle(0, 0, 0.4)
  self.eggCollider.user = "egg"

  local key1, key2
  key1 = function()
    flux.to(self, 0.3, { eggRed = 0.8 }):oncomplete(key2)
  end
  key2 = function()
    flux.to(self, 0.3, { eggRed = 0.85 }):oncomplete(key1)
  end
  key1()
end

cell.drawEgg = function(self)
  egg:setScale(0.5)
  egg:setTranslation(self.x, self.y, 0)
  love.graphics.setColor(self.eggRed, 1, 1, 1)
  egg:draw(eggShader)
  love.graphics.setColor(1, 1, 1, 1)
end

return cell