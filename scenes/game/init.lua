local lg = love.graphics

local audioManager = require("util.audioManager")
audioManager.setVolumeAll()

local g3d = require("libs.g3d")
local cam = g3d.camera:current()
cam.fov = math.rad(50)
cam:updateProjectionMatrix()

local assetManager = require("util.assetManager")
local settings = require("util.settings")
local cursor = require("util.cursor")
local input = require("util.input")
local lang = require("util.lang")
local ui = require("util.ui")

do
 require("assets.cells.park")
 require("assets.cells.city_res")
end
local road = require("src.road")

local scene = {
  posX = 0, posY = 0,
  state = "menu", -- game
  zone = nil,
  player = require("assets.character.player"),
}

local weaponSets = {
  ["left"] = {
    {
      type = "pistol",
      asset = "ui.weapon.pistol.silver",
      cooldown = 0.8,
      damage = 4.0,
      noise = 60.0,
    },
    {
      type = "bat",
      asset = "ui.weapon.bat",
      cooldown = 0.8,
      damage = 1.5,
      noise = 10.0,
    }
  },
  ["right"] = {
    {
      type = "pistol",
      asset = "ui.weapon.pistol.gold",
      cooldown = 0.4,
      damage = 3.0,
      noise = 50.0,
    },
    {
      type = "knife",
      asset = "ui.weapon.knife",
      cooldown = 0.8,
      damage = 3.0,
      noise = 3,
    }
  }
}

local updateCamera = function()
  g3d.camera.current():lookAt(scene.posX, scene.posY, 25, scene.posX, scene.posY-0.000001, 0)
end

scene.load = function()
  scene.zone = require("src.zone").getZone("city")
  road.createColliders("city", scene.zone.hc)
  scene.zone:forceBossSpawn()

  scene.player.setZone(scene.zone, 0, -5)

  updateCamera()
end

scene.resize = function(w, h)
  -- Update settings
  settings.client.resize(w, h)

-- scale scene
  local wsize = settings._default.client.windowSize
  local tw, th = wsize.width, wsize.height
  local sw, sh = w / tw, h / th
  scene.scale = sw < sh and sw or sh

-- scale Text
  local font = ui.getFont(18, "fonts.regular.bold", scene.scale)
  lg.setFont(font)

-- scale Cursor
  cursor.setScale(scene.scale)

-- scale World
  local cam = g3d.camera:current()
  cam.aspectRatio = (w/h)
  cam:updateProjectionMatrix()
end

local menuHighlight = "none"

local waitTimer = 0
scene.update = function(dt)
  love.mouse.setRelativeMode(false)
  love.mouse.setVisible(true)

  if scene.state == "menu" then
    waitTimer = waitTimer + dt
    local ww = love.graphics.getWidth()
    local x = love.mouse.getX()
    if x >= 0 and x <= ww/2 then
      menuHighlight = "left"
    elseif x >= ww/2 and x <= ww then
      menuHighlight = "right"
    else
      menuHighlight = "none"
    end
    if waitTimer >= .5 and input.baton:pressed("attack") then
      local ws = weaponSets[menuHighlight]
      if ws then
        scene.player.setWeapons(ws)
        scene.state = "game"
        return
      end
    end
  elseif scene.state == "game" and scene.zone and scene.player then
    local tx, ty = scene.player.shape:center()

    -- can zombie see player
    for i = 1, #scene.zone.zombies do
      local z = scene.zone.zombies[i]
      if z.health > 0 then
        local zx, zy = z.shape:center()
        if (tx - zx)^2 + (ty - zy)^2 <= (8)^2 then
          z.targetX, z.targetY = tx, ty
          --zombie.reason = "vision"
        end
      end
    end

    -- boss can ALWAYS see player
    if scene.zone.boss then
      scene.zone.boss.targetX, scene.zone.boss.targetY = tx, ty
    end

    scene.zone:update(dt, scene.player)
  end
  if scene.player then
    scene.player.update(dt, scene.state == "game")
    scene.posX, scene.posY = scene.player.shape:center()
    updateCamera()
  end
end

scene.draw = function()
  lg.clear()
  -- WORLD
  lg.origin()
  if scene.zone then
    road.draw("city")
    scene.zone:draw()
  end
  if scene.player then
    scene.player.draw()
  end
  -- UI
  lg.setDepthMode("always", true)
  lg.push("all")
  lg.origin()
  if scene.state == "menu" then
    local wsize = settings._default.client.windowSize
    local tw, th = wsize.width, wsize.height
    local widthOffset = lg.getWidth()-(tw*scene.scale)
    local heightOffset = lg.getHeight()-(th*scene.scale)
    lg.push("all")
    lg.translate(widthOffset/2, heightOffset/2)
    lg.setColor(0,0,0,0.8)
    -- Left
    lg.push("all")
    local padding = 20 * scene.scale
    local rectangleWidth, rectangleHeight = (tw/2)*scene.scale-padding*2, th*scene.scale-padding*2
    lg.rectangle("fill", padding, padding, rectangleWidth, rectangleHeight, 10)
    if menuHighlight == "left" then
      lg.push("all")
      lg.setColor(1,1,0.5,1)
      lg.rectangle("line", padding, padding, rectangleWidth, rectangleHeight, 10)
      lg.pop()
    end
    lg.push("all")
    lg.translate(padding*2, padding*2)
    local a = menuHighlight == "left" and 0.7 or 0.3
    lg.setColor(1,1,1,a)
    lg.rectangle("fill", 0,0,rectangleWidth-padding*2, rectangleHeight-padding*2, 5)
    lg.setColor(1,1,1,1)
    -- weapon set 1
    local innerRectangleWidth = rectangleWidth-padding*2
    lg.translate(innerRectangleWidth/2, padding)
    local weaponSet = weaponSets["left"]
    local w1, w2 = assetManager[weaponSet[1].asset], assetManager[weaponSet[2].asset]
    local scale = scene.scale * 4
    if w1 then
      lg.draw(w1, -8*scale, scale, 0, scale)
    end
    if w2 then
      lg.draw(w2, -8*scale, 16*scale+padding*2, 0, scale)
    end
    lg.translate(-innerRectangleWidth/2, (16*scale)*2+padding*4)
    lg.setColor(0,0,0,1)
    local text = lang.getText("game.weaponset.left.title")
    local font = ui.getFont(17, "fonts.regular.bold", scene.scale)
    local _, wrappedText = font:getWrap(text, innerRectangleWidth)
    lg.printf(text, font, 0, 0, innerRectangleWidth, "center")
    lg.translate(padding, #wrappedText*(font:getHeight()))
    local font = ui.getFont(16, "fonts.regular.bold", scene.scale)
    lg.printf(lang.getText("game.weaponset.left.text"), font, 0, 0, innerRectangleWidth, "left")
    lg.pop()
    lg.pop()
-- Right
    lg.push("all")
    lg.rectangle("fill", (tw/2)*scene.scale+padding, padding, rectangleWidth, rectangleHeight, 10)
    if menuHighlight == "right" then
      lg.push("all")
      lg.setColor(1,1,0.5,1)
      lg.rectangle("line", (tw/2)*scene.scale+padding, padding, rectangleWidth, rectangleHeight, 10)
      lg.pop()
    end
    lg.push("all")
    lg.translate((tw/2)*scene.scale+padding*2, padding*2)
    local a = menuHighlight == "right" and 0.7 or 0.3
    lg.setColor(1,1,1,a)
    lg.rectangle("fill", 0,0,rectangleWidth-padding*2, rectangleHeight-padding*2, 5)
    lg.setColor(1,1,1,1)
    -- weapon set 2
    local innerRectangleWidth = rectangleWidth-padding*2
    lg.translate(innerRectangleWidth/2, padding)
    local weaponSet = weaponSets["right"]
    local w1, w2 = assetManager[weaponSet[1].asset], assetManager[weaponSet[2].asset]
    local scale = scene.scale * 4
    if w1 then
      lg.draw(w1, -8*scale, scale, 0, scale)
    end
    if w2 then
      lg.draw(w2, -8*scale, 16*scale+padding*2, 0, scale)
    end
    lg.translate(-innerRectangleWidth/2, (16*scale)*2+padding*4)
    lg.setColor(0,0,0,1)
    local text = lang.getText("game.weaponset.right.title")
    local font = ui.getFont(17, "fonts.regular.bold", scene.scale)
    local _, wrappedText = font:getWrap(text, innerRectangleWidth)
    lg.printf(text, font, 0, 0, innerRectangleWidth, "center")
    lg.translate(padding, #wrappedText*(font:getHeight()))
    local font = ui.getFont(16, "fonts.regular.bold", scene.scale)
    lg.printf(lang.getText("game.weaponset.right.text"), font, 0, 0, innerRectangleWidth, "left")
    lg.pop()
    lg.pop()

    lg.pop()
  elseif scene.state == "game" then
    -- draw game ui
    local wsize = settings._default.client.windowSize
    local tw, th = wsize.width, wsize.height
    local widthOffset = lg.getWidth()-(tw*scene.scale)
    local heightOffset = lg.getHeight()-(th*scene.scale)
    lg.setColor(1,1,1,1)
    lg.push("all")
    lg.translate(widthOffset/2, heightOffset/2)

    local padding = 4*scene.scale
    local squareSize = 16*4*scene.scale

    local squareSizePadded = squareSize+padding*2

    local weapons = scene.player.weapons
    local w1, w2 = assetManager[weapons[1].asset], assetManager[weapons[2].asset]

    lg.push()
    lg.translate((tw/2)*scene.scale-padding/2, 0)
    local inputMouse = assetManager["input.pc.mouse.scroll.vertical"]
    if inputMouse then
      local s = scene.scale/3
      local w, h = inputMouse:getDimensions()
      w, h = w * s, h * s
      lg.draw(inputMouse, -w/2, squareSize/2, 0, s)
    end

    lg.push("all")
    lg.setColor(1,1,1,0.1)
    lg.rectangle("fill", -(squareSize+padding*4), padding, squareSizePadded, squareSizePadded, 10)
    local per = ((scene.player.attackCooldown or 1) / (weapons[1].cooldown or 1))
    if scene.player.weaponIndex == 1 then
      if scene.player.attackCooldown ~= 0 then
        lg.setColor(.8,0.2,0.3,1)
        if per > 0.05 then
          lg.rectangle("fill", -(squareSize+padding*4), padding+squareSizePadded*(1-per), squareSizePadded, squareSizePadded * per, 10)
        end
      end
      lg.setColor(1,1,.5,1)
      lg.rectangle("line", -(squareSize+padding*4), padding, squareSizePadded, squareSizePadded, 10)
    end
    if w1 then
      lg.setColor(1,1,1,(scene.player.weaponIndex == 1 and per <= 0) and 1 or scene.player.weaponIndex == 2 and 1 or 0.5)
      lg.draw(w1, -(squareSize+padding*3), padding*2, 0, 4*scene.scale)
    end
    lg.pop()

    lg.translate(padding, 0)

    lg.push("all")
    lg.setColor(1,1,1,0.1)
    lg.rectangle("fill",  padding, padding, squareSizePadded, squareSizePadded, 10)
    local per = ((scene.player.attackCooldown or 1) / (weapons[2].cooldown or 1))
    if scene.player.weaponIndex == 2 then
      if scene.player.attackCooldown ~= 0 then
        lg.setColor(.8,0.2,0.3,1)
        if per > 0.05 then
          lg.rectangle("fill", padding, padding+squareSizePadded*(1-per), squareSizePadded, squareSizePadded * per, 10)
        end
      end
      lg.setColor(1,1,.5,1)
      lg.rectangle("line", padding, padding, squareSizePadded, squareSizePadded, 10)
    end
    if w2 then
      lg.setColor(1,1,1,(scene.player.weaponIndex == 2 and per <= 0) and 1 or scene.player.weaponIndex == 1 and 1 or 0.5)
      lg.draw(w2, padding*2, padding*2, 0, 4*scene.scale)
    end
    lg.pop()
    lg.pop()

    lg.pop()
  end

  lg.pop()
  lg.setDepthMode("lequal", true)
end

scene.wheelmoved = function(_, y)
  if y > 0 then
    scene.player.setWeaponIndex(1)
  end
  if y < 0 then
    scene.player.setWeaponIndex(2)
  end
end

scene.keypressed = function(_, key)
  if key == "1" or key == "kp1" then
    scene.player.setWeaponIndex(1)
  end
  if key == "2" or key == "kp2" then
    scene.player.setWeaponIndex(2)
  end
end

return scene