local lg = love.graphics

local audioManager = require("util.audioManager")
local assetManager = require("util.assetManager")
local settings = require("util.settings")
local logger = require("util.logger")
local cursor = require("util.cursor")
local input = require("util.input")
local lang = require("util.lang")
local flux = require("libs.flux")
local suit = require("libs.suit").new()
local ui = require("util.ui")

local g3d = require("libs.g3d")
local cam = g3d.camera:current()
cam.fov = math.rad(50)
cam:updateProjectionMatrix()

local settingsMenu = require("ui.menu.settings")
settingsMenu.set(suit)

suit.theme = require("ui.theme.menu")

local gameLogo1 = lg.newImage("assets/gamelogo_000.png")
gameLogo1:setFilter("nearest", "nearest")
local gameLogo2 = lg.newImage("assets/gamelogo_001.png")
gameLogo2:setFilter("nearest", "nearest")

do
  require("assets.cells.park")
  
  require("assets.cells.city_res")
end
local road = require("src.road")

local scene = {
  menu = "prompt",
  posX = love.math.random() > 0.5 and love.math.random(-90,-30) or love.math.random(70,120),
  posY = 14,
}

local updateCamera = function()
  g3d.camera.current():lookAt(scene.posX, 10, scene.posY, scene.posX, 0, scene.posY-8)
end

scene.preload = function()
  settingsMenu.preload()
end

scene.load = function()
  suit:gamepadMode(true)
  cursor.setType(settings.client.systemCursor and "system" or "custom")

  --scene.menu = "prompt"
  scene.zone = require("src.zone").getZone("city")
  settingsMenu.load()
end

scene.unload = function()
  cursor.switch(nil)
  settingsMenu.unload()
end

scene.langchanged = function()
  scene.prompt = require("libs.sysl-text").new("left", { 
    color = { 1,1,1,1 },
  })
  scene.prompt:send(lang.getText("menu.prompt"), nil, true)
end

scene.resize = function(w, h)
  -- Update settings
  settings.client.resize(w, h)

  -- Scale scene
  local wsize = settings._default.client.windowSize
  local tw, th = wsize.width, wsize.height
  local sw, sh = w / tw, h / th
  scene.scale = sw < sh and sw or sh

  -- scale UI
  suit.scale = scene.scale
  suit.theme.scale = scene.scale

  -- scale Text
  local font = ui.getFont(18, "fonts.regular.bold", scene.scale)
  lg.setFont(font)

  scene.prompt.default_font = font

  -- scale Cursor
  cursor.setScale(scene.scale)

  --
  local cam = g3d.camera:current()
  cam.aspectRatio = (w/h)
  cam:updateProjectionMatrix()
end

local bgTimer = 0
local logoTimer = 0

local inputTimer, inputTimeout = 0, 0
local inputType = nil
scene.update = function(dt)
  logoTimer = logoTimer + dt
  if logoTimer >= 1 then
    logoTimer = 0
  end

  bgTimer = bgTimer + dt
  if bgTimer > 10 then
    bgTimer = 0
    local newX = 0
    repeat
      newX = love.math.random() > 0.5 and love.math.random(-90,-30) or love.math.random(70,120)
    until math.abs(newX - scene.posX) >= 20
    scene.posX = newX
  end
  scene.posX = scene.posX + dt*1
  updateCamera()
  scene.zone:update(dt, nil)

  if scene.menu == "main" then
    if not suit.gamepadActive then
      if input.baton:pressed("menuNavUp") or input.baton:pressed("menuNavDown") then
        suit:gamepadMode(true)
      end
    end
    if suit.gamepadActive then
      if not inputType then
        local menuUp = input.baton:pressed("menuNavUp") and 1 or 0
        local menuDown = input.baton:pressed("menuNavDown") and 1 or 0
        local pos = menuUp - menuDown
        if pos ~= 0 then
          inputType = pos == 1 and "menuNavUp" or "menuNavDown"
          inputTimer = 0
          inputTimeout = .5
        end

        suit:adjustGamepadPosition(pos)
      else
        if input.baton:released(inputType) then
          inputType = nil
        else
          inputTimer = inputTimer + dt
          while inputTimer > inputTimeout do
            inputTimer = inputTimer - inputTimeout
            inputTimeout = .1
            suit:adjustGamepadPosition(inputType == "menuNavUp" and 1 or -1)
          end
        end
      end

      if input.baton:pressed("accept") then
        suit:setHit(suit.hovered)
      end
      if input.baton:pressed("reject") then
        suit:setGamepadPosition(1) -- jump to exit button
      end
    end
  end

  if suit.gamepadActive then
    love.mouse.setRelativeMode(true)
    love.mouse.setVisible(false)
  else
    love.mouse.setRelativeMode(false)
    love.mouse.setVisible(true)
  end

  if scene.menu == "settings" then
    settingsMenu.update(dt)
  end

  scene.prompt:update(dt)
end

local maxOffsetW = 30

local drawMenuButton = function(text, opt, x, y, w, h)
  local slice3 = assetManager["ui.3slice.basic"]

  if opt.entered then
    if opt.flux then opt.flux:stop() end
    opt.flux = flux.to(opt, .5, {
      offsetW = maxOffsetW
    }):ease("elasticout")
  end
  if opt.left then
    if opt.flux then opt.flux:stop() end
    opt.flux = flux.to(opt, .2, {
      offsetW = 0
    }):ease("quadout")
  end
  if not opt.hovered and opt.flux and opt.flux.progress >= 1 then
    opt.flux:stop()
    opt.flux = nil
    opt.offsetW = 0
  end

  lg.push()
  lg.origin()
  lg.translate(x, y)
    lg.push() 
    if opt.hovered then
      lg.setColor(1,1,1,1)
    else
      lg.setColor(1,1,1,1)
    end
    slice3:draw(lg.getFont():getWidth(text) + (slice3.offset*2 + opt.offsetW) * scene.scale, h)
    lg.pop()
  lg.setColor(.1,.1,.1,1)
  if opt.hovered then
    text = " "..text
  end
  lg.print(text, slice3.offset * scene.scale, 0)
  lg.setColor(1,1,1,1)
  lg.pop()
end

local changeMenu = function(target)
  scene.menu = target
  cursor.switch(nil)
end

local menuButton = function(button, font, height)
  local str = lang.getText(button.id)
  local slice3 = assetManager["ui.3slice.basic"]
  local slice3Width = slice3:getLength(font:getWidth(str), height)
  local width = slice3Width + maxOffsetW * scene.scale
  local b = suit:Button(str, button, suit.layout:up(width, nil))
  if b.hit and type(button.hitCB) == "function" then
    audioManager.play("audio.ui.click")
    button.hitCB()
    return
  end
  cursor.switchIf(b.hovered, "hand")
  cursor.switchIf(b.left, nil)

  if b.entered then
    audioManager.play("audio.ui.select")
  end
end

local mainButtonFactory = function(langKey, callback)
  return {
    id = langKey,
    hitCB = callback,
    noScaleX = true,
    draw = drawMenuButton,
    gamepadOption = true,
    offsetW = 0,
  }
end

local mainButtons = {
  mainButtonFactory("menu.exit", function()
      love.event.quit()
    end),
  mainButtonFactory("menu.settings", function()
      changeMenu("settings")
      suit:setGamepadPosition(1)
    end),
  mainButtonFactory("menu.new_game", function()
      --logger.warn("TODO new game button")
      --changeMenu("game")
      require("util.sceneManager").changeScene("scenes.game")
    end),
}

if false then
  logger.warn("TODO load button conditional show")
  table.insert(mainButtons,
    mainButtonFactory("menu.load", function()
      logger.warn("TODO load game button")
    end))
  table.insert(mainButtons,
    mainButtonFactory("menu.continue", function()
      logger.warn("TODO continue game button")
    end))
end

scene.updateui = function()
  suit:enterFrame()
  local font = lg.getFont()
  local fontHeight = font:getHeight()
  local buttonHeight = fontHeight / scene.scale

  local windowHeightScaled = lg.getHeight() / scene.scale
  suit.layout:reset(fontHeight*1.5, windowHeightScaled - buttonHeight*0.5, 0, 10)
  suit.layout:up(0, buttonHeight)
  suit.layout:up(0, buttonHeight)

  if scene.menu == "main" then
    for _, button in ipairs(mainButtons) do
      menuButton(button, font, buttonHeight)
    end
  elseif scene.menu == "settings" then
    if settingsMenu.updateui() then
      changeMenu("main")
    end
  end
end

local logoBounce = { offset = 0 }
local logoKey1, logoKey2
logoKey1 = function()
  flux.to(logoBounce, 2, { offset = -20}):ease("backinout"):oncomplete(logoKey2)
end
logoKey2 = function()
  flux.to(logoBounce, 2, { offset = 0}):ease("backinout"):oncomplete(logoKey1)
end
logoKey1()

scene.draw = function()
  lg.clear(0.7,0.3,0.4,1)
  lg.setDepthMode("lequal", true)
  road.draw("city")
  scene.zone:draw(0)
  lg.setDepthMode("always", true)


  if scene.menu ~= "settings" then
    lg.setColor(.05,.05,.05, .5)
    lg.rectangle("fill", 0, 0, lg.getDimensions())
    lg.setColor(1,1,1,1)
    local w, h = lg.getDimensions()
    local iw, ih = gameLogo1:getDimensions()
    iw, ih = iw*2*scene.scale, ih*2*scene.scale
    local img = logoTimer > 0.5 and gameLogo1 or gameLogo2
    lg.draw(img, w/2-iw/2, ih+logoBounce.offset*scene.scale, 0, 2*scene.scale)

    local lk = love.keyboard
    local text = ""
    text = text .. lk.getScancodeFromKey("w") .. lk.getScancodeFromKey("a") .. lk.getScancodeFromKey("s") .. lk.getScancodeFromKey("d")
    text = text:upper() .." movement | Mouse left click attack | "
    local key = lk.getScancodeFromKey("e")
    text = text .. key:upper() .. " to interact"
    lg.print(text, w-lg.getFont():getWidth(text)-10*scene.scale, h-lg.getFont():getHeight()-10*scene.scale)
  end

  if scene.menu == "prompt" then
    local windowW, windowH = lg.getDimensions()
    local offset = windowH/10
    scene.prompt:draw(offset, windowH - offset - scene.prompt.get.height)
  elseif scene.menu == "settings" then
    settingsMenu.draw()
  end
  suit:draw(1)
end

scene.textedited = function(...)
  suit:textedited(...)
end

scene.textinput = function(...)
  suit:textinput(...)
end

local inputDetected = function(inputType)
  if scene.menu == "prompt" then
    flux.to(scene.prompt.current_color, .2, { [4] = 0 }):ease("linear"):oncomplete(function()
      changeMenu("main")
    end)
    if inputType == "mouse" then
      suit:gamepadMode(false)
    end
  end
end

scene.keypressed = function(...)
  suit:keypressed(...)
  inputDetected()
end

scene.mousepressed = function()
  inputDetected("mouse")
  suit:gamepadMode(false)
end
scene.touchpressed = scene.mousepressed

scene.mousemoved = function()
  if scene.menu ~= "prompt" then
    suit:gamepadMode(false)
  end
end

scene.wheelmoved = function(...)
  suit:updateWheel(...)
  inputDetected()
end

scene.gamepadpressed = function()
  inputDetected()
  suit:gamepadMode(true)
end
scene.joystickpressed = scene.gamepadpressed
scene.joystickaxis = scene.gamepadpressed

return scene