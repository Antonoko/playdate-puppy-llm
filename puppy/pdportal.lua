import 'CoreLibs/object'
import 'CoreLibs/timer'
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- The PdPortal class is used to communicate from the Playdate back to the
-- browser (and other Playdates). Typically, you'll subclass this
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

class('PdPortal').extends()
local PdPortal <const> = PdPortal

local jsonEncode <const> = json.encode
local jsonDecode <const> = json.decode
local timer <const> = playdate.timer

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- These functions should be implemented by each app, and will be called by the
-- pdportal web app as appropriate.
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

--- Called by pdportal web app after serial connection established. Example
--  handler: Update UI to show that the serial connection was successful.
function PdPortal:onConnect(portalVersion)
	--
end

--- Called by Lua code when serial keepalive fails. Example
--  handler: Update UI to show that the serial has been disconnected.
function PdPortal:onDisconnect()
	--
end

--- Peer connection established, remote peer connection possible. Example
--  handler: Update UI to show this Playdate's peer ID. Other users can enter
--  the ID to connect.
-- @see https://peerjs.com/docs/#peeron-open
function PdPortal:onPeerOpen(peerId)
	--
end

--- Peer connection destroyed, remote peer connection no longer possible.
--  Example handler: Update UI to show that peer connection is no longer
--  possible. Prompt user to reconnect?
-- @see https://peerjs.com/docs/#peeron-close
function PdPortal:onPeerClose()
	--
end

--- A remote peer has connected to us via the peer server. The given
--  `remotePeerId` can be used to send data to this peer with
--  `PdPortal.PortalCommand.SendToPeerConn`. Example handler: Start game!
-- @see https://peerjs.com/docs/#peeron-connection
function PdPortal:onPeerConnection(remotePeerId)
	--
end

-- We've connected to a remote peer via the peer server. The given
-- `remotePeerId` can be used to send data to this peer with
-- `PdPortal.PortalCommand.SendToPeerConn`. Example handler: Start game!
-- @see https://peerjs.com/docs/#dataconnection-on-open
function PdPortal:onPeerConnOpen(remotePeerId)
	--
end

-- Connection to a remote peer has been lost. Example handler: End game.
-- @see https://peerjs.com/docs/#dataconnection-on-close
function PdPortal:onPeerConnClose(remotePeerId)
	--
end

--- We've received data from a remote peer. Example handler: Read `payload` and
-- act appropriately based on the `remotePeerId` and current app state. Note
-- that `payload` is JSON-encoded, so you probably want to
-- `local decodedPayload = json.decode(payload)` before use.
-- @see https://peerjs.com/docs/#dataconnection-on-data
-- @see https://sdk.play.date/inside-playdate#M-json
function PdPortal:onPeerConnData(remotePeerId, payload)
	--
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Use these methods to communicate with the pdportal web app and/or other
-- connected Playdates.
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

--- Commands Playdate can send to the pdportal website
PdPortal.PortalCommand = {
	--- Log the given arguments to the browser console
	Log = 'l',
	--- Keepalive command, automatically sent by the Lua side of pdportal
	Keepalive = 'k',
	--  Tell pdportal to initialize connection to the peer server for
	-- communicating with another Playdate. Not required for `fetch`.
	InitializePeer = 'ip',
	-- Tell pdportal to disconnect from the peer server.
	DestroyPeer = 'dp',
	--- Takes two strings, the destination peer ID, and a JSON string. Sends the
	-- JSON to that peer.
	SendToPeerConn = 'p',
	--- Takes one string, the peer ID to close the connection to.
	ClosePeerConn = 'cpc',
	--- HTTP fetch
	Fetch = 'f',
}

--- Send the given PortalCommand and arguments to the pdportal site e.g.
-- `portalInstance:sendCommand(PdPortal.PortalCommand.Log, 'hello', 'world!')`
-- will log those two strings to the browser console.
function PdPortal:sendCommand(portalCommand, ...)
	local cmd = {portalCommand}

	for i = 1, select('#', ...) do
		local arg = select(i, ...)
		table.insert(cmd, PdPortal.portalArgumentSeparator)
		table.insert(cmd, arg)
	end

	table.insert(cmd, PdPortal.portalCommandSeparator)

	print(table.concat(cmd, ''))
end

--- Convenience method instead of calling
--  `:sendCommand(PdPortal.PortalCommand.Log, 'hello', 'world')`
function PdPortal:log(...)
	self:sendCommand(
		PdPortal.PortalCommand.Log,
		table.unpack({...})
	)
end

--- Convenience method instead of calling
--  `:sendCommand(PdPortal.PortalCommand.SendToPeerConn, peerConnId, encodedPayload)`
function PdPortal:sendToPeerConn(peerConnId, payload)
	local jsonPayload = jsonEncode(payload)
	self:sendCommand(
		PdPortal.PortalCommand.SendToPeerConn,
		peerConnId,
		jsonPayload
	)
end

--- Send an HTTP request using `fetch`.
-- @see https://developer.mozilla.org/en-US/docs/Web/API/fetch
function PdPortal:fetch(url, options, successCallback, errorCallback)
	local encodedOptions = jsonEncode(options)
	local requestId = tostring(self._nextRequestId)
	self._nextRequestId += 1

	self._fetchCallbacks[requestId] = {successCallback, errorCallback}

	self:sendCommand(PdPortal.PortalCommand.Fetch, requestId, url, encodedOptions)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Most apps should _not_ need to use, override, or change things below here.
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

--- Things the pdportal site can tell Playdate to do
PdPortal.PlaydateCommand = {
	OnConnect = 'oc',
	OnPeerConnData = 'opcd',
	OnPeerOpen = 'opo',
	OnPeerClose = 'opc',
	OnPeerConnection = 'opconn',
	OnPeerConnOpen = 'opco',
	OnPeerConnClose = 'opcc',
	Keepalive = 'k',
	OnFetchSuccess = 'ofs',
	OnFetchError = 'ofe',
}

--- Map of PlaydateCommands to method names that should be called
PdPortal.playdateCommandMethods = {
	[PdPortal.PlaydateCommand.OnConnect] = {'_onConnect', 'onConnect'},
	[PdPortal.PlaydateCommand.OnPeerConnData] = {'onPeerConnData'},
	[PdPortal.PlaydateCommand.OnPeerOpen] = {'onPeerOpen'},
	[PdPortal.PlaydateCommand.OnPeerClose] = {'onPeerClose'},
	[PdPortal.PlaydateCommand.OnPeerConnection] = {'onPeerConnection'},
	[PdPortal.PlaydateCommand.OnPeerConnOpen] = {'onPeerConnOpen'},
	[PdPortal.PlaydateCommand.OnPeerConnClose] = {'onPeerConnClose'},
	[PdPortal.PlaydateCommand.Keepalive] = {'_onKeepalive'},
	[PdPortal.PlaydateCommand.OnFetchSuccess] = {'_onFetchSuccess'},
	[PdPortal.PlaydateCommand.OnFetchError] = {'_onFetchError'},
}

--- Sent from Playdate to serial host at the end of each command
PdPortal.portalCommandSeparator = string.char(30) -- RS (␞)
--- Sent from Playdate to serial host between commands and their arguments, and each argument
PdPortal.portalArgumentSeparator = string.char(31) -- US (␟)

--- Sent from serial host to Playdate at the end of each command.
PdPortal.playdateCommandSeparator = '~|~'
PdPortal.playdateCommandPattern = PdPortal.playdateCommandSeparator .. "()"
--- Sent from serial host to Playdate between commands and their arguments, and each argument
PdPortal.playdateArgumentSeparator = '~,~'
PdPortal.playdateArgumentPattern = '(.-)' .. PdPortal.playdateArgumentSeparator .. "()"

-- Partial commands can be sent from serial host to PD due to `msg` length limit. Add to this buffer until a complete command has been received (playdateCommandSeparator)
PdPortal.incomingCommandBuffer = ''


--- The PdPortal class (and by extension, your subclass) should be treated as a
-- singleton. On init, it sets the system `playdate.serialMessageReceived`
-- callback to its own method, replacing any existing handler.
-- @see https://sdk.play.date/2.4.1/Inside%20Playdate.html#c-serialMessageReceived
function PdPortal:init()
	playdate.serialMessageReceived = function (msg)
		self:_onSerialMessageReceived(msg)
	end

	self.serialKeepaliveTimer = nil

	self._fetchCallbacks = {}
	self._nextRequestId = 1
end

function PdPortal:update()
	-- Required for serial keepalive
	timer.updateTimers()
end

--- Handle input from the `msg` serial command, and distribute appropriately
function PdPortal:_onSerialMessageReceived(msgString)

	-- Convert `~n~` back to actual `\n` newlines
	msgString = msgString:gsub('~n~', '\n')

	local completeCommandStrings, trailingCommand = PdPortal._splitCommandBuffer(
		PdPortal.incomingCommandBuffer .. msgString,
		PdPortal.playdateCommandPattern
	)

	PdPortal.incomingCommandBuffer = trailingCommand

	for _i, commandString in ipairs(completeCommandStrings) do
		local cmdArgs = PdPortal._splitString(commandString, PdPortal.playdateArgumentPattern)

		local methodsToCall = PdPortal.playdateCommandMethods[cmdArgs[1]]

		if methodsToCall == nil then
			self:log('Unknown command received', cmdArgs[1], msgString, string.len(msgString))
			return
		end

		for i, methodName in ipairs(methodsToCall) do
			self[methodName](self, table.unpack(cmdArgs, 2))
		end
	end
end

function PdPortal:_onConnect()
	self:_onKeepalive()
end

--- Called by self on connect, then automatically re-triggered by responses from
--  pdportal. This is required so the Playdate can know when it loses connection
--  with the portal.
function PdPortal:_onKeepalive()
	-- We've received a keepalive message, cancel the keepalive timer. We live for
	-- at least another few hundred milliseconds.
	if self.serialKeepaliveTimer ~= nil then
		self.serialKeepaliveTimer:pause()
		self.serialKeepaliveTimer:remove()
		self.serialKeepaliveTimer = nil
	end

	-- Schedule another keepalive cycle in 500ms
	timer.performAfterDelay(500, function ()
		-- If pdportal doesn't respond within 100ms, disconnect
		self.serialKeepaliveTimer = playdate.timer.new(100, function ()
			self:onDisconnect()
		end)
		self:sendCommand(PdPortal.PortalCommand.Keepalive)
	end)
end

function PdPortal:_onFetchSuccess(requestId, responseText, responseDetails)
	local callbacks = self._fetchCallbacks[requestId]

	if callbacks == nil then
		self:log('Success, but no callbacks found for request ID', requestId)
		return
	end

	callbacks[1](responseText, jsonDecode(responseDetails))

	self._fetchCallbacks[requestId] = nil
end

function PdPortal:_onFetchError(requestId, errorDetails)
	local callbacks = self._fetchCallbacks[requestId]

	if callbacks == nil then
		self:log('Error, but no callbacks found for request ID', requestId)
		return
	end

	callbacks[2](jsonDecode(errorDetails))

	self._fetchCallbacks[requestId] = nil
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Utility functions
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

--- Splits a string on the given pattern. Returns a table of complete commands, and a string with any trailing incomplete command info
PdPortal._splitCommandBuffer = function(cmdBufferString, pattern)
	local completeCommands = {}
	local start = 1
	local first, last = string.find(cmdBufferString, pattern, start)
	local trailingCommand = cmdBufferString

	while first do
		local command = string.sub(cmdBufferString, start, first - 1)
		if command ~= "" then
			table.insert(completeCommands, command)
		end
		start = last + 1
		first, last = string.find(cmdBufferString, pattern, start)
	end

	if start <= string.len(cmdBufferString) then
		trailingCommand = string.sub(cmdBufferString, start)
	else
		trailingCommand = ""
	end

	return completeCommands, trailingCommand
end

PdPortal._splitString = function(inputStr, pattern)
	local result = {}
	local lastEnd = 1

	for part, endPos in string.gmatch(inputStr, pattern) do
		table.insert(result, part)
		lastEnd = endPos
	end

	-- Add the last part if there is any
	if lastEnd <= #inputStr then
		table.insert(result, string.sub(inputStr, lastEnd))
	end

	return result
end
