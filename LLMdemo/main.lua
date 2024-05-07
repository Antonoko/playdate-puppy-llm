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

local STAGE = {}
local stage_manager = "rabbit"

local FONT = {
    CabinetGroteskThin16 = {
        font = gfx.font.new('font/CabinetGrotesk-Thin-16')
    },
    CabinetGroteskRegular60 = {
        font = gfx.font.new('font/CabinetGrotesk-Regular-60')
    },
}

local t_rabbit = gfx.imagetable.new("img/rabbit-R90")
local t_rabbit_animation = gfx.animation.loop.new(30, t_rabbit, true)
local t_rabbit_sprite = gfx.sprite.new(t_rabbit_animation:image())
local i_battery_icon = gfx.image.new("img/icon-battery")
local time_sprite = gfx.sprite.new()
local battery_text_sprite = gfx.sprite.new()


--------------------------------------------

function get_time_now_as_string()
    local minute = playdate.getTime().minute
    if minute <10 then
        minute = "0"..minute
    end
    local second = playdate.getTime().second
    if second <10 then
        second = "0"..second
    end

    -- return playdate.getTime().year.."/"..playdate.getTime().month.."/"..playdate.getTime().day.."   "..playdate.getTime().hour..":"..minute..":"..second
    return playdate.getTime().hour..":"..minute
end



--------------------------------------------

function render_battery()
    --FIXME lazy update
    local image = gfx.image.new(screenWidth,20)
    gfx.pushContext(image)
        gfx.setFont(FONT["CabinetGroteskThin16"].font)
        gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
        gfx.drawTextAligned(string.format(math.floor(pd.getBatteryPercentage())).."%", screenWidth/2, 0, kTextAlignment.right)
        i_battery_icon:draw(screenWidth/2+4, 1)
        gfx.setColor(playdate.graphics.kColorWhite)
        gfx.fillRect(screenWidth/2+6, 3, math.floor(16*(pd.getBatteryPercentage()/100)), 7)
    gfx.popContext()
    battery_text_sprite:setImage(image)
end



function render_time()
    --FIXME lazy update
    local image = gfx.image.new(screenWidth,64)
    gfx.pushContext(image)
        gfx.setFont(FONT["CabinetGroteskRegular60"].font)
        gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
        gfx.drawTextAligned(get_time_now_as_string(), screenWidth/2, 0, kTextAlignment.center)
    gfx.popContext()
    time_sprite:setImage(image)
end


--------------------------------------------

STAGE["rabbit"] = function()
    t_rabbit_sprite:setImage(t_rabbit_animation:image())
    render_time()
    render_battery()
end

--------------------------------------------

function init()
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, screenWidth, screenHeight)

    battery_text_sprite:add()
    battery_text_sprite:moveTo((screenWidth/2)+110, screenHeight/2)
    battery_text_sprite:setRotation(90)
    time_sprite:add()
    time_sprite:moveTo((screenWidth/2)+70, screenHeight/2)
    time_sprite:setRotation(90)
    t_rabbit_sprite:add()
    t_rabbit_sprite:moveTo((screenWidth/2)+15, screenHeight/2)
end


function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()
    

    STAGE[stage_manager]()
end

init()