local aMonths = { 'januari', 'februari', 'maart', 'april', 'mei', 'juni', 'juli', 'augustus', 'september', 'oktober', 'november', 'december' }
oDatetime = os.date( "*t" )
oDatetime.minutes = oDatetime.min + ( oDatetime.hour * 60 )
oDatetime.smonth = tostring( tonumber( oDatetime.month ) )
if ( tonumber( oDatetime.month ) < 10 ) then
	oDatetime.smonth = '0' .. oDatetime.smonth
end
oDatetime.monthname = aMonths[tonumber( oDatetime.month )]
oDatetime.sday = tostring( tonumber( oDatetime.day ) )
if ( tonumber( oDatetime.day ) < 10 ) then
	oDatetime.sday = '0' .. oDatetime.sday
end
sNow = oDatetime.sday .. "/" .. oDatetime.smonth .. "/" .. oDatetime.year

math.randomseed( oDatetime.day )
