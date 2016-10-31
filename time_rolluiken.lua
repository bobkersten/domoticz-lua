local sLastUpdate = otherdevices_lastupdate['Rolluik Badkamer'] -- is used in all situations
if (
	sLastUpdate == nil
	or timeOffset( sLastUpdate ) > ( 45 * 60 ) -- 45 minutes
) then
	if ( tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) < 25 ) then
		if ( otherdevices['Rolluik Badkamer'] == 'Stopped' ) then -- if open
			addCommand( "Rolluik Badkamer", "On", 3, 5 )
			addCommand( "Rolluik Kamer Joep", "On", 3, 5, 1 )
			addCommand( "Rolluik Kamer Stef", "On", 3, 5, 2 )
			addCommand( "Rolluik Kamer Bob en Elvira", "On", 3, 5, 3 )
			log( 'Alle rolluiken worden gesloten.', 'Rolluiken', true )
		end
	elseif (
		tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) >= 25
		and tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) < 1000
	) then
		if ( otherdevices['Rolluik Badkamer'] ~= 'Stopped' ) then -- if not open
			addCommand( "Rolluik Badkamer", "On", 2, 1 )
			addCommand( "Rolluik Badkamer", "Off", 2, 1, 60 )
			addCommand( "Rolluik Badkamer", "Stop", 2, 1, 85 )
			log( 'De rolluik op de badkamer wordt geopend.', 'Rolluiken', true )
		end
	end
end
