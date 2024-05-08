import 'CoreLibs/graphics'
import "CoreLibs/ui"
import "CoreLibs/timer"
import "CoreLibs/crank"
import "CoreLibs/sprites"
import "CoreLibs/animation"

local pd <const> = playdate
local gfx <const> = playdate.graphics
local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()

local str = "{\"msglist\":[{\"name\":\"You\",\"streaming\":false,\"content\":[\"f\",\"u\"]},{\"name\":\"Puppy\",\"streaming\":true,\"content\":[\"啊\",\"啊\",\"啊\",\"\n\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"草\"]}]}"
local fuck = json.decode(str)

for key, section in pairs(fuck["msglist"]) do
    print(section.name)
end


function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()

end