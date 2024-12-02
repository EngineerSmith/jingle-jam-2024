local cell = require("src.cell")
local g3d = require("libs.g3d")

local model = g3d.newModel("assets/cells/park/model.obj", "assets/cells/park/texture.png")
local plane = g3d.newModel("assets/cells/plane.obj", "assets/cells/park/plane.png")

local park = cell.new()

park.createCollider = function(self, hc)
  
end

park.draw = function(self)
  plane:setTranslation(self.x, self.y, 0)
  plane:draw()
  model:setTranslation(self.x, self.y, 0)
  model:draw()
end

require("src.zone").registerBossCell("city", park)