if ( devicechanged['Home Cinema Power Off'] == 'Off' ) then -- Home Cinema wordt AAN gezet (stand uit = off :-))
	addCommand( '$Versterker', 'On', 3, 3 )
end

if ( devicechanged['Home Cinema Power Off'] == 'On' ) then -- Home Cinema wordt UIT gezet
	addCommand( '$Versterker', 'Off', 3, 3 )
	if (
		oDatetime.hour >= 21 or oDatetime.hour < 3
		and otherdevices['Alarm'] == 'Off'
	) then
		addCommand( 'SendNotification', '#Welterusten.' )
		addCommand( 'Entree Lamp', 'On' )
		addCommand( 'Overloop Lamp', 'On AFTER 5' )
		addCommand( 'Tuin Lampen', 'Off AFTER 5' )
		if ( otherdevices['Woonkamer Lamp'] ~= 'Off' ) then
			addCommand( 'Woonkamer Lamp', 'Set Level 20' )
		end
	end
end
