function formatWh( fWh_ )
	if ( fWh_ < 1000 ) then
		return math.ceil( fWh_ - 0.5 ) .. " Wh"
	else
		return string.format( "%.3f", fWh_ / 1000 ) .. " kWh"
	end
end

function parseTime( sTime_ )
	local oTime = {}
	for sPart in string.gmatch( sTime_, "%d*" ) do
		oTime[#oTime + 1] = tonumber( sPart )
	end
	return { hour = oTime[1], min = oTime[2] }
end

function timeOffset( sDate_ )
	local t1 = os.time()
	local t2 = parseDate( sDate_ )
	return os.difftime( t1, t2 )
end

function timeDelta( sDate1_, sDate2_, bSigned_ )
	local t1 = parseDate( sDate1_ )
	local t2 = parseDate( sDate2_ )
	if ( bSigned_ ) then
		return os.difftime( t1, t2 )
	else
		return math.abs( os.difftime( t1, t2 ) )
	end
end


function parseDate( sDate_ )
	if ( sDate_ == nil ) then
		return os.time{ year=1900, month=1, day=1, hour=0, min=0, sec=0 }
	else
		local sYear = string.sub( sDate_, 1, 4 )
		local sMonth = string.sub( sDate_, 6, 7 )
		local sDay = string.sub( sDate_, 9, 10 )
		local sHour = string.sub( sDate_, 12, 13 )
		local sMinutes = string.sub( sDate_, 15, 16 )
		local sSeconds = string.sub( sDate_, 18, 19 )
		return os.time{ year=sYear, month=sMonth, day=sDay, hour=sHour, min=sMinutes, sec=sSeconds }
	end
end

function addTimeStr( sTime_, iAdd_ )
	local oTime
	if ( sTime_ == "now" ) then
		local oDatetime = os.date( "*t" )
		oTime = { hour = oDatetime.hour, min = oDatetime.min }
	else
		oTime = parseTime( sTime_ )
	end

	addTime( oTime, iAdd_ )
	return getTimeStr( oTime )
end

function getTimeStr( mTime_ )
	if ( mTime_ == "now" ) then
		mTime_ = os.date( "*t" )
	end
	local sResult = tostring( mTime_.hour ) .. ":"
	if ( mTime_.min < 10 ) then
		sResult = sResult .. "0"
	end
	sResult = sResult .. tostring( mTime_.min )
	return sResult
end

function addTime( oTime_, iAdd_ )
	oTime_.min = oTime_.min + iAdd_
	while ( oTime_.min >= 60 ) do
		oTime_.hour = oTime_.hour + 1
		oTime_.min = oTime_.min - 60
    end
	if ( oTime_.hour >= 24 ) then
		oTime_.hour = 0
	end
	return oTime_
end

function isTime( oTime_ )
	local oDatetime = os.date( "*t" )
	return ( oDatetime.hour == oTime_.hour and oDatetime.min == oTime_.min )
end

function getPreciseTime()
	local rHandle = io.popen( "date +%s%N | cut -b1-13 2>&1" )
	local sResult = rHandle:read( '*line' )
	return tonumber( sResult )
end

function splitkWhValues( sValues_ )
	if ( sValues_ == nil ) then
		return { watt = 0, total = 0 }
	end
	local aValues = {}
	for sValue in string.gmatch( sValues_, "%d+%.?%d*" ) do
		aValues[#aValues + 1] = tonumber( sValue )
	end
	return { watt = aValues[1], total = aValues[2] }
end

function splitP1Values( sValues_ )
	if ( sValues_ == nil ) then
		return { watt = 0, total = 0 }
	end
	local aValues = split( sValues_, ';' )

-- 1 USAGE1= energy usage meter tariff 1
-- 2 USAGE2= energy usage meter tariff 2
-- 3 RETURN1= energy return meter tariff 1
-- 4 RETURN2= energy return meter tariff 2
-- 5 CONS= actual usage power (Watt)
-- 6 PROD= actual return power (Watt)

	return {
		watt = tonumber( aValues[5] ) - tonumber( aValues[6] ),
		total = ( tonumber( aValues[1] ) + tonumber( aValues[2] ) ) - ( tonumber( aValues[3] ) + tonumber( aValues[4] ) ),
		ret = tonumber( aValues[3] ) + tonumber( aValues[4] ),
		usa = tonumber( aValues[1] ) + tonumber( aValues[2] ),
		cons = tonumber( aValues[5] ),
		prod = tonumber( aValues[6] )
	}
end


function urlEncode( sStr_ )
	if ( sStr_ ) then
		sStr_ = string.gsub( sStr_, "\n", "\r\n" )
		sStr_ = string.gsub( sStr_, "([^%w %-%_%.%~])", function( c ) return string.format("%%%02X", string.byte( c ) ) end )
		sStr_ = string.gsub( sStr_, " ", "+" )
	end
	return sStr_
end

function split( sStr_, sSep_ )
	if ( sSep_ == nil ) then
		sSep_ = "%s"
	end
	local t = {} ; i = 1
	for sLocalStr in string.gmatch( sStr_, "([^" .. sSep_ .. "]+)" ) do
		t[i] = sLocalStr
		i = i + 1
	end
	return t
end

function addCommand( sDevice_, sCommand_, iRepeat_, iDelay_, iWait_ )
	iRepeat_ = iRepeat_ or 1
	iDelay_ = iDelay_ or 0
	iWait_ = iWait_ or 0
	for iIndex = 1, iRepeat_ do
		if ( iWait_ == 0 and ( iIndex == 1 or iDelay_ == 0 ) ) then
			commandArray[#commandArray + 1] = { [ sDevice_ ] = sCommand_ }
		else
			commandArray[#commandArray + 1] = { [ sDevice_ ] = sCommand_ .. ' AFTER ' .. ( iWait_ + ( iDelay_ *  iIndex ) ) }
		end
	end
end

function setCommand( sDevice_, sCommand_, iRepeat_, iDelay_, iWait_ )
	addCommand( sDevice_, sCommand_, iRepeat_, iDelay_, iWait_, true )
end

function toggle( sDevice_, iWait_, bExclusive_ )
	iWait_ = iWait_ or 0
	if ( otherdevices[sDevice_] == 'Off' ) then
		addCommand( sDevice_, 'On', 1, 0, iWait_, bExclusive_ )
	else
		addCommand( sDevice_, 'Off', 1, 0, iWait_, bExclusive_ )
	end
end

function round( fNum_, iDecimals_ )
	local fMult = 10 ^ ( iDecimals_ or 0 )
	return math.floor( fNum_ * fMult + 0.5 ) / fMult
end

function log( sMessage_, sPrefix_, bNotify_ )
	local sMessage = sMessage_
	if ( sPrefix_ ) then
		sMessage = '(' .. sPrefix_ .. ') ' .. sMessage
	end
	print( sMessage )
	if ( bNotify_ ) then
		addCommand( 'SendNotification', sMessage )
	end
	return true -- allows chaining in if conditions
end

--  ____ ___                  ____   ____            .__      ___.   .__
-- |    |   \______ __________\   \ /   /____ _______|__|____ \_ |__ |  |   ____   ______
-- |    |   /  ___// __ \_  __ \   Y   /\__  \\_  __ \  \__  \ | __ \|  | _/ __ \ /  ___/
-- |    |  /\___ \\  ___/|  | \/\     /  / __ \|  | \/  |/ __ \| \_\ \  |_\  ___/ \___ \
-- |______//____  >\___  >__|    \___/  (____  /__|  |__(____  /___  /____/\___  >____  >
--              \/     \/                    \/              \/    \/          \/     \/

function storeSet( sSet_, oSet_, iWait_ )
	iWait_ = iWait_ or 0
	local sObject = ''
	for sKey, sValue in pairs( oSet_ ) do
		if ( sValue ~= nil ) then
			if ( string.len( sObject ) > 0 ) then
				sObject = sObject .. '|'
			end
			sObject = sObject .. sKey .. '=' .. sValue
		end
	end
	sObject = '@' .. getTimeStr( 'now' ) .. '~' .. sObject .. '~'
	if ( iWait_ > 0 ) then
		addCommand( 'Variable:' .. sSet_, sObject .. ' AFTER ' .. tostring( iWait_ ) )
	else
		addCommand( 'Variable:' .. sSet_, sObject )
	end
	uservariables[sSet_] = sObject
end

function retrieveSet( sSet_ )
	local oObject = {}
	local sObject = uservariables[sSet_]
	if ( sObject == nil ) then
		error( 'invalid set "' .. sSet_ .. '", create a string uservariable first' )
	else
		-- Anything before and after the ~-sign (including) is stripped (can be used for metadata).
		sObject = sObject:gsub( '.*~(.*)~.*', '%1' )
		if ( uservariables[sSet_] == sObject ) then
			-- Nothing has changed, so the uservariable is invalid and should be re-initialized.
			storeSet( sSet_, {} )
			error( 'invalid set "' .. sSet_ .. '", uservariable re-initialized' )
		else
			aPairs = split( sObject, '|' )
			for iIndex, sPair in ipairs( aPairs ) do
				aPair = split( sPair, '=' )
				if ( #aPair == 2 ) then
					oObject[aPair[1]] = aPair[2]
				end
			end

		end
	end
	return oObject
end

function store( sSet_, sKey_, mValue_, iWait_ )
	mValue_ = mValue_ or nil
	iWait_ = iWait_ or 0
	if ( sKey_:match( "%W _" ) ) then
		error( 'invalid key "' .. sKey_ .. '", use only alphanumeric characters, spaces or underscores' )
	end
	local oSet = retrieveSet( sSet_ )
	if ( mValue_ ~= nil ) then
		oSet[sKey_] = tostring( mValue_ )
	else
		oSet[sKey_] = nil
	end
	storeSet( sSet_, oSet, iWait_ )
end

function retrieve( sSet_, sKey_, mDefault_ )
	local oSet = retrieveSet( sSet_ )
	if ( oSet[sKey_] ~= nil ) then
		return oSet[sKey_]
	else
		return mDefault_
	end
end

function retrieveNumber( sSet_, sKey_, mDefault_ )
	local sValue = retrieve( sSet_, sKey_, nil )
	if ( sValue ~= nil ) then
		return tonumber( sValue )
	else
		return mDefault_
	end
end

function delete( sSet_, sKey_ )
	store( sSet_, sKey_ )
end
