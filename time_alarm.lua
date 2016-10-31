if (
	otherdevices['Alarm'] == 'On'
	and math.ceil( timeOffset( otherdevices_lastupdate['Alarm'] ) / 60 ) == 10
) then
	addCommand( "Rolluik Badkamer", "On", 3, 5 )
	addCommand( "Rolluik Kamer Joep", "On", 3, 5 )
	addCommand( "Rolluik Kamer Stef", "On", 3, 5 )
	addCommand( "Rolluik Kamer Bob en Elvira", "On", 3, 5 )

	if ( otherdevices['Woonkamer Lamp'] ~= 'Off' ) then
		addCommand( 'Woonkamer Lamp', 'Off' )
	end
	if ( otherdevices['Overloop Lamp'] ~= 'Off' ) then
		addCommand( 'Overloop Lamp', 'Off' )
	end
	if ( otherdevices['Garage Lampen'] ~= 'Off' ) then
		addCommand( 'Garage Lampen', 'Off' )
	end
	if ( otherdevices['Keuken Lamp'] ~= 'Off' ) then
		addCommand( 'Keuken Lamp', 'Off' )
	end
	if ( otherdevices['Home Cinema Power Off'] ~= 'On' ) then -- is actually turned on (counter intuitive)
		addCommand( 'Home Cinema Power Off', 'On' )
	end
end

if ( retrieve( 'Alarm', 'Status' ) == 'Alarm' ) then
	local iOffset = math.ceil( timeOffset( uservariables_lastupdate['Alarm'] ) / 60 )
	if (
		iOffset > 5
		and iOffset % 5 == 0
	) then
		log( '!!! HERHALING ALARM MELDING !!!', 'Alarm', true )
	end
end
