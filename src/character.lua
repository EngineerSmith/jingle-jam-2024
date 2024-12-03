local character = { }
character.__index = character

character.new = function()
  local self = setmetatable({ }, character)
  return self
end

character.clone = function()
  return character.new()
end

character.update = function(self, dt)

end

character.draw = function(self)

end

return character