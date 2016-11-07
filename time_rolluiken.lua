local sLastUpdate = otherdevices_lastupdate['Rolluik Badkamer'] -- is used in all situations
if (
	sLastUpdate == nil
	or timeOffset( sLastUpdate ) > ( 45 * 60 ) -- 45 minutes
) then
	if (
		tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) < 25
		or otherdevices['Iemand Aanwezig'] == 'Off'
	) then
		if ( otherdevices['Rolluik Badkamer'] == 'Stopped' ) then -- if open
			addCommand( "Rolluik Badkamer", "On REPEAT 3 INTERVAL 5 SECONDS RANDOM 5 SECONDS" )
			addCommand( "Rolluik Kamer Joep", "On REPEAT 3 INTERVAL 5 SECONDS RANDOM 5 SECONDS" )
			addCommand( "Rolluik Kamer Stef", "On REPEAT 3 INTERVAL 5 SECONDS RANDOM 5 SECONDS" )
			addCommand( "Rolluik Kamer Bob en Elvira", "On REPEAT 3 INTERVAL 5 SECONDS RANDOM 5 SECONDS" )
			log( 'Alle rolluiken worden gesloten.', 'Rolluiken', true )
		end
	else
		if ( otherdevices['Rolluik Badkamer'] ~= 'Stopped' ) then -- if not open
			addCommand( "Rolluik Badkamer", "On REPEAT 3 INTERVAL 0.5 SECONDS" )
			addCommand( "Rolluik Badkamer", "Off AFTER 55 SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
			addCommand( "Rolluik Badkamer", "Stop AFTER 81 SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
			log( 'De rolluik op de badkamer wordt geopend.', 'Rolluiken', true )
		end
	end
end
