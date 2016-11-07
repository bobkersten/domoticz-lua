commandArray = {}

package.path = package.path .. ';' .. '/home/bob/domoticz/scripts/lua/?.lua'

require "inc/functions"
require "inc/sqlite3"
require "inc/variables"

require "time_electra"
require "time_verwarming"
require "time_rolluiken"
require "time_verlichting"
require "time_ventilatie"
require "time_aanwezig"

return commandArray
