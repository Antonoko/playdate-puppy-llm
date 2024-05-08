-- Copied during build, you wouldn't normally have to do that
import './pdportal'

import 'CoreLibs/graphics'

import 'Example04Fetch'

local app = Example04Fetch()

playdate.update = function()
	app:update()
end
