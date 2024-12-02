local cell = {
  width = 60,
  height = 60,
}
cell.__index = cell

cell.new = function()
  return setmetatable({
    x = 0, y = 0,
  }, cell)
end

cell.clone = function(self)
  local newCell = cell.new()
  newCell.update = self.update
  newCell.draw = self.draw
  return newCell
end

cell.createCollider = function(self, hc)
  -- implemented by cell
end

cell.update = function(self, dt)
  -- implemented by cell
end

cell.draw = function(self)
  -- implemented by cell
end

return cell