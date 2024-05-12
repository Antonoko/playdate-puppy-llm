import './pdportal'
import 'ime'

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

local zh_ime = IME()
----------------------------------------------------

local LINEHEIGHT_FACTOR <const> = 1.4

local IMG_ABOUT <const> = gfx.image.new("img/about")
pd.setMenuImage(IMG_ABOUT)

local P_STAGE = {}
local p_stage_manager = "puppy"
local p_stage_manager_choose = "puppy"
local puppy_menu = playdate.getSystemMenu()

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
    AshevilleSans12LightOblique = {
        font = gfx.font.new('font/Asheville-Sans-12-Light-Oblique')
    },
}

local SFX = {
    selection = {
        sound = pd.sound.fileplayer.new("ime_src/sound/selection")
    },
    key = {
        sound = pd.sound.fileplayer.new("ime_src/sound/key")
    }
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
local chat_sprite_y_offset = 0
local chat_pointer = gfx.imagetable.new("img/pointer")
local chat_pointer_delay_cnt = 0
local chat_pointer_delay_times <const> = 0
local chat_user_input
local start_new_chat_trigger = false

local icon_utils = {
    no_signal = {
        sprite = gfx.sprite.new(gfx.image.new("img/icon-no-signal"))
    },
    loading = {
        sprite = gfx.sprite.new(gfx.image.new("img/icon-loading"))
    },
    error = {
        sprite = gfx.sprite.new(gfx.image.new("img/icon-error"))
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

local server_address = 'http://127.0.0.1:5001/llmproxy'

--------------------------------------------------------------------------------------

-- Get a value from a table if it exists or return a default value
local get_or_default = function (table, key, expectedType, default)
	local value = table[key]
	if value == nil then
		return default
	else
		if type(value) ~= expectedType then
			print("Warning: value for key " .. key .. " is type " .. type(value) .. " but expected type " .. expectedType)
			return default
		end
		return value
	end
end

-- Save the state of the game to the datastore
function save_state()
	print("Saving state...")
	local state = {}
    state["server_address"] = server_address

	playdate.datastore.write(state)
	print("State saved!")
end


-- Load the state of the game from the datastore
function load_state()
	print("Loading state...")
	local state = playdate.datastore.read()
	if state == nil then
		print("No state found, using defaults")
        state = {}
	else
		print("State found!")
	end

    server_address = get_or_default(state, "server_address", "string", "http://127.0.0.1:5001/llmproxy")
end


function puppy_sidebar_option()
    puppy_menu:removeAllMenuItems()
    local modeMenuItem, error = puppy_menu:addMenuItem("edit address", function(value)
        p_stage_manager = "edit_server_address"
        zh_ime:startRunning("Edit Server Address", "en", stringToTable(server_address), "num")
    end)
end

--------------------------------------------------------------------------------------

local PdPortal <const> = PdPortal
local PortalCommand <const> = PdPortal.PortalCommand
local chat_dialog_table = {}
local msg_received, msg_received_lazy
local state_wait_respond = false

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
    self:log("get_llm_response", msg_send)
    self:_createObject(json.encode({
        name = 'llm-fetch',
        data = {
            msg = msg_send,
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
            icon_utils.error.sprite:remove()
            --fetching
		else
            icon_utils.no_signal.sprite:remove()
            icon_utils.loading.sprite:remove()
            icon_utils.error.sprite:remove()
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
    if msg_received == nil then
        msg_received = {
            usermsg = {
                "Received failed."
            },
            llmmsg = {
                responseText
            }
        }
    end

    local llm_chat_table = {
        name = "Puppy",
        streaming = true,
        content = msg_received["llmmsg"]
    }
    table.insert(chat_dialog_table, llm_chat_table)
    for key, char in pairs(chat_dialog_table) do
        chat_dialog_table[key]["streaming"] = false
    end
    chat_dialog_table[#chat_dialog_table]["streaming"] = true
    state_wait_respond = false
    reset_chat_render()
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
    -- self:deliver_msg("{\"msglist\":[{\"name\":\"System\",\"streaming\":false,\"content\":[\"error:\",\""..errorMessage.."\"]}]}")
    icon_utils.error.sprite:add()
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

function findNextSpaceIndex(tbl, index)
    if index >= #tbl then
        return -1
    end
    for i = index + 1, #tbl do
        if tbl[i] == " " then
            if i > 12 then
                return -1
            else
                return i
            end
        end
    end
    return -1
end

function stringToTable(s)
    local t = {}
    for i = 1, #s do
        t[i] = s:sub(i, i)
    end
    return t
end


--------------------------------------------

function reset_dialog()
    chat_dialog_table = {
        {
            name = "Puppy",
            streaming = false,
            content = {
                "Hi, nice to see you!"
            }
        }
    }
end

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
    for key, section in pairs(response_json) do
        gfx.setFont(FONT["AshevilleSans12LightOblique"].font)
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
                if char == " " then  --word break
                    local next_space_index = findNextSpaceIndex(section.content, key)
                    local word_width = 0
                    if next_space_index > 1 and next_space_index > key then
                        for i = key+1, next_space_index do
                            word_width += gfx.getTextSize(section.content[i])
                        end
                        if current_x + word_width > 320 - max_zh_char_size then
                            current_x = img_chat_draw_coord_x_offset
                            height += lineheight
                        end
                    end
                end
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

    if height < screenHeight - 30 then
        height = screenHeight
    end
    img_chat_buffer = gfx.image.new(screenWidth, height)
end

function render_chat(response_json)
    function _render_name(name, x, y)
        gfx.setFont(FONT["AshevilleSans12LightOblique"].font)
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
                if char == " " then  --word break
                    local next_space_index = findNextSpaceIndex(content, key)
                    local word_width = 0
                    if next_space_index > 1 and next_space_index > key then
                        for i = key+1, next_space_index do
                            word_width += gfx.getTextSize(content[i])
                        end
                        if current_x + word_width > 320 - max_zh_char_size + img_chat_draw_coord_x_offset then
                            current_x = x
                            y_offset_callback += lineheight
                        end
                    end
                end
                
                gfx.drawTextAligned(char, current_x, y_offset_callback+y, kTextAlignment.left)
                current_x += gfx.getTextSize(char)
            end
            
            if current_x > 320 - max_zh_char_size + img_chat_draw_coord_x_offset then
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
        for key, section in pairs(response_json) do
            _render_name(section.name, img_chat_draw_coord_x + img_chat_draw_coord_x_offset, img_chat_draw_coord_y)
            if string.lower(section.name) == "puppy" then
                _render_puppy_avatar(8, img_chat_draw_coord_y-8)
            end
            gfx.setFont(FONT["AshevilleSans12LightOblique"].font)
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
            if char == " " then  --word break
                local next_space_index = findNextSpaceIndex(content, img_chat_streaming_text_char_index)
                local word_width = 0
                if next_space_index > 1 and next_space_index > img_chat_streaming_text_char_index then
                    for i = img_chat_streaming_text_char_index+1, next_space_index do
                        word_width += gfx.getTextSize(content[i])
                    end
                    if img_chat_streaming_text_x + word_width > 320 - max_zh_char_size then
                        img_chat_streaming_text_x = 0
                        img_chat_streaming_text_y += lineheight
                    end
                end
            end

            gfx.setImageDrawMode(playdate.graphics.kDrawModeCopy)
            chat_pointer:drawImage(1, img_chat_streaming_text_x + img_chat_draw_coord_x_offset + gfx.getTextSize(char), img_chat_streaming_text_y)
            gfx.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
            gfx.drawTextAligned(char, img_chat_streaming_text_x + img_chat_draw_coord_x_offset, img_chat_streaming_text_y, kTextAlignment.left)
            img_chat_streaming_text_x += gfx.getTextSize(char)
            SFX.key.sound:play()
        end
        
        img_chat_streaming_text_x_last = img_chat_streaming_text_x
        img_chat_streaming_text_y_last = img_chat_streaming_text_y

        if img_chat_streaming_text_x > 320 - max_zh_char_size then
            img_chat_streaming_text_x = 0
            img_chat_streaming_text_y += lineheight
        end

        if img_chat_streaming_text_y_last > screenHeight - 60 then
            chat_sprite:moveTo(0, -(img_chat_streaming_text_y_last-screenHeight)-60)
            chat_sprite_y_offset = -(img_chat_streaming_text_y_last-screenHeight)-60
        end
    end

    gfx.pushContext(img_chat_buffer)
        for key, section in pairs(response_json) do
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
        render_chat_stream_part(response_json)
    end
end

function reset_chat_render()
    history_chat_render_done = false
    streaming_chat_render_done = false
    img_chat_buffer = gfx.image.new(400, 240)
    chat_sprite:setImage(img_chat_buffer)
    img_chat_draw_coord_x_offset = 60
    img_chat_draw_coord_x = 0
    img_chat_draw_coord_y = 0
    img_chat_streaming_text_char_index = 1
    img_chat_streaming_text_x = 0
    img_chat_streaming_text_y = 0
    img_chat_streaming_text_x_last = 0
    img_chat_streaming_text_y_last = 0
end

function scroll_chat()
    local change, acceleratedChange = playdate.getCrankChange()
    local buffer_img_width, buffer_img_height = img_chat_buffer:getSize()
    if change ~= 0 then
        chat_sprite_y_offset += -change
        if chat_sprite_y_offset < -(buffer_img_height - 150) then
            chat_sprite_y_offset = -(buffer_img_height - 150)
        elseif chat_sprite_y_offset > 5 then
            chat_sprite_y_offset = 5
        end
        chat_sprite:moveTo(chat_sprite.x, chat_sprite_y_offset)
    end
end


--------------------------------------------

P_STAGE["puppy"] = function()
    t_puppy_sprite:setImage(t_puppy_animation:image())
    render_time()
    render_battery()
    switch_rotation_mode()
end


P_STAGE["terminal"] = function()
    switch_rotation_mode()
    puppy_communication:update()
    scroll_chat()
    

    if chat_dialog_table ~= nil and #chat_dialog_table ~= 0 and state_wait_respond == false then
        update_chat_render(chat_dialog_table)
    end

    if pd.buttonJustPressed(pd.kButtonA) and not state_wait_respond and p_stage_manager == "terminal" then
        p_stage_manager = "terminal_input"
        zh_ime:startRunning("Chat to Puppy", "en", {}, "en")
        exit_terminal()

        -- puppy_communication:get_llm_response("hello i am sad", false)
        -- state_wait_respond = true
        -- local debug:
        -- local str = "{\"msglist\":[{\"name\":\"System\",\"streaming\":false,\"content\":[\"error.\"]}]}"
        -- msg_received = json.decode(str)
    end

    if pd.buttonJustPressed(pd.kButtonB) and p_stage_manager == "terminal" then
        state_wait_respond = false
        start_new_chat_trigger = true
        reset_dialog()
        reset_chat_render()
    end
end

P_STAGE["terminal_input"] = function()
    if zh_ime:isRunning() then
        chat_user_input = zh_ime:update()
    else
        if not zh_ime:isUserDiscard() and #chat_user_input > 0 then
            puppy_communication:get_llm_response(table.concat(chat_user_input, ""), start_new_chat_trigger)
            local user_chat_table_temp = {
                name = "You",
                streaming = false,
                content = chat_user_input
            }
            table.insert(chat_dialog_table, user_chat_table_temp)
            for key, char in pairs(chat_dialog_table) do
                chat_dialog_table[key]["streaming"] = false
            end
            reset_chat_render()
            update_chat_render(chat_dialog_table)
            
            start_new_chat_trigger = false
            state_wait_respond = true
        end
        p_stage_manager = "terminal"
        enter_terminal()
    end
end

P_STAGE["edit_server_address"] = function()
    if zh_ime:isRunning() then
        chat_user_input = zh_ime:update()
    else
        if not zh_ime:isUserDiscard() and #chat_user_input > 0 then
            server_address = table.concat(chat_user_input, "")
            save_state()
        end
        p_stage_manager = "terminal"
        enter_terminal()
    end
end

----------------------------------------------

function exit_terminal()
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
    puppy_sidebar_option()
    chat_sprite:setCenter(0,0)
    chat_sprite:moveTo(0, 5)
    chat_sprite:add()
    tip_btn_sprite:setCenter(0,0)
    tip_btn_sprite:moveTo(0, screenHeight-30)
    tip_btn_sprite:add()

    local icon_offset_x = 0
    for key, value in pairs(icon_utils) do
        value.sprite:setCenter(0, 0)
        value.sprite:moveTo(screenWidth-40-icon_offset_x, 8)
        icon_offset_x += 30
        -- value.sprite:add()
    end
end

function enter_puppy()
    puppy_sidebar_option()
    battery_text_sprite:add()
    battery_text_sprite:moveTo((screenWidth/2)+110, screenHeight/2)
    time_sprite:add()
    time_sprite:moveTo((screenWidth/2)+70, screenHeight/2)
    t_puppy_sprite:add()
    t_puppy_sprite:moveTo((screenWidth/2)+25, screenHeight/2)
    t_puppy_sprite:setRotation(90)
end

function switch_rotation_mode()
    if pd.buttonIsPressed(pd.kButtonDown) then
        if not pd.accelerometerIsRunning() then
            pd.startAccelerometer()
        end
        x,y,z = pd.readAccelerometer()
        if y > x_func(x) and y > x_ne_func(x) then
            p_stage_manager_choose = "terminal"
        elseif y < x_func(x) and y > x_ne_func(x) then
    
        elseif y < x_func(x) and y < x_ne_func(x) then
    
        elseif y > x_func(x) and y < x_ne_func(x) then
            p_stage_manager_choose = "puppy"
        end

        if p_stage_manager ~= p_stage_manager_choose then
            p_stage_manager = p_stage_manager_choose
            if p_stage_manager == "terminal" then
                exit_puppy()
                enter_terminal()
            elseif p_stage_manager == "puppy" then
                exit_terminal()
                enter_puppy()
            end
        end
    end

    if pd.buttonJustReleased(pd.kButtonDown) then
        pd.stopAccelerometer()
    end
end

--------------------------------------------

function init()
    pd.display.setRefreshRate(30)
    load_state()

    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, 0, screenWidth, screenHeight)

    puppy_communication = PuppyCommunication()
    reset_dialog()

    enter_puppy()
end


function debug()

end


function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()

    P_STAGE[p_stage_manager]()
end

init()