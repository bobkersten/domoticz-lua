commandArray = {}

package.path = package.path .. ';' .. '/var/domoticz/lua/?.lua'

require "inc/functions"
require "inc/sqlite3"
require "inc/variables"

require "device_deurbel"
require "device_alarm"
require "device_electra"
require "device_verlichting"
require "device_televisie"
require "device_ventilatie"

return commandArray
