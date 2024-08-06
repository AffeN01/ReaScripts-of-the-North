-- @description Force-enable/disable plugins on master bus during rendering
-- @author Nowu of the North
-- @link 
-- @version 1.0
-- @about
--   This script allows you to specify two lists of plugins: one to always enable during rendering,
--   and one to always disable. The original state of the plugins is restored after rendering.

-- Define the lists of plugins to force-enable/disable
local enablePlugins = {}
local disablePlugins = {}

-- Function to save plugin lists to file
local function savePluginLists()
  local file = io.open(reaper.GetResourcePath().. "/plugin_lists.txt", "w")
  if file then
    for i, plugin in ipairs(enablePlugins) do
      file:write("enable:".. plugin.. "\n")
    end
    for i, plugin in ipairs(disablePlugins) do
      file:write("disable:".. plugin.. "\n")
    end
    file:close()
  end
end

-- Function to load plugin lists from file
local function loadPluginLists()
  local file = io.open(reaper.GetResourcePath().. "/plugin_lists.txt", "r")
  if file then
    for line in file:lines() do
      local type, plugin = line:match("^(%w+):(.+)$")
      if type == "enable" then
        table.insert(enablePlugins, plugin)
      elseif type == "disable" then
        table.insert(disablePlugins, plugin)
      end
    end
    file:close()
  end
end

-- Load plugin lists from file
loadPluginLists()

-- Function to add plugins to enable/disable lists
local function addPlugins()
  local pluginNames = {}
  for i = 1, reaper.TrackFX_GetCount(reaper.GetMasterTrack(0)) do
    local fxName = reaper.TrackFX_GetFXName(reaper.GetMasterTrack(0), i - 1, "")
    table.insert(pluginNames, fxName)
  end

  local title = "Add Plugins to Lists"
  local columns = {
    {title = "Plugin", width = 200},
    {title = "Enable", width = 100},
    {title = "Disable", width = 100}
  }
  local data = {}
  for i, pluginName in ipairs(pluginNames) do
    local enable = false
    for j, enablePlugin in ipairs(enablePlugins) do
      if enablePlugin == pluginName then
        enable = true
        break
      end
    end
    local disable = false
    for j, disablePlugin in ipairs(disablePlugins) do
      if disablePlugin == pluginName then
        disable = true
        break
      end
    end
    table.insert(data, {pluginName, enable, disable})
  end

  local dialog = reaper.ShowConsoleMsg(title, columns, data)
  if dialog then
    for i, row in ipairs(dialog) do
      if row[2] then
        table.insert(enablePlugins, pluginNames[i])
      end
      if row[3] then
        table.insert(disablePlugins, pluginNames[i])
      end
    end
  end
end

-- Function to force-enable/disable plugins
local function forcePluginStates()
  for i = 1, reaper.TrackFX_GetCount(reaper.GetMasterTrack(0)) do
    local fxName = reaper.TrackFX_GetFXName(reaper.GetMasterTrack(0), i - 1, "")
    if table.contains(enablePlugins, fxName) then
      reaper.TrackFX_SetEnabled(reaper.GetMasterTrack(0), i - 1, true)
    elseif table.contains(disablePlugins, fxName) then
      reaper.TrackFX_SetEnabled(reaper.GetMasterTrack(0), i - 1, false)
    end
  end
end

-- Function to restore original plugin states
local function restoreOriginalStates()
  for i = 1, reaper.TrackFX_GetCount(reaper.GetMasterTrack(0)) do
    local fxName = reaper.TrackFX_GetFXName(reaper.GetMasterTrack(0), i - 1, "")
    local originalState = false
    for j, originalPlugin in ipairs(originalPlugins) do
      if originalPlugin == fxName then
        originalState = true
        break
      end
    end
    reaper.TrackFX_SetEnabled(reaper.GetMasterTrack(0), i - 1, originalState)
  end
end

-- Save the original state of the plugins
local originalPlugins = {}
for i = 1, reaper.TrackFX_GetCount(reaper.GetMasterTrack(0)) do
  local fxName = reaper.TrackFX_GetFXName(reaper.GetMasterTrack(0), i - 1, "")
  table.insert(originalPlugins, fxName)
end

-- Set up the rendering hook
reaper.SetRenderHook(function()
  forcePluginStates()
  reaper.defer(restoreOriginalStates)
end)

-- Create a command to add plugins to lists
reaper.main_OnCommand(40044, 0) -- 40044 is the ID of the "Custom: Add Plugins to Lists" command
function main()
  addPlugins()
end