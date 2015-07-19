--[[
	Version: 1.3
	Updated: July 16th, 2015
	Thread link: http://forum.botoflegends.com/topic/64983-library-improvedscriptconfig/
]]

_G.IMPROVED_SCRIPT_CONFIG_VERSION = 1.3

--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class("Ticker")

function Ticker:__init()
	self.Callbacks = {}
	self.CurrentID = 0

	AddTickCallback(function() self:OnTick() end)
end

--[[
	Returns unique ID of tick callback
]]
function Ticker:AddTickCallback(func)
	self.CurrentID = self.CurrentID + 1
	self.Callbacks[self.CurrentID] = func
	return self.CurrentID
end

function Ticker:RemoveTickCallback(ID)
	self.Callbacks[ID] = nil
end

function Ticker:OnTick()
	for i=1, self.CurrentID do
		local func = self.Callbacks[i]
		if func then
			func()
		end
	end
end

--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

local TICKER = Ticker()

function scriptConfig:clear(clearParams, clearSubMenus)
	assert(type(clearParams) == "boolean" and type(clearSubMenus) == "boolean", "ImprovedScriptConfig: wrong argument types (<boolean>, <boolean> expected)")

	if clearParams then
		local i = #self._param
		while i > 0 do
			local param = self._param[i]
			if param._callback then
				TICKER:RemoveTickCallback(param._callback.TickerID)
				param._callback = nil
			end
			table.remove(self._param, i)
			i = i - 1
		end
	end

	if clearSubMenus then
		for i, subMenu in ipairs(self._subInstances) do
			subMenu:clear(clearParams, clearSubMenus)
			subMenu._parent = nil
			table.remove(self._subInstances, self:getSubMenuIndex(subMenu.name))
		end
	end
end

--[[
	Returns whether a sub menu was found and if its header was changed
]]
function scriptConfig:modifySubMenuText(name, newHeader)
	assert(type(name) == "string" and type(newHeader) == "string", "ImprovedScriptConfig: wrong argument types (<string>, <string> expected)")

	local index = self:getSubMenuIndex(name)
	if index then
		self._subInstances[index].header = newHeader
		return true
	end
	return false
end

--[[
	Returns whether a sub menu was removed
]]
function scriptConfig:removeSubMenu(name)
	assert(type(name) == "string", "ImprovedScriptConfig: wrong argument types (<string> expected)")

	local subMenu = self[name]
	local subMenuName = self.name .. "_" .. name

	if not subMenu then 
		return false 
	end

	for i, data in ipairs(subMenu._param) do
		subMenu:removeParam(data.var)
	end

	subMenu._parent = nil

	table.remove(self._subInstances, self:getSubMenuIndex(subMenuName))

	subMenu = nil
	self[name] = nil
	return true
end

--[[
	Returns index of sub menu given name or nil
]]
function scriptConfig:getSubMenuIndex(name)
	assert(type(name) == "string", "ImprovedScriptConfig: wrong argument types (<string> expected)")

	local subMenuName = self.name .. "_" .. name

	for i, data in ipairs(self._subInstances) do
		if data.name == subMenuName then
			return i
		end
	end
end

--[[
	Adds a config parameter that the user can switch in between On/Off, KeyDown, and KeyToggle
	The 'key' parameter is not needed if the defaultType is SCRIPT_PARAM_ONOFF
]]
function scriptConfig:addDynamicParam(var, text, defaultType, defaultValue, key)
	assert(type(var) == "string" and type(text) == "string" and type(defaultType) == "number", "ImprovedScriptConfig: wrong argument types (<string>, <string>, <pType> expected)")
    assert(string.find(var, "[^%a%d]") == nil, "ImprovedScriptConfig: pVar should contain only char and number")
    assert(defaultType >= 1 and defaultType <= 3, "ImprovedScriptConfig: dynamic parameter should only be of parameter type ONOFF, ONKEYDOWN, or ONKEYTOGGLE")

    self:addParam(var, text, defaultType, defaultValue, key)

    if self:getParamIndex(var) then
    	local listVarName = var .. "TypeList"
    	self:addParam(listVarName, " -> Parameter mode:", SCRIPT_PARAM_LIST, defaultType, {"On/Off", "KeyDown", "KeyToggle"})
    	local listParamIndex = self:getParamIndex(listVarName)

    	if listParamIndex then
    		self:setCallback(listVarName, 
			function(value)
				self:modifyParam(var, "pType", value)
				if value > 1 then --KeyDown or KeyToggle
					self:modifyParam(var, "key", key or GetKey("L")) --Default key is 'L'
				end
			end)
    	end
    end
end

--[[
	Returns index of config parameter given name or nil
]]
function scriptConfig:getParamIndex(var)
	assert((type(var) == "string"), "ImprovedScriptConfig: expected <string>")

	for i, data in ipairs(self._param) do
		if data.var == var then
			return i
		end
	end
end

--[[
	Returns if a config parameter was modified
]]
function scriptConfig:modifyParam(var, key, value)
	assert((type(var) == "string") and (type(key) == "string"), "ImprovedScriptConfig: expected <string>, <string>)")

	local i = self:getParamIndex(var)
	if i then
		self._param[i][key] = value
		return true
	end
	return false
end

--[[
	Returns if a config parameter was removed
]]
function scriptConfig:removeParam(var)
	assert((type(var) == "string"), "ImprovedScriptConfig: expected <string>)")

	local i = self:getParamIndex(var)
	if i then
		self:removeCallback(var)
		table.remove(self._param, i)
		return true
	end
	return false
end

--[[
	Returns if callback was set
]]
function scriptConfig:setCallback(var, func)
	assert((type(var) == "string") and (type(func) == "function"), "ImprovedScriptConfig: expected <string>, <function>)")

	local paramIndex = self:getParamIndex(var)

	if paramIndex then
		local param = self._param[paramIndex]
		param._lastValue = self[var]
		param._callback = {["func"] = func, ["TickerID"] = TICKER:AddTickCallback(
			function()
				local currentVal = self[var]
				if currentVal ~= self._param[self:getParamIndex(var)]._lastValue then
					func(currentVal)
					self._param[self:getParamIndex(var)]._lastValue = currentVal
				end
			end
		)}
		return true
	end
	return false
end

--[[
	Returns if callback was remove
]]
function scriptConfig:removeCallback(var)
	assert((type(var) == "string"), "ImprovedScriptConfig: expected <string>)")

	local paramIndex = self:getParamIndex(var)

	if paramIndex then
		local param = self._param[paramIndex]

		if param._callback then
			TICKER:RemoveTickCallback(param._callback.TickerID)
			param._callback = nil
			return true
		end
	end
	return false
end