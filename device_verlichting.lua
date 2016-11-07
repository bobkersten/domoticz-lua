if ( devicechanged['Voordeur Lamp'] == 'On' ) then
	addCommand( 'Tuin Lampen', 'On FOR 0.5 SECONDS REPEAT -5 INTERVAL 0.5 SECONDS' )
end

if ( devicechanged['Voordeur Lamp'] == 'Off' ) then
	addCommand( 'Tuin Lampen', 'Off FOR 0.5 SECONDS REPEAT -5 INTERVAL 0.5 SECONDS' )
end

if ( devicechanged['$Achterdeur Sensor'] == 'Open' ) then
	if ( otherdevices['Garage Lampen'] == 'Off' ) then
		addCommand( 'Garage Lampen', 'On' )
	end
end

if (
	devicechanged['$Entree Sensor Activiteit'] == 'On'
	or devicechanged['$Voordeur Sensor'] == 'Open'
) then
	if (
		otherdevices['Entree Lamp'] == 'Off'
		and tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) < 25
	) then
		addCommand( "Entree Lamp", 'On' )
	end
	if (
		otherdevices['Woonkamer Lamp'] == 'Off'
		and tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) < 25
	) then
		if ( timeOffset( otherdevices_lastupdate['Woonkamer Lamp'] ) / 60 > 30 ) then
			addCommand( 'Woonkamer Lamp', 'Set Level 5 AFTER 3 SECONDS' )
		end
	end
	if (
		otherdevices['Tuin Lampen'] == 'Off'
		and otherdevices['Voordeur Lamp'] == 'On'
		and ( oDatetime.hour >= 5 and oDatetime.hour <= 9 )
	) then
		addCommand( 'Tuin Lampen', 'On AFTER 10 SECONDS FOR 0.5 SECONDS REPEAT -5 INTERVAL 0.5 SECONDS' )
	end
end

if (
	devicechanged['$Entree Sensor Activiteit'] == 'Off'
	and otherdevices['Entree Lamp'] == 'On'
) then
	addCommand( 'Entree Lamp', 'Off FOR 0.5 SECONDS REPEAT -3 INTERVAL 0.5 SECONDS' )
end

if (
	devicechanged['$Keuken Sensor Activiteit'] == 'On'
	or devicechanged['$Achterdeur Sensor']
) then
	-- De keukenlamp wordt aangezet als er activiteit is waargenomen in de buurt van de keuken, maar
	-- deze wordt pas uitgezet na xx minuten (in time script).
	if ( otherdevices['Keuken Lamp'] == 'Off' ) then
		addCommand( "Keuken Lamp", "On" )
	end
end

if ( devicechanged['$Woonkamer Schakelaar Stand 1'] == 'On' or devicechanged['$Woonkamer Schakelaar Stand 2'] == 'On' ) then
	if ( tonumber( otherdevices_svalues['Woonkamer Lamp'] ) < 3 or tonumber( otherdevices_svalues['Woonkamer Lamp'] ) > 12 ) then
		addCommand( 'Woonkamer Lamp', 'Set Level 10' )
	else
		addCommand( 'Woonkamer Lamp', 'Set Level 35' )
	end
end

if (
	devicechanged['$Woonkamer Lamp Klik']
	and tonumber( otherdevices_svalues['Woonkamer Lamp'] ) == 0
) then
	if ( otherdevices['Home Cinema TV'] == 'On' ) then
		addCommand( 'Woonkamer Lamp', 'Set Level 10' )
	end
	if ( otherdevices['Home Cinema Apple TV'] == 'On' ) then
		addCommand( 'Woonkamer Lamp', 'Set Level 5' )
	end
end

if (
	devicechanged['Home Cinema TV'] == 'On'
	and otherdevices['Woonkamer Lamp'] ~= 'Off'
) then
	addCommand( 'Woonkamer Lamp', 'Set Level 10' )
end

if (
	devicechanged['Home Cinema Apple TV'] == 'On'
	and otherdevices['Woonkamer Lamp'] ~= 'Off'
) then
	addCommand( 'Woonkamer Lamp', 'Set Level 5' )
end

if (
	devicechanged['Woonkamer Lamp']
	or devicechanged['Entree Sensor Lichtsterkte']
) then
	if (
		tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) < 30
		and (
			otherdevices['Woonkamer Lamp'] == 'Off'
			or tonumber( otherdevices_svalues['Woonkamer Lamp'] ) < 10
		)
	) then
		if ( otherdevices['$Woonkamer Bank Lamp'] == 'Off' ) then
			addCommand( '$Woonkamer Bank Lamp', 'On REPEAT 3 INTERVAL 2 SECONDS RANDOM 2 SECONDS' )
		end
	else
		if ( otherdevices['$Woonkamer Bank Lamp'] == 'On' ) then
			addCommand( '$Woonkamer Bank Lamp', 'Off REPEAT 3 INTERVAL 2 SECONDS RANDOM 2 SECONDS' )
		end
	end
end
