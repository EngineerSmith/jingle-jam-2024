# Jingle Jam Game Jam 2024
This is the repo for a submission to the [2024 Jingle Jam Game Jam](https://itch.io/jam/jinglegamejam2024)

## License
The MIT license applies exclusively to the code contained within this directory and it's subdirectories. It excludes code that has it's own license within the license directory. It also does not extend to the assets directory, which is subject to a separate license.

## Assets
To add new assets, you can put them in the `assets` directory. Then you can add it to the `assets/assets.lua` file which lists all assets. You may have to create a subdirectory, to ensure it is correctly sorted.

* `path` is the file path, within the `assets` directory
* `name` is the unique keyword you will use to access the asset within the project
* `onLoad` is a function that is called after the asset has been loaded (see `pixelArt`)

Audio additions:
* `sourceType` is for the load type for the source. `static` or `stream`. General rule, SFX should use `static`, Music should use `stream`
* `audioType` is for what category the source should come under for volume.
* `key` is for merging sources into a single "asset", when this key is played it will select one of the sources at random within the group.
* `volume` is the static modifier for this individual source. By default it is 1, and can only go lower until 0. This is to allow for audio to be roughly equal within the same grouping.

Fonts, are handled differently due to the window resize requirement. Talk to EngineerSmith for help with that system.

To access the newly added assets, you must first define that they should be loaded in that scene using `assets.lua` within the scene's directory. The asset will correctly load, and unload dynamically as the scene changes that way.

Once the asset has been defined to load for the scene, or level within the scene. You can access it the following way.:
```lua
local assetManager = require("util.assetManager")
-- ...
function draw()
  local texture = assetManager["name"]
  -- ...
end
```
It is important you always access the asset this way, and not store a reference or a copy within a table or variable outside the scope it's being used in.

## Arguments
There are a few arguments that you can use to speed up development. These are used when you run the program. These work with the unfused or fused project: `love . --speed` or `game.exe --speed`

* `--speed` Will skip the intro-scenes, as soon as all assets are loaded.
* `--log [file name: log.txt]` Will add a logging sink, to save logs
  * e.g. `--log` saves to [save directory]/log.txt, `--log mylogs.txt` saves to [save directory]/mylogs.txt
* `--settings <filename>` Will use to use a different file for settings than the default [save directory]/settings.json
* `--reset` Will reset all settings to their default values. If used with `--settings`, resets the specified custom settings file.
---
<big>Note!</big>

All custom file locations must be within the [save directory]. You cannot directly reference a file, unless you're referencing a file from the fused directory of the project! Which can only happen if the project is fused, or used love's direct argument `--fused`

### How to use arguments in code
```lua
local args = require("util.args")

-- Ran with `love . --keyword` will be of type boolean
if args["--keyword"] then
  print("--keyword arg used")
end

-- Ran with `love . --keyword apple banana` will make an array with two entries ['apple', 'banana']
local var = "orange"
if type(args["--keyword"]) == "table" then
  print(var, "=", args["--keyword"][1]) -- orange  =   apple
  var = args["--keyword"][1]
end
```

## Language
You can add language keys to `en.json`, and the access them with the following.
```lua
local lang = require("util.lang")
local str = lang.getText("my.key")
-- for text, with variables
  -- e.g. 'my.key': 'My cat's name is $1. $2 $1'
local str = lang.getText("my.key", 'Pizza', 'I love') -- 'My cat's name is Pizza. I love Pizza'
```

## Logging
The project includes a basic logging system
```lua
local logger = require("util.logger")

-- Logger contains a few basic functions. The different levels, just use different prefixes and colors (where consoles support colors)
logger.info()
logger.warn()
logger.error()
logger.fatal() -- fatal, will show a message box and close the program
logger.unknown()

-- They all work similar to print, in that they can take in multiple values
logger.info("What have I done wrong", type(variable1), variable1)

-- Note, if you call global print()
print("debug", var)
-- it will redirect to logger.unknown
logger.unknown("debug", var) -- same as, but without having to grab the logger table
```

[save directory]: https://love2d.org/wiki/love.filesystem