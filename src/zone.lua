local logger = require("util.logger")
local zombie_base = require("assets.character.zombie")

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

local spawnArea = {
  [1] = -140,
  [2] = - 45,
  [3] =   50,
}
-- local randomRotation = {
--   [1] = 0,
--   [2] = 90,
--   [3] = 180,
--   [4] = 270,
-- }
zone.getZone = function(type)
  width, height = 3, 3 -- update cell.x/y math if you want to customise these future me
                        -- right now, it just maps 1:-95, 2:0, 3:95 - it doesn't care about road width
                        -- + zombie spawn area

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
    cell.boss = centreY == y and centreX == x
    cell.x = (x - 2) * 95
    cell.y = (y - 2) * 95
    cell.spawnX = spawnArea[x]
    cell.spawnY = spawnArea[y]
    cell.spawnW = 90
    cell.spawnH = 90
    --cell.rotation = randomRotation[love.math.random(1, 4)] -- textures for cells are fixed because shadows
    table.insert(cells, cell)
  end
  end

  local zombies = { }
  local newZone = zone.new(cells, zombies, width, height)

  for _, cell in ipairs(cells) do
    local minX, maxX = cell.spawnX, cell.spawnX+ cell.spawnW
    local minY, maxY = cell.spawnY, cell.spawnY + cell.spawnH
    if not cell.boss then
      for _ = 1, love.math.random(15, 20) do
        for _ = 1, 5 do -- try X times to find a spawn point, per zombie
          local rx, ry = love.math.random(minX, maxX), love.math.random(minY, maxY)
          local hit = false
          for shape in pairs(newZone.hc:shapesAt(rx, ry)) do
            if shape.user == "building" then
              hit = true
              break
            end
          end
          if not hit then
            for _ = 1, love.math.random(3,6) do
              local zx, zy = love.math.random(-3, 3)+rx, love.math.random(-3, 3)+ry
              local hit = false
              for shape in pairs(newZone.hc:shapesAt(rx, ry)) do
                if shape.user == "building" then
                  hit = true
                  break
                end
              end
              if not hit then
                table.insert(zombies, zombie_base.clone(newZone.hc, zx, zy))
                break
              end
            end
          end
        end
      end
    end
  end
  logger.info("Spawned", #zombies, "zombies")
  return newZone
end

zone.new = function(cells, zombies, width, height)
  local self = setmetatable({
    cells = cells,
    zombies = zombies,
    hc = require("libs.HC").new(2),
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
  for _, z in ipairs(self.zombies) do
    z:update(dt, self.hc)
  end
end

zone.draw = function(self)
  for _, cell in ipairs(self.cells) do
    cell:draw()
  end
  for _, z in ipairs(self.zombies) do
    z:draw()
  end
end

return zone