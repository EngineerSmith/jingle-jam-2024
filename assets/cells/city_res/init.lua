local cell = require("src.cell")
local g3d = require("libs.g3d")

local modelFile = "assets/cells/city_res/model.obj"

local model = g3d.newModel(modelFile, "assets/cells/city_res/texture.png")
local plane = g3d.newModel("assets/cells/plane.obj", "assets/cells/city_res/plane.png")

local city = cell.new()

local createRectCollider = function(hc, rect, offsetX, offsetY)
  local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
  for i = 1, 7, 2 do
    minX = math.min(minX, rect[i])
    maxX = math.max(maxX, rect[i])
    minY = math.min(minY, rect[i+1])
    maxY = math.max(maxY, rect[i+1])
  end

  local x, y = minX + offsetX, minY + offsetY
  local width, height = maxX - minX, maxY - minY
  local shape = hc:rectangle(x, y, width, height)
  shape.user = "building"
  shape.user2 = table.concat(rect, ", ")
end

local tolerance = 0.01
city.createCollider = function(self, hc)
  local offsetX, offsetY = self.x, self.y

  local rect
  for line in love.filesystem.lines(modelFile) do
    local words = {}
    for word in line:gmatch("([^%s]+)") do
      table.insert(words, word)
    end
    if words[1] == "o" then
      if rect then
      if #rect ~= 4*2 then
        logger.warn("Collider tried to make collider for non-rectangle")
      else
        createRectCollider(hc, rect, offsetX, offsetY)
      end
      end
      rect = { }
    elseif words[1] == "v" then
      local z = tonumber(words[4])
      if math.abs(z) < tolerance then
        table.insert(rect, tonumber(words[2]))
        table.insert(rect, tonumber(words[3]))
      end
    end
  end
  if rect and #rect == 4*2 then
    createRectCollider(hc, rect, offsetX, offsetY)
  end
end

city.draw = function(self)
  plane:setTranslation(self.x, self.y, 0)
  plane:draw()
  model:setTranslation(self.x, self.y, 0)
  model:draw()
end

require("src.zone").registerCell("city", city)