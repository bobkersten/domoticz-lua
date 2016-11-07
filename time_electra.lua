---------------------------------------------------------------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------------------------------------------------------------
local aSuccessPrefix = { 'Yahooooooo!!', 'Goed nieuws.', 'Tadaaaa.', 'Hoppakee dan!', 'Yesssss.', 'Lekker weertje, of niet?', 'BAM!' }
local aAlmostSuccessPrefix = { 'Oeeeej bijna.', 'Dat scheelt niet veel.', 'Kak. Net niet.', 'Niet slecht.', 'Toch een van de betere dagen.', 'Bijna.' }
local aFailurePrefix = { 'Sjonge jonge jonge.', 'Wat een butt-weer.', 'Nou nou.', 'Tja.', 'Poe poe poe.', 'Diepe zucht.', 'Sjonge zeg.', 'Gaaaaaaaaaaaaaaap.' }
local sDatabaseDomoticz = '/home/bob/domoticz-data/domoticz.db'
local sZonnepanelenDeviceName = 'Zonnepanelen'
local sEigenVerbruikDeviceName = 'Eigen Verbruik'
---------------------------------------------------------------------------------------------------------------------------

local iZonnepanelenDeviceId = otherdevices_idx[sZonnepanelenDeviceName]
local iEigenVerbruikDeviceId = otherdevices_idx[sEigenVerbruikDeviceName]

local oZonnepanelenWaardes = splitkWhValues( otherdevices_svalues[sZonnepanelenDeviceName] )
local oVerbruikTotaalWaardes = splitkWhValues( otherdevices_svalues[sEigenVerbruikDeviceName] )

-- Vraag de benodigde gegevens op uit de Domoticz database.
local sZonnepanelenCounter = executeQueryAndGetValues( sDatabaseDomoticz, [[
	SELECT `Counter`
	FROM `Meter_Calendar`
	WHERE `DeviceRowId`=]] .. iZonnepanelenDeviceId .. [[
	ORDER BY `Date` DESC
	LIMIT 1
]] )
local sZonnepanelenValueMax = executeQueryAndGetValues( sDatabaseDomoticz, [[
	SELECT MAX(`Value`)
	FROM `Meter_Calendar`
	WHERE `DeviceRowId`=]] .. iZonnepanelenDeviceId .. [[
]] )
local sZonnepanelenValueMonthMax, sZonnepanelenValueMonthAverage, sZonnepanelenValueMonthMin = executeQueryAndGetValues( sDatabaseDomoticz, [[
	SELECT MAX(`Value`), ROUND(AVG(`Value`),3), MIN(`Value`)
	FROM `Meter_Calendar`
	WHERE `DeviceRowId`=]] .. iZonnepanelenDeviceId .. [[
	AND strftime( "%m", `Date` )="]] .. oDatetime.smonth .. [["
	GROUP BY `DeviceRowId`
]] )
local sZonnepanelenValueMonthMaxThisYear = executeQueryAndGetValues( sDatabaseDomoticz, [[
	SELECT MAX(`Value`)
	FROM `Meter_Calendar`
	WHERE `DeviceRowId`=]] .. iZonnepanelenDeviceId .. [[
	AND strftime( "%m", `Date` )="]] .. oDatetime.month .. [["
	AND strftime( "%Y", `Date` )="]] .. oDatetime.year .. [["
]] )
local sEigenVerbruikCounter = executeQueryAndGetValues( sDatabaseDomoticz, [[
	SELECT `Counter`
	FROM `Meter_Calendar`
	WHERE `DeviceRowId`=]] .. iEigenVerbruikDeviceId .. [[
	ORDER BY `Date` DESC
	LIMIT 1
]] )

local fZonnepanelenDag = oZonnepanelenWaardes.total - tonumber( sZonnepanelenCounter )
local fEigenVerbruikDag = oVerbruikTotaalWaardes.total - tonumber( sEigenVerbruikCounter )

-- Rapporteer de opbrengst van de zonnepanelen als deze bovengemiddeld preseteren.
if (
	tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) > 30
	and oDatetime.min == math.random( 0, 59 )
	and oDatetime.hour % 2 == math.random( 0, 2 )
	and fZonnepanelenDag > tonumber( sZonnepanelenValueMonthAverage )
) then
	local sNotification = "Tot nu toe is er *" .. formatWh( fZonnepanelenDag ) .. "* gegenereerd en *" .. formatWh( fEigenVerbruikDag ) .. "* verbruikt."
	log( sNotification, 'Electra', true )
end

-- Rapporteer iedere dag de dagopbrengst op z'n vroegst om zeven uur of pas nadat het donker is.
if ( oDatetime.minutes == math.max( ( 19 * 60 ), timeofday['SunsetInMinutes'] ) + math.random( 1, 30 ) ) then
	local sNotification = "Vandaag is er *" .. formatWh( fZonnepanelenDag ) .. "* gegenereerd."
	if ( fZonnepanelenDag > tonumber( sZonnepanelenValueMax ) ) then
		-- algemeen record, hoogste ooit
		sNotification = aSuccessPrefix[ math.random( #aSuccessPrefix ) ] .. " " .. sNotification
		sNotification = sNotification .. " Dit is de _hoogste_ dagopbrengst *OOIT*. Het vorige record stond op *" .. formatWh( tonumber( sZonnepanelenValueMax ) ) .. "*."
	elseif ( fZonnepanelenDag > tonumber( sZonnepanelenValueMonthMax ) ) then
		-- maand record
		sNotification = aSuccessPrefix[ math.random( #aSuccessPrefix ) ] .. " " .. sNotification
		sNotification = sNotification .. " Dit is de _hoogste_ dagopbrengst voor de maand " .. oDatetime.monthname .. " *ooit*."
	elseif ( ( 100 / tonumber( sZonnepanelenValueMonthMax ) ) * fZonnepanelenDag > 80 ) then
		-- bijna maand record
		sNotification = aAlmostSuccessPrefix[ math.random( #aAlmostSuccessPrefix ) ] .. " " .. sNotification
		sNotification = sNotification .. " Dit is maar *" .. formatWh( tonumber( sZonnepanelenValueMonthMax ) - fZonnepanelenDag ) .. "* verwijderd van het record voor de maand " .. oDatetime.monthname .. "."
	elseif ( sZonnepanelenValueMonthMaxThisYear and fZonnepanelenDag > tonumber( sZonnepanelenValueMonthMaxThisYear ) ) then
		-- maand record dit jaar
		sNotification = sNotification .. " Dit is de _hoogste_ dagopbrengst voor de *huidige maand*."
	elseif ( fZonnepanelenDag > tonumber( sZonnepanelenValueMonthAverage ) ) then
		-- bovengemiddeld
		sNotification = sNotification .. " Dit is bovengemiddeld *voor deze maand*."
	else
		-- ondergemiddeld
		sNotification = "Vandaag is er _slechts_ *" .. formatWh( fZonnepanelenDag ) .. "* gegenereerd."
		sNotification = aFailurePrefix[ math.random( #aFailurePrefix ) ] .. " " .. sNotification
		sNotification = sNotification .. " Het gemiddelde voor de maand " .. oDatetime.monthname .. " is " .. formatWh( tonumber( sZonnepanelenValueMonthAverage ) ) .. "."
	end
	sNotification = sNotification .. " Er is overigens ook al *" .. formatWh( fEigenVerbruikDag ) .. "* verbruikt."
	log( sNotification, 'Electra', true )
end

-- Rapporteer het verbruik ergens na negen uur.
if ( isTime( { hour = 21, min = math.random( 5, 55 ) } ) ) then
	local fDagVerbruikPrognose = ( fEigenVerbruikDag / oDatetime.minutes ) * ( 60 * 24 )
	local sNotification = "Er is vandaag *" .. formatWh( fEigenVerbruikDag ) .. "* verbruikt. Het totaalverbruik komt vandaag waarschijnlijk rond de *" .. formatWh( fDagVerbruikPrognose ) .. "* te liggen."
	log( sNotification, 'Electra', true )
end
