if ( devicechanged['$Deurbel Schakelaar'] == 'On' ) then
	if ( otherdevices['$Voordeur Sensor'] == 'Closed' ) then

		-- De voordeur zit gewoon dicht, dus dit is een deurbel actie.
		setCommand( '$Deurbel', 'On FOR 0.7 SECOND' )
		if ( tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) > 250 ) then
			setCommand( '$Sirene', 'On FOR 0.5 SECOND' )
		end
		if (
			otherdevices['Entree Lamp'] == 'Off'
			and tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) < 25
		) then
			setCommand( "Entree Lamp", "On AFTER 0.5" )
		end
		if ( oDatetime.hour >= 21 and oDatetime.hour <= 7 ) then
			log( 'Er is midden in de nacht op de deurbel gedrukt, de modderfokkers!', 'Deurbel', true )
		else
			log( 'Er staat iemand voor de deur!', 'Deurbel', true )
		end

	else

		-- De voordeur is open, dus dit is een alarm actie. Alle lopende alarm acties worden onderbroken
		-- doordat exclusive op true wordt gezet.
		toggle( 'Alarm', 0, true )
	end
end
