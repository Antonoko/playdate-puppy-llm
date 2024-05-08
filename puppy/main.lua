import './pdportal'

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

----------------------------------------------------

local LINEHEIGHT_FACTOR <const> = 1.4

local STAGE = {}
local stage_manager = "puppy"
local stage_manager_choose = "puppy"

local FONT = {
    CabinetGroteskThin16 = {
        font = gfx.font.new('font/CabinetGrotesk-Thin-16')
    },
    CabinetGroteskRegular60 = {
        font = gfx.font.new('font/CabinetGrotesk-Regular-60')
    },
    SourceHanSansCNM20px = {
        font = gfx.font.new('font/SourceHanSansCN-M-20px')
    },
    Roobert11Medium = {
        font = gfx.font.new('font/Roobert-11-Medium')
    },
}

local time_str_lazy
local time_query_cnt = 1000
local battery_str_lazy
local battery_query_cnt = 1000
local icon_puppy = gfx.image.new("img/icon-puppy")
local tip_btn = gfx.image.new("img/tip-btn")
local tip_btn_sprite = gfx.sprite.new(tip_btn)
local t_puppy = gfx.imagetable.new("img/puppy")
local t_puppy_animation = gfx.animation.loop.new(30, t_puppy, true)
local t_puppy_sprite = gfx.sprite.new(t_puppy_animation:image())
local i_battery_icon = gfx.image.new("img/icon-battery")
local time_sprite = gfx.sprite.new()
local battery_text_sprite = gfx.sprite.new()
local chat_sprite = gfx.sprite.new()
local chat_pointer = gfx.imagetable.new("img/pointer")
local chat_pointer_delay_cnt = 0
local chat_pointer_delay_times <const> = 1

local icon_utils = {
    no_signal = {
        sprite = gfx.sprite.new(gfx.image.new("img/icon-no-signal"))
    },
    loading = {
        sprite = gfx.sprite.new(gfx.image.new("img/icon-loading"))
    }
}

local img_chat_buffer = gfx.image.new(400, 2000)
local img_chat_draw_coord_x_offset = 60
local img_chat_draw_coord_x = 0
local img_chat_draw_coord_y = 0
local img_chat_streaming_text_char_index = 1
local img_chat_streaming_text_x = 0
local img_chat_streaming_text_y = 0
local img_chat_streaming_text_x_last = 0
local img_chat_streaming_text_y_last = 0

local history_chat_render_done = false
local streaming_chat_render_done = false

--------------------------------------------------------------------------------------

local server_address = 'http://127.0.0.1:5001/mypostendpoint'

local PdPortal <const> = PdPortal
local PortalCommand <const> = PdPortal.PortalCommand
local msg_received, msg_received_lazy

class('PuppyCommunication').extends(PdPortal)
local PuppyCommunication <const> = PuppyCommunication

function PuppyCommunication:init()
	PuppyCommunication.super.init(self)
	self:_initOwnProps()
end

function PuppyCommunication:_initOwnProps()
	self.connected = false
	self.isSendingRequest = false
	self.responseImage = nil
	self.portalVersion = nil
end

function PuppyCommunication:get_llm_response(msg_send, new_chat)
    self:_createObject(json.encode({
        name = 'llm-fetch',
        data = {
            msg = string.format(msg_send),
            new_chat = new_chat
        }
    }))
end

function PuppyCommunication:update()
	PuppyCommunication.super.update(self)

	if self.connected then
		if self.isSendingRequest then
            icon_utils.no_signal.sprite:remove()
            icon_utils.loading.sprite:add()
            --fetching
		else
            icon_utils.no_signal.sprite:remove()
            icon_utils.loading.sprite:remove()
			--normal
		end
	else
        icon_utils.no_signal.sprite:add()
        icon_utils.loading.sprite:remove()
        -- 'Disconnected'
	end
end

function PuppyCommunication:deliver_msg(responseText)
    msg_received = json.decode(responseText)
end

function PuppyCommunication:_createObject(body)
	self.isSendingRequest = true

	self:fetch(
		server_address,
		{
			body = body,
			method = 'POST',
			headers = {
				['Content-Type'] = 'application/json'
			},
		},
		function (responseText, responseDetails)
			self.isSendingRequest = false

			local responseJson = json.decode(responseText)

			if responseDetails.status == 200 then
				self:deliver_msg(responseText)
			else
				self:_handleError(responseText)
			end
		end,
		function (errorDetails)
			self:_handleError(errorDetails.message)
		end
	)
end

function PuppyCommunication:_handleError(errorMessage)
	self.isSendingRequest = false
    self:deliver_msg('{}')
	-- self:deliver_msg('Error: ' .. errorMessage)
end

function PuppyCommunication:onConnect(portalVersion)
	self.connected = true
	self.portalVersion = portalVersion
	self:log('connectEcho!', portalVersion)
end

function PuppyCommunication:onDisconnect()
	self:_initOwnProps()
end

------------------------------------------------------------------------

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

function x_func(i)
    return i
end

function x_ne_func(i)
    return -i
end


function deepCompareTable(tbl1, tbl2)
    if tbl1 == tbl2 then
        return true
    elseif type(tbl1) == "table" and type(tbl2) == "table" then
        for key1, value1 in pairs(tbl1) do
            local value2 = tbl2[key1]
            if value2 == nil then
                return false
            elseif value1 ~= value2 then
                if type(value1) == "table" and type(value2) == "table" then
                    if not deepCompare(value1, value2) then
                        return false
                    end
                else
                    return false
                end
            end
        end
        for key2, _ in pairs(tbl2) do
            if tbl1[key2] == nil then
                return false
            end
        end
        return true
    end
    return false
end

function shallowCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end
    return copy
end

--------------------------------------------

function render_battery()
    --FIXME lazy update
    if battery_query_cnt < 30 then
        battery_query_cnt += 1
        return
    end
    battery_query_cnt = 0
    if pd.getBatteryPercentage() == battery_str_lazy then
        return
    end

    local image = gfx.image.new(screenWidth,20)
    gfx.pushContext(image)
        gfx.setFont(FONT["CabinetGroteskThin16"].font)
        gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
        gfx.drawTextAligned(string.format(math.floor(pd.getBatteryPercentage())).."%", screenWidth/2, 0, kTextAlignment.right)
        i_battery_icon:draw(screenWidth/2+4, 1)
        gfx.setColor(playdate.graphics.kColorWhite)
        gfx.fillRect(screenWidth/2+6, 3, math.floor(16*(pd.getBatteryPercentage()/100)), 7)
    gfx.popContext()
    battery_text_sprite:setImage(image:rotatedImage(90))
    battery_str_lazy = pd.getBatteryPercentage()
end


function render_time()
    if time_query_cnt < 30 then
        time_query_cnt += 1
        return
    end
    time_query_cnt = 0
    if get_time_now_as_string() == time_str_lazy then
        return
    end
    local image = gfx.image.new(screenWidth,64)
    gfx.pushContext(image)
        gfx.setFont(FONT["CabinetGroteskRegular60"].font)
        gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
        gfx.drawTextAligned(get_time_now_as_string(), screenWidth/2, 0, kTextAlignment.center)
    gfx.popContext()
    time_sprite:setImage(image:rotatedImage(90))
    time_str_lazy = get_time_now_as_string()
end


function init_calc_chat_img(response_json)
    local height = 0
    for key, section in pairs(response_json["msglist"]) do
        gfx.setFont(FONT["Roobert11Medium"].font)
        height += gfx.getTextSize("M") * LINEHEIGHT_FACTOR +6
        gfx.setFont(FONT["SourceHanSansCNM20px"].font)
        local max_zh_char_size = gfx.getTextSize("啊")
        local lineheight = max_zh_char_size * LINEHEIGHT_FACTOR
        local current_x = img_chat_draw_coord_x_offset
        for key, char in pairs(section.content) do
            if char == "\n" then
                current_x = img_chat_draw_coord_x_offset
                height += lineheight
            else
                current_x += gfx.getTextSize(char)
            end
            if current_x > 320 - max_zh_char_size then
                current_x = img_chat_draw_coord_x_offset
                height += lineheight
            end
        end
        height += lineheight
        height += 20 --buffer
    end

    img_chat_buffer = gfx.image.new(screenWidth, height)
end

function render_chat(response_json)
    function _render_name(name, x, y)
        gfx.setFont(FONT["Roobert11Medium"].font)
        gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
        gfx.drawTextAligned(name, x, y, kTextAlignment.left)
    end

    function _render_chat_content(content, x, y)
        local current_x = x
        local y_offset_callback = 0
        gfx.setFont(FONT["SourceHanSansCNM20px"].font)
        gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
        local max_zh_char_size = gfx.getTextSize("啊")
        local lineheight = max_zh_char_size * LINEHEIGHT_FACTOR
        for key, char in pairs(content) do
            if char == "\n" then
                current_x = x
                y_offset_callback += lineheight
            else
                gfx.drawTextAligned(char, current_x, y_offset_callback+y, kTextAlignment.left)
                current_x += gfx.getTextSize(char)
            end
            
            if current_x > 320 - max_zh_char_size then
                current_x = x
                y_offset_callback += lineheight
            end
        end
        return y_offset_callback
    end

    function _render_puppy_avatar(x, y)
        gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
        icon_puppy:draw(x, y)
    end

    gfx.pushContext(img_chat_buffer)
        for key, section in pairs(response_json["msglist"]) do
            _render_name(section.name, img_chat_draw_coord_x + img_chat_draw_coord_x_offset, img_chat_draw_coord_y)
            if string.lower(section.name) == "puppy" then
                _render_puppy_avatar(8, img_chat_draw_coord_y-8)
            end
            gfx.setFont(FONT["Roobert11Medium"].font)
            img_chat_draw_coord_y += gfx.getTextSize("M") * LINEHEIGHT_FACTOR +6
            if not section.streaming then
                img_chat_draw_coord_y += _render_chat_content(section.content, img_chat_draw_coord_x + img_chat_draw_coord_x_offset, img_chat_draw_coord_y)
                img_chat_draw_coord_y += 36
            end
        end
    gfx.popContext()
    chat_sprite:setImage(img_chat_buffer)

    img_chat_streaming_text_y = img_chat_draw_coord_y
end


function render_chat_stream_part(response_json)
    if streaming_chat_render_done then
        return
    end

    if chat_pointer_delay_cnt < chat_pointer_delay_times then
        chat_pointer_delay_cnt += 1
        return
    end
    chat_pointer_delay_cnt = 0

    function _render_chat_single_char(content)
        if img_chat_streaming_text_char_index > #content then
            chat_pointer:drawImage(2, img_chat_streaming_text_x_last + img_chat_draw_coord_x_offset, img_chat_streaming_text_y_last)
            streaming_chat_render_done = true
            return
        end
        gfx.setFont(FONT["SourceHanSansCNM20px"].font)
        local max_zh_char_size = gfx.getTextSize("啊")
        local lineheight = max_zh_char_size * LINEHEIGHT_FACTOR
        local char = content[img_chat_streaming_text_char_index]
        gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)

        if img_chat_streaming_text_char_index > 1 then
            chat_pointer:drawImage(2, img_chat_streaming_text_x_last + img_chat_draw_coord_x_offset, img_chat_streaming_text_y_last)
        end
        
        if char == "\n" then
            img_chat_streaming_text_x = 0
            img_chat_streaming_text_y += lineheight
        else
            gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
            chat_pointer:drawImage(1, img_chat_streaming_text_x + img_chat_draw_coord_x_offset + max_zh_char_size, img_chat_streaming_text_y)
            gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
            gfx.drawTextAligned(char, img_chat_streaming_text_x + img_chat_draw_coord_x_offset, img_chat_streaming_text_y, kTextAlignment.left)
            img_chat_streaming_text_x += gfx.getTextSize(char)
        end
        
        img_chat_streaming_text_x_last = img_chat_streaming_text_x
        img_chat_streaming_text_y_last = img_chat_streaming_text_y

        if img_chat_streaming_text_x > 320 - max_zh_char_size then
            img_chat_streaming_text_x = 0
            img_chat_streaming_text_y += lineheight
        end

        if img_chat_streaming_text_y_last > screenHeight then
            chat_sprite:moveTo(0, -(img_chat_streaming_text_y_last-screenHeight)-30)
        end
    end

    gfx.pushContext(img_chat_buffer)
        for key, section in pairs(response_json["msglist"]) do
            if section.streaming then
                _render_chat_single_char(section.content)
            end
        end
    gfx.popContext()
    chat_sprite:setImage(img_chat_buffer)
    img_chat_streaming_text_char_index += 1
end


function update_chat_render(response_json)
    if not history_chat_render_done then
        init_calc_chat_img(response_json)
        render_chat(response_json)
        history_chat_render_done = true
    end

    if not streaming_chat_render_done then
        -- local img_x, img_y = img_chat_buffer:getSize()
        -- if img_y > screenHeight then
        --     chat_sprite:moveTo(0, -(img_y-screenHeight)-30)
        -- end
        render_chat_stream_part(response_json)
    end
end

function reset_chat_render()
    history_chat_render_done = false
    streaming_chat_render_done = false
    img_chat_buffer = gfx.image.new(400, 2000)
    img_chat_draw_coord_x_offset = 60
    img_chat_draw_coord_x = 0
    img_chat_draw_coord_y = 0
    img_chat_streaming_text_char_index = 1
    img_chat_streaming_text_x = 0
    img_chat_streaming_text_y = 0
    img_chat_streaming_text_x_last = 0
    img_chat_streaming_text_y_last = 0
end


--------------------------------------------

STAGE["puppy"] = function()
    t_puppy_sprite:setImage(t_puppy_animation:image())
    render_time()
    render_battery()
end


STAGE["terminal"] = function()
    puppy_communication:update()

    if msg_received ~= nil then
        update_chat_render(msg_received)
    end

    if pd.buttonJustPressed(pd.kButtonA) then
        -- puppy_communication:get_llm_response("hellooooo", false)
        local str = "{\"msglist\":[{\"name\":\"You\",\"streaming\":False,\"content\":[\"h\",\"i\",\"\",\"你\",\"好\",\"啊\"]},{\"name\":\"Puppy\",\"streaming\":True,\"content\":[\"H\",\"i\",\"\",\"t\",\"h\",\"e\",\"r\",\"e\",\"!\",\"\",\"I\",\"\"\",\"m\",\"\",\"L\",\"L\",\"a\",\"M\",\"A\",\",\",\"\",\"a\",\"n\",\"\",\"A\",\"I\",\"\",\"a\",\"s\",\"s\",\"i\",\"s\",\"t\",\"a\",\"n\",\"t\",\"\",\"d\",\"e\",\"v\",\"e\",\"l\",\"o\",\"p\",\"e\",\"d\",\"\",\"b\",\"y\",\"\",\"M\",\"e\",\"t\",\"a\",\"\",\"A\",\"I\",\"\",\"t\",\"h\",\"a\",\"t\",\"\",\"c\",\"a\",\"n\",\"\",\"u\",\"n\",\"d\",\"e\",\"r\",\"s\",\"t\",\"a\",\"n\",\"d\",\"\",\"a\",\"n\",\"d\",\"\",\"r\",\"e\",\"s\",\"p\",\"o\",\"n\",\"d\",\"\",\"t\",\"o\",\"\",\"h\",\"u\",\"m\",\"a\",\"n\",\"\",\"i\",\"n\",\"p\",\"u\",\"t\",\"\",\"i\",\"n\",\"\",\"a\",\"\",\"c\",\"o\",\"n\",\"v\",\"e\",\"r\",\"s\",\"a\",\"t\",\"i\",\"o\",\"n\",\"a\",\"l\",\"\",\"m\",\"a\",\"n\",\"n\",\"e\",\"r\",\".\",\"\",\"I\",\"\"\",\"m\",\"\",\"n\",\"o\",\"t\",\"\",\"a\",\"\",\"h\",\"u\",\"m\",\"a\",\"n\",\",\",\"\",\"b\",\"u\",\"t\",\"\",\"a\",\"\",\"c\",\"o\",\"m\",\"p\",\"u\",\"t\",\"e\",\"r\",\"\",\"p\",\"r\",\"o\",\"g\",\"r\",\"a\",\"m\",\"\",\"d\",\"e\",\"s\",\"i\",\"g\",\"n\",\"e\",\"d\",\"\",\"t\",\"o\",\"\",\"s\",\"i\",\"m\",\"u\",\"l\",\"a\",\"t\",\"e\",\"\",\"c\",\"o\",\"n\",\"v\",\"e\",\"r\",\"s\",\"a\",\"t\",\"i\",\"o\",\"n\",\"\",\"a\",\"n\",\"d\",\"\",\"a\",\"n\",\"s\",\"w\",\"e\",\"r\",\"\",\"q\",\"u\",\"e\",\"s\",\"t\",\"i\",\"o\",\"n\",\"s\",\"\",\"t\",\"o\",\"\",\"t\",\"h\",\"e\",\"\",\"b\",\"e\",\"s\",\"t\",\"\",\"o\",\"f\",\"\",\"m\",\"y\",\"\",\"a\",\"b\",\"i\",\"l\",\"i\",\"t\",\"i\",\"e\",\"s\",\".\",\"\",\"I\",\"'\",\"m\",\"\",\"h\",\"e\",\"r\",\"e\",\"\",\"t\",\"o\",\"\",\"h\",\"e\",\"l\",\"p\",\"\",\"a\",\"n\",\"d\",\"\",\"c\",\"h\",\"a\",\"t\",\"\",\"w\",\"i\",\"t\",\"h\",\"\",\"y\",\"o\",\"u\",\",\",\"\",\"s\",\"o\",\"\",\"f\",\"e\",\"e\",\"l\",\"\",\"f\",\"r\",\"e\",\"e\",\"\",\"t\",\"o\",\"\",\"a\",\"s\",\"k\",\"\",\"m\",\"e\",\"\",\"a\",\"n\",\"y\",\"t\",\"h\",\"i\",\"n\",\"g\",\"!\"]}]}"
        print(str)
        -- local str = "{\"msglist\":[{\"name\":\"You\",\"streaming\":false,\"content\":[\"f\",\"u\"]},{\"name\":\"Puppy\",\"streaming\":true,\"content\":[\"啊\",\"啊\",\"啊\",\"\n\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"啊\",\"草\"]}]}"
        msg_received = json.decode(str)
        print(msg_received)
    end

    if pd.buttonJustPressed(pd.kButtonB) then
        reset_chat_render()
    end
end

----------------------------------------------

function exit_terminal()
    ---FIXME clean all icon
    chat_sprite:remove()
    tip_btn_sprite:remove()
    for key, value in pairs(icon_utils) do
        value.sprite:remove()
    end
end

function exit_puppy()
    battery_text_sprite:remove()
    time_sprite:remove()
    t_puppy_sprite:remove()
end

function enter_terminal()
    for key, value in pairs(icon_utils) do
        value.sprite:add()
    end
    chat_sprite:setCenter(0,0)
    chat_sprite:moveTo(0, 0)
    chat_sprite:add()
    tip_btn_sprite:setCenter(0,0)
    tip_btn_sprite:moveTo(0, screenHeight-30)
    tip_btn_sprite:add()
end

function enter_puppy()
    battery_text_sprite:add()
    battery_text_sprite:moveTo((screenWidth/2)+110, screenHeight/2)
    time_sprite:add()
    time_sprite:moveTo((screenWidth/2)+70, screenHeight/2)
    t_puppy_sprite:add()
    t_puppy_sprite:moveTo((screenWidth/2)+25, screenHeight/2)
    t_puppy_sprite:setRotation(90)
end

--------------------------------------------

function init()
    pd.display.setRefreshRate(30)

    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, screenWidth, screenHeight)

    icon_utils.no_signal.sprite:setCenter(0, 0)
    icon_utils.no_signal.sprite:moveTo(screenWidth-40, 8)
    icon_utils.loading.sprite:setCenter(0, 0)
    icon_utils.loading.sprite:moveTo(screenWidth-70, 8)

    puppy_communication = PuppyCommunication()

    enter_puppy()
end


function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()

    if pd.buttonIsPressed(pd.kButtonA) then
        if not pd.accelerometerIsRunning() then
            pd.startAccelerometer()
        end
        x,y,z = pd.readAccelerometer()
        if y > x_func(x) and y > x_ne_func(x) then
            stage_manager_choose = "terminal"
        elseif y < x_func(x) and y > x_ne_func(x) then
    
        elseif y < x_func(x) and y < x_ne_func(x) then
    
        elseif y > x_func(x) and y < x_ne_func(x) then
            stage_manager_choose = "puppy"
        end
    end

    if pd.buttonJustReleased(pd.kButtonA) then
        pd.stopAccelerometer()
        if stage_manager ~= stage_manager_choose then
            stage_manager = stage_manager_choose
            exit_puppy()
            exit_terminal()
            if stage_manager == "terminal" then
                enter_terminal()
            elseif stage_manager == "puppy" then
                enter_puppy()
            end
        end
    end

    STAGE[stage_manager]()
end

init()