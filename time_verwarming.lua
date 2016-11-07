--[[
	    )
	 ( /(                )                   (
	 )\())   (     )  ( /( (          (  (   )\ )      (   (      (
	((_)\   ))\ ( /(  )\()))\   (     )\))( (()/(     ))\  )(    ))\
	 _((_) /((_))(_))(_))/((_)  )\ ) ((_))\  /(_))_  /((_)(()\  /((_)
	| || |(_)) ((_)_ | |_  (_) _(_/(  (()(_)(_)) __|(_))(  ((_)(_))(
	| __ |/ -_)/ _` ||  _| | || ' \))/ _` |   | (_ || || || '_|| || |
	|_||_|\___|\__,_| \__| |_||_||_| \__, |    \___| \_,_||_|   \_,_|
	                                 |___/

	DROP TABLE "Timer_Deltas";
	CREATE TABLE 'Timer_Deltas' (
		'Id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
		, 'DeviceRowId' BIGINT(10) NOT NULL
		, 'TimerId' INTEGER NOT NULL
		, 'TimerHash' VARCHAR(40) NOT NULL
		, 'TimerPlan' INTEGER NOT NULL
		, 'OutsideTemperature' INTEGER NOT NULL
		, 'PreHeat' INTEGER NOT NULL
		, 'Date' DATE NOT NULL
		, 'Start' TIME NOT NULL
		, 'StartTemperature' FLOAT NOT NULL
		, 'Offset' INTEGER DEFAULT NULL
		, 'StartDelay' INTEGER DEFAULT NULL
		, 'Stop' TIME DEFAULT NULL
		, 'StopTemperature' FLOAT DEFAULT NULL
		, 'Time' INTEGER DEFAULT NULL
		, 'Delta' FLOAT DEFAULT NULL
		, 'Debug' TEXT NOT NULL
	);
	CREATE INDEX DeviceRowID ON Timer_Deltas (DeviceRowId);
	CREATE INDEX TimerHash ON Timer_Deltas (TimerHash);
	CREATE INDEX TimerPlan ON Timer_Deltas (TimerPlan);
	CREATE INDEX Delta ON Timer_Deltas (Delta);
	CREATE INDEX Date ON Timer_Deltas (Date);
	CREATE INDEX Start ON Timer_Deltas (Start);
	CREATE INDEX Offset ON Timer_Deltas (Offset);
	CREATE INDEX OutsideTemperature ON Timer_Deltas (OutsideTemperature);
]]--
-- https://github.com/OpenPrograms/Kubuxu-Programs/blob/master/pid/pid.lua


---------------------------------------------------------------------------------------------------------------------------
-- Domoticz and Heating Database Locations
---------------------------------------------------------------------------------------------------------------------------
local sDatabaseDomoticz = '/home/bob/domoticz-data/domoticz.db'																-- The location of the domoticz database
local sDatabaseCustom = '/home/bob/domoticz-data/domoticz.custom.db'															-- The location of the custom database (where deltas are stored)
---------------------------------------------------------------------------------------------------------------------------
-- Domoticz Device Names & Variables
---------------------------------------------------------------------------------------------------------------------------
local aThermostatDeviceNames = { 'Woonkamer Thermostaat', 'Badkamer Thermostaat', 'Entree Thermostaat' }			-- An array with the names of the thermostat pseudo devices above
local aThermostatWeights = { 12, 4, 1 }																				-- The priorities for the thermostats
local aTemperatureDeviceNames = { 'Woonkamer Temperatuur', 'Badkamer Temperatuur', 'Entree Sensor Temperatuur' }	-- An array with temperature sensor names that correspond to the thermostats above
local aValvesDeviceNames = { 'Vloerverwarming Pomp Schakelaar', nil, nil }											-- An array with comma separated valve device names.
local aPreHeat = { true, true, false }																				-- Wether or not to pre-heat the zone
local sTemperatureOutsideDeviceName = 'Buiten Temperatuur'															-- The name of an outside temperature sensor
local sHeatingDeviceName = 'CV Aansturing'																			-- The name of the on/off heating device
local fMeasureDeltaMinimum = 0.3																					-- Minimum temperatature delta measured to determine pre-heat duration
local iHeaterMinimumDuration = 3.5																					-- Minimum duration in minutes the heater is off or off to prevent to excessive switching
local iValveMinimumDuration = 4.5																					-- Minimum duration in minutes the valves should not be updated
---------------------------------------------------------------------------------------------------------------------------

local sCurrentTime = string.format( "%02d", tostring( oDatetime.hour ) ) .. ':' .. string.format( "%02d", oDatetime.min )
local sCurrentDate = string.format( "%02d", tostring( oDatetime.year ) ) .. '-' .. string.format( "%02d", oDatetime.month ) .. '-' .. string.format( "%02d", oDatetime.day )
local iTemperatureOutside = round( tonumber( otherdevices_svalues[sTemperatureOutsideDeviceName]:match( "([^;]+)" ) ) )

local oHeating = { diff = 0, weights = 0, valves = { on = {}, off = {} } }
local aActiveTimers = {}
local aWeekDayBits = { 64, 1, 2, 4, 8, 16, 32 } -- 1 = sun = 64, 2 = mon = 1

-- If the heater was turned on or off recently, do not switch again if within xx minutes.
local sLastHeatingUpdate = otherdevices_lastupdate[sHeatingDeviceName]
if (
	sLastHeatingUpdate ~= nil
	and timeOffset( sLastHeatingUpdate ) / 60 < iHeaterMinimumDuration
) then
	log( 'Heater was recently turned ' .. otherdevices[sHeatingDeviceName] .. '.', sHeatingDeviceName )
	return commandArray
end

local mTimerPlan = executeQueryAndGetValues( sDatabaseDomoticz, [[
	SELECT `nValue`
	FROM `Preferences`
	WHERE `Key`="ActiveTimerPlan"
]] )
if ( not mTimerPlan ) then
	log( 'Unable to determine active timerplan.', sHeatingDeviceName )
	return commandArray
end

-- _________ .__                        ____ ___
-- \_   ___ \|  |   ____ _____    ____ |    |   \______
-- /    \  \/|  | _/ __ \\__  \  /    \|    |   /\____ \
-- \     \___|  |_\  ___/ / __ \|   |  \    |  / |  |_> >
--  \______  /____/\___  >____  /___|  /______/  |   __/
--         \/          \/     \/     \/          |__|

for iThermostatIndex = 1, #aThermostatDeviceNames do
	local iThermostatDeviceId = otherdevices_idx[aThermostatDeviceNames[iThermostatIndex]]

	-- Remove measurements that are way off. The measurements need to be more precise the older they get, or
	-- otherwise they will be removed. A weeks worth of measurements are always kept. This ensures that the
	-- very first measurement for a timer can be used for pre-heating, even if it's way off.
	-- TODO take into account how many measurements there actually are and do not remove if too little.
	executeQuery( sDatabaseCustom, [[
		DELETE FROM `Timer_Deltas`
		WHERE `DeviceRowID`=]] .. tostring( iThermostatDeviceId ) .. [[
		AND (
			(
				ABS(`Offset`) > 15
				AND `Date` NOT BETWEEN DATETIME("now", "-7 day") AND DATETIME("now")
			)
			OR (
				ABS(`Offset`) > 10
				AND `Date` NOT BETWEEN DATETIME("now", "-31 day") AND DATETIME("now")
			)
			OR (
				ABS(`Offset`) > 5
				AND `Date` NOT BETWEEN DATETIME("now", "-365 day") AND DATETIME("now")
			)
			OR (
				ABS(`Offset`) > 0
				AND `Date` NOT BETWEEN DATETIME("now", "-730 day") AND DATETIME("now")
			)
		)
	]] )
end

--	   _____                .__                .__
--	  /  _  \   ____ _____  |  | ___.__._______|__| ____    ____
--	 /  /_\  \ /    \\__  \ |  |<   |  |\___   /  |/    \  / ___\
--	/    |    \   |  \/ __ \|  |_\___  | /    /|  |   |  \/ /_/  >
--	\____|__  /___|  (____  /____/ ____|/_____ \__|___|  /\___  /
--	        \/     \/     \/     \/           \/       \//_____/

for iThermostatIndex = 1, #aThermostatDeviceNames do
	local iThermostatDeviceId = otherdevices_idx[aThermostatDeviceNames[iThermostatIndex]]
	local fThermostatSetPoint = tonumber( otherdevices_svalues[aThermostatDeviceNames[iThermostatIndex]] )
	local fTemperatureCurrent = tonumber( otherdevices_svalues[aTemperatureDeviceNames[iThermostatIndex]]:match( "([^;]+)" ) )

	-- Apparently one of the sensors give very high readings in some rare occasions. These need to
	-- be ignored because they mess up measuring and stuff.
	if ( fTemperatureCurrent < 30 ) then

		-- First we need to determine which setpoint should be currently active. Instead of just simply using
		-- the current setpoint, a future setpoint might also be active if heating should've started to reach
		-- the setponts temperature on time.
		local sUnions = [[
			SELECT DATETIME( DATE("now"), "-99 day" ) AS `Date`, ]] .. tostring( iThermostatDeviceId ) .. [[ AS `DeviceRowID`, 0 AS `ID`, 1 AS `Active`, 2 AS `Type`, ]] .. tostring( fTemperatureCurrent ) .. [[ AS `Temperature`, "00:00" AS `Time`, 0 AS `Days`, 0 AS `DayBits`
			UNION SELECT DATETIME( DATE("now"), "99 day" ) AS `Date`, ]] .. tostring( iThermostatDeviceId ) .. [[ AS `DeviceRowID`, 0 AS `ID`, 1 AS `Active`, 2 AS `Type`, ]] .. tostring( fTemperatureCurrent ) .. [[ AS `Temperature`, "23:59" AS `Time`, 0 AS `Days`, 0 AS `DayBits`
		]]
		for iDayOffset = -7, 7, 1 do
			local iWeekDay = 1 + ( ( oDatetime.wday + iDayOffset - 1 ) % 7 )
			local iDayBits = 128 + aWeekDayBits[iWeekDay] -- 128 = everyday
			if (
				iWeekDay == 1 -- sun
				or iWeekDay == 7 -- sat
			) then
				iDayBits = iDayBits + 512 -- weekend
			else
				iDayBits = iDayBits + 256 -- weekdays
			end
			-- NOTE: 30 seconds are added to the timers to make sure they're matched *after* the time matches the
			-- current time. This is done because Domoticz runs lua's first before processing timers, so the setpoint
			-- has not yet been updated when this script runs on the exact time of the timer.
			sUnions = sUnions .. [[
				UNION SELECT DATETIME( DATE("now") || " " || `Time`, "]] .. tostring( iDayOffset ) .. [[ day", "30 second" ) AS `Date`, `DeviceRowID`, `ID`, `Active`, `Type`, `Temperature`, `Time`, `Days`, ]] .. tostring( iDayBits ) .. [[ AS `DayBits`
				FROM `SetpointTimers`
				WHERE `DeviceRowID`=]] .. tostring( iThermostatDeviceId ) .. [[
				AND `Days` & ]] .. tostring( iDayBits ) .. [[ > 0
				AND `Active`=1
				AND `Type`=2
				AND `TimerPlan`=]] .. mTimerPlan .. [[
			]]
		end
		local sQuery = [[
			SELECT
				`Date` > DATETIME( DATE("now") || " ]] .. sCurrentTime .. [[" )
				, `ID`
				, `Temperature`
				, `Time`
				, 24 * 60 * ( JULIANDAY(`Date`) - JULIANDAY( DATETIME( DATE("now") || " ]] .. sCurrentTime .. [[" ) ) )
				, "]] .. tostring( iThermostatDeviceId ) .. [[/" || `ID` || "/" || `Time` || "/" || `Temperature` || "/" || `Days` || "/" || `DayBits` AS `Hash`
			FROM ( ]] .. sUnions .. [[ )
			ORDER BY `Date`
		]]
		local bSuccess, aTimers, iCount = executeQuery( sDatabaseDomoticz, sQuery )
		if ( bSuccess ) then

			local oCurrentTimer
			local oNextTimer

			for iTimerIndex = 1, iCount do
				if ( aTimers[iTimerIndex][1] == '1' ) then
					oNextTimer = { deviceid = iThermostatDeviceId, device = aThermostatDeviceNames[iThermostatIndex], timerid = tonumber( aTimers[iTimerIndex][2] ), setpoint = tonumber( aTimers[iTimerIndex][3] ), time = aTimers[iTimerIndex][4], minutes = round( tonumber( aTimers[iTimerIndex][5] ) ), hash = aTimers[iTimerIndex][6], temperature = fTemperatureCurrent, preheat = 0 }
					break
				end
				oCurrentTimer = { deviceid = iThermostatDeviceId, device = aThermostatDeviceNames[iThermostatIndex], timerid = tonumber( aTimers[iTimerIndex][2] ), setpoint = tonumber( aTimers[iTimerIndex][3] ), time = aTimers[iTimerIndex][4], minutes = round( tonumber( aTimers[iTimerIndex][5] ) ), hash = aTimers[iTimerIndex][6], temperature = fTemperatureCurrent, preheat = 0 }
			end

			log( 'The current timer started at ' .. oCurrentTimer.time .. ' (' .. tostring( math.abs( oCurrentTimer.minutes ) ) .. ' minutes ago) with setpoint ' .. tostring( oCurrentTimer.setpoint ) .. 'C.', oCurrentTimer.device )
			if ( oCurrentTimer.setpoint ~= fThermostatSetPoint ) then
				oCurrentTimer.setpoint = fThermostatSetPoint
				oCurrentTimer.hash = nil
				log( 'The current timer is manually overridden with temperature ' .. tostring( fThermostatSetPoint ) .. 'C.', oCurrentTimer.device )
			end
			log( 'The next timer will start at ' .. oNextTimer.time .. ' (in ' .. tostring( oNextTimer.minutes ) .. ' minutes) with setpoint ' .. tostring( oNextTimer.setpoint ) .. 'C.', oNextTimer.device )

			local oActiveTimer = oCurrentTimer

			-- Determine if there's an active measurement going on for the next timer. If so, the next timer
			-- should be the current timer because it was activated for pre-heating before. This prevents
			-- rare cases where heating would cause the pre-heat minutes to lower causing the script to switch
			-- back to the active timer instead of the next.
			local mTimerId = executeQueryAndGetValues( sDatabaseCustom, [[
				SELECT `TimerId`
				FROM `Timer_Deltas`
				WHERE `TimerHash`="]] .. oNextTimer.hash .. [["
				AND `TimerPlan`=]] .. mTimerPlan .. [[
				AND `Stop` IS NULL
				LIMIT 1
			]] )
			if ( mTimerId ) then
				oActiveTimer = oNextTimer
			elseif (
				aPreHeat[iThermostatIndex] == true
				and oActiveTimer.temperature < oNextTimer.setpoint
			) then
				local mDeltaAvg, sOffsetAvg, sTimerHash, sDeltaTemperatureOutside = executeQueryAndGetValues( sDatabaseCustom, [[
					SELECT AVG(`Delta` / `Time`), AVG( `Offset` ), `TimerHash`, `OutsideTemperature`
					FROM `Timer_Deltas`
					WHERE `DeviceRowID`=]] .. tostring( iThermostatDeviceId ) .. [[
					AND `TimerPlan`=]] .. mTimerPlan .. [[
					AND `Delta` IS NOT NULL
					AND `Time` IS NOT NULL
					AND ABS(`Offset`)<=15
					GROUP BY `TimerHash`, `OutsideTemperature`
					ORDER BY `TimerHash`="]] .. oNextTimer.hash .. [[" DESC, ABS(`OutsideTemperature` - ]] .. tostring( iTemperatureOutside ) .. [[) ASC
					LIMIT 1
				]] )
				if ( mDeltaAvg ) then
					local iPreheatMinutes = round( ( ( oNextTimer.setpoint - oActiveTimer.temperature ) / tonumber( mDeltaAvg ) ) + tonumber( sOffsetAvg ) )
					local sDebug = 'round( ( ( ' .. tostring( oNextTimer.setpoint ) .. ' - ' .. tostring( oActiveTimer.temperature ) .. ' ) / ' .. mDeltaAvg .. ' ) + ' .. sOffsetAvg .. ' )'
					log( 'Heating from ' .. tostring( oActiveTimer.temperature ) .. 'C to ' .. tostring( oNextTimer.setpoint ) .. 'C at ' .. oNextTimer.time .. ' with outside temp of ' .. tostring( iTemperatureOutside ) .. 'C requires ' .. tostring( iPreheatMinutes ) .. ' minutes pre-heating.', oNextTimer.device )
					if ( oNextTimer.minutes <= iPreheatMinutes ) then
						if ( sTimerHash ~= oNextTimer.hash ) then
							log( 'Using deltas from timer ' .. sTimerHash .. ' instead of timer ' .. oNextTimer.hash .. '.', oNextTimer.device )
						end
						if ( tonumber( sDeltaTemperatureOutside ) ~= iTemperatureOutside ) then
							log( 'Using deltas with outside temperature of ' .. sDeltaTemperatureOutside .. 'C instead of ' .. iTemperatureOutside .. 'C.', oNextTimer.device )
						end
						oActiveTimer = oNextTimer
						oActiveTimer.preheat = iPreheatMinutes
						oActiveTimer.delta_avg = mDeltaAvg
						oActiveTimer.offset_avg = sOffsetAvg
						oActiveTimer.debug = sDebug
					end
				end
			end

			-- To determine if an active timer should count towards the weighted diff we need to look at
			-- the minimum and maximum temperatures in the timers. We want to prevent a low temperture for
			-- a zone to bring down the diff, causing other zones to be too cold.
			local mMin, sMax = executeQueryAndGetValues( sDatabaseDomoticz, [[
				SELECT MIN(`Temperature`), MAX(`Temperature`)
				FROM `SetpointTimers`
				WHERE `DeviceRowID`=]] .. tostring( iThermostatDeviceId ) .. [[
				AND `Active`=1
				AND `Type`=2
				AND `TimerPlan`=]] .. mTimerPlan .. [[
			]] )
			if ( not ( mMin ) ) then -- there are no timers, just use the thermostat setpoint
				mMin = oActiveTimer.setpoint
				sMax = oActiveTimer.setpoint
			end
			oActiveTimer.min = tonumber( mMin )
			oActiveTimer.max = tonumber( sMax )
			oActiveTimer.avg = ( ( oActiveTimer.min + oActiveTimer.max ) / 2 )
			oActiveTimer.high = ( oActiveTimer.setpoint >= oActiveTimer.avg )
			oActiveTimer.low = ( oActiveTimer.setpoint < oActiveTimer.avg )
			oActiveTimer.diff = 0
			if (
				oActiveTimer.preheat == 0
				and oActiveTimer.high
				and otherdevices['Iemand Aanwezig'] == 'Off'
			) then
				oActiveTimer.setpoint = oActiveTimer.setpoint - 2
				log( "Setpoint is adjusted downwards because there's nobody home.", oActiveTimer.device )
			end
			if (
				oActiveTimer.high
				or (
					oActiveTimer.low
					and oActiveTimer.temperature < oActiveTimer.setpoint
				)
			) then
				local iWeight = aThermostatWeights[iThermostatIndex]
				oActiveTimer.diff = round( ( oActiveTimer.setpoint - oActiveTimer.temperature ) * iWeight, 2 )
				oHeating.diff = oHeating.diff + oActiveTimer.diff
				oHeating.weights = oHeating.weights + iWeight
				log( "Temperature is " .. tostring( oActiveTimer.temperature ) .. "C and should be " .. tostring( oActiveTimer.setpoint ) .. 'C causing an diff of ' .. tostring( oActiveTimer.diff ) .. '.', oActiveTimer.device )
			else
				log( "Temperature is " .. tostring( oActiveTimer.temperature ) .. "C and should be " .. tostring( oActiveTimer.setpoint ) .. 'C and is ignored.', oActiveTimer.device )
			end

			-- Opening or closing valves should help to reduce the weighted diff as soon as possible.
			if ( aValvesDeviceNames[iThermostatIndex] ) then
				for sValveDeviceName in string.gmatch( aValvesDeviceNames[iThermostatIndex], "([^,|]+)" ) do
					local sValveUpdate = otherdevices_lastupdate[sValveDeviceName]
					if (
						sValveUpdate ~= nil
						and timeOffset( sValveUpdate ) / 60 < iValveMinimumDuration
					) then
						log( 'Valve was recently turned ' .. otherdevices[sValveDeviceName] .. '.', sValveDeviceName )
					else
						if (
							oActiveTimer.setpoint > oActiveTimer.temperature
							and otherdevices[sValveDeviceName] == 'Off'
						) then
							oHeating.valves.on[#oHeating.valves.on + 1] = sValveDeviceName
						end
						if (
							oActiveTimer.setpoint <= oActiveTimer.temperature
							and otherdevices[sValveDeviceName] == 'On'
						) then
							oHeating.valves.off[#oHeating.valves.off + 1] = sValveDeviceName
						end
					end
				end
			end

			-- Store the active timer in the active timers array. These are used to later on start a new- or
			-- stop an active measurement for the zone.
			aActiveTimers[#aActiveTimers + 1] = oActiveTimer
		end
	end
end

--	   _____                                    .__
--	  /     \   ____ _____    ________ _________|__| ____    ____
--	 /  \ /  \_/ __ \\__  \  /  ___/  |  \_  __ \  |/    \  / ___\
--	/    Y    \  ___/ / __ \_\___ \|  |  /|  | \/  |   |  \/ /_/  >
--	\____|__  /\___  >____  /____  >____/ |__|  |__|___|  /\___  /
--	        \/     \/     \/     \/                     \//_____/

for iActiveTimerIndex = 1, #aActiveTimers do
	local oActiveTimer = aActiveTimers[iActiveTimerIndex]

	-- First we need to determine if a measurement is currently active. There can only be one timer active for each device id,
	-- so there can also only be one measurement active per device id.
	local mTimerId, sHash, sStartTemperature, sDuration, sStartDelay = executeQueryAndGetValues( sDatabaseCustom, [[
		SELECT `Id`, `TimerHash`, `StartTemperature`, ( ( JULIANDAY( DATE("now") || " ]] .. sCurrentTime .. [[" ) - JULIANDAY( DATE("now") || " " || `Start` ) ) * 24 * 60 ) AS `Duration`, COALESCE(`StartDelay`,-1)
		FROM `Timer_Deltas`
		WHERE `DeviceRowId`="]] .. oActiveTimer.deviceid .. [["
		AND `TimerPlan`=]] .. mTimerPlan .. [[
		AND `Stop` IS NULL
		LIMIT 1
	]] )

	-- Start a new measurement if none is active and the active timer zone is in need of heating. This
	-- is only done for timers with a high temperature setting.
	if (
		not( mTimerId )
		and oActiveTimer.high
		and oActiveTimer.diff > fMeasureDeltaMinimum
		and oActiveTimer.minutes > -5				-- do not measure when keeping a steady temperature (5 mins is a safe rounding margin)
		and oActiveTimer.hash ~= nil				-- do not measure when setpoint is manually overridden
		and oHeating.diff > 0						-- do not measure when heater is off due to other zone
	) then

		-- All variables are dumped in the debug column.
		local sDebug = '';
		for sKey, sValue in pairs( oActiveTimer ) do
			if ( string.len( sDebug ) > 0 ) then
				sDebug = sDebug .. '; '
			end
			sDebug = sDebug .. sKey .. '=' .. tostring( sValue )
		end

		executeQuery( sDatabaseCustom, [[
			INSERT INTO `Timer_Deltas` ( `DeviceRowId`, `TimerId`, `TimerHash`, `TimerPlan`, `OutsideTemperature`, `PreHeat`, `Date`, `Start`, `StartTemperature`, `Debug` )
			VALUES (
				]] .. tostring( oActiveTimer.deviceid ) .. [[,
				]] .. tostring( oActiveTimer.timerid ) .. [[,
				"]] .. oActiveTimer.hash .. [[",
				]] .. mTimerPlan .. [[,
				]] .. tostring( iTemperatureOutside ) .. [[,
				]] .. tostring( oActiveTimer.preheat ) .. [[,
				"]] .. sCurrentDate .. [[",
				"]] .. sCurrentTime .. [[",
				]] .. tostring( oActiveTimer.temperature ) .. [[,
				"]] .. sDebug .. [["
			)
		]] )
		log( 'New measurement started with start temperature ' .. tostring( oActiveTimer.temperature ) .. 'C.', oActiveTimer.device )
	end

	if ( mTimerId ) then

		-- If a new timer was started while measuring the previous timer, the measurement is invalid and needs
		-- to be removed.
		if ( sHash ~= oActiveTimer.hash ) then
			executeQuery( sDatabaseCustom, [[
				DELETE FROM `Timer_Deltas`
				WHERE `Id`=]] .. mTimerId .. [[
			]] )
		else
			local fStartTemperature = tonumber( sStartTemperature )
			local iDuration = round( tonumber( sDuration ) )
			local fDelta = round( oActiveTimer.temperature - fStartTemperature, 2 )

			-- We'd like to know how long it takes before the temperature increases after turning on the heater.
			if (
				tonumber( sStartDelay ) == -1			-- no startdelay recorded yet
				and fDelta > 0
			) then
				executeQuery( sDatabaseCustom, [[
					UPDATE `Timer_Deltas`
					SET `StartDelay`=]] .. tostring( iDuration ) .. [[
					WHERE `Id`=]] .. mTimerId .. [[
				]] )
				log( 'Measurement updated with startdelay ' .. tostring( iDuration ) .. ' at temperature ' .. tostring( oActiveTimer.temperature ) .. 'C.', oActiveTimer.device )
			end

			-- When the target temperature has been reached the measurement needs to be updated and closed.
			if (
				oActiveTimer.diff <= 0					-- valves are closed, so measurement will otherwise be inacurate
				or oHeating.diff <= 0					-- heater will be turned off, so measurement should stop
			) then
				if ( fDelta >= fMeasureDeltaMinimum ) then
					local iOffset
					executeQuery( sDatabaseCustom, [[
						UPDATE `Timer_Deltas`
						SET `Stop`="]] .. sCurrentTime .. [[",
						`StopTemperature`=]] .. tostring( oActiveTimer.temperature ) .. [[,
						`Offset`=CASE WHEN `PreHeat` > 0 THEN ]] .. tostring( -oActiveTimer.minutes ) .. [[ ELSE 0 END,
						`Time`=]] .. tostring( iDuration ) .. [[,
						`Delta`=]] .. tostring( fDelta ) .. [[
						WHERE `Id`=]] .. mTimerId .. [[
					]] )
					log( 'Measurement stopped with end temperature ' .. tostring( oActiveTimer.temperature ) .. 'C.', oActiveTimer.device )
				else
					executeQuery( sDatabaseCustom, [[
						DELETE FROM `Timer_Deltas`
						WHERE `Id`=]] .. mTimerId .. [[
					]] )
				end
			end
		end
	end
end

--	  ___ ___                 __  .__
--	 /   |   \   ____ _____ _/  |_|__| ____    ____
--	/    ~    \_/ __ \\__  \\   __\  |/    \  / ___\
--	\    Y    /\  ___/ / __ \|  | |  |   |  \/ /_/  >
--	 \___|_  /  \___  >____  /__| |__|___|  /\___  /
--	       \/       \/     \/             \//_____/

if (
	oHeating.diff > 0
	and otherdevices[sHeatingDeviceName] == 'Off'
) then
	addCommand( sHeatingDeviceName, 'On' )
	--log( 'Sending ON command to heating device.', sHeatingDeviceName, true )
end
if (
	oHeating.diff <= 0
	and otherdevices[sHeatingDeviceName] == 'On'
) then
	addCommand( sHeatingDeviceName, 'Off' )
	--log( 'Sending OFF command to heating device.', sHeatingDeviceName, true )
end

for iValveIndex = 1, #oHeating.valves.on do
	if ( otherdevices[oHeating.valves.on[iValveIndex]] ~= 'On' ) then
		addCommand( oHeating.valves.on[iValveIndex], 'On REPEAT 3 INTERVAL 5 SECONDS RANDOM 5' )
		log( 'Valve "' .. oHeating.valves.on[iValveIndex] .. '" is opened.' )
	end
end
for iValveIndex = 1, #oHeating.valves.off do
	if ( otherdevices[oHeating.valves.on[iValveIndex]] ~= 'Off' ) then
		addCommand( oHeating.valves.off[iValveIndex], 'Off REPEAT 3 INTERVAL 5 SECONDS RANDOM 5' )
		log( 'Valve "' .. oHeating.valves.off[iValveIndex] .. '" is closed.' )
	end
end
