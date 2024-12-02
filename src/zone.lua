local logger = require("util.logger")

local zone = {
  types = { }
}
zone.__index = zone

zone.registerCell = function(type, cell)
  local type = zone.getType(type)
  table.insert(type.cells, cell)
end

zone.registerBossCell = function(type, cell)
  local type = zone.getType(type)
  table.insert(type.bossCells, cell)
end

zone.registerRoad = function(type, road)
  local type = zone.getType(type)
  type.road = road
end

zone.getType = function(type)
  local tbl = zone.types[type] or {
      cells = { },
      bossCells = { },
      road = nil,
    }
  if not zone.types[type] then
    logger.info("Created new zone type:", type)
  end
  zone.types[type] = tbl
  return tbl
end

zone.getRandomCell = function(type)
  local type = zone.getType(type)
  if #type.cells == 0 then
    logger.error("Called getRandomCell for", type, "but no cells exist within type to give")
    return nil
  end
  return type.cells[love.math.random(1, #type.cells)]
end

zone.getRandomBossCell = function(type)
  local type = zone.getType(type)
  if #type.bossCells == 0 then
    logger.error("Called getRandomBossCell for", type, "but no boss cells exist within type to give")
    return nil
  end
  return type.bossCells[love.math.random(1, #type.bossCells)]
end

zone.getZone = function(type)
  width, height = 3, 3 -- update cell.x/y math if you want to customise these future me
                        -- right now, it just maps 1:-95, 2:0, 3:95 - it doesn't care about road width

  local cells = { }
  local centreX, centreY = math.ceil(width / 2), math.ceil(height / 2)
  for y = 1, height do
  for x = 1, width do
    local cell 
    if centreY == y and centreX == x then
      cell = zone.getRandomBossCell(type)
    else
      cell = zone.getRandomCell(type)
    end
    cell = cell:clone()
    cell.x = (x - 2) * 95
    cell.y = (y - 2) * 95
    table.insert(cells, cell)
  end
  end

  local newZone = zone.new(cells, width, height)
  return newZone
end

zone.new = function(cells, width, height)
  local self = setmetatable({
    width = width, height = height,
    cells = cells,
    hc = require("libs.HC").new(),
  }, zone)

  for _, cell in ipairs(cells) do
    cell:createCollider(self.hc)
  end

  return self
end

zone.update = function(self, dt)
  for _, cell in ipairs(self.cells) do
    cell:update(dt)
  end
end

zone.draw = function(self)
  for _, cell in ipairs(self.cells) do
    cell:draw()
  end
end

return zone