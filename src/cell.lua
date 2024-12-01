local cell = { }
cell.__index = cell

cell.new = function()
  return setmetatable({ }, cell)
end

cell.draw = function()

end

return cell