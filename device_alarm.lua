if ( devicechanged['$Alarm Schakelaar'] == 'On' ) then
	addCommand( 'Alarm', 'Toggle' )
end

if ( devicechanged['Alarm'] == 'On' ) then
	addCommand( 'Alarm', 'Clear' )
	if ( retrieve( 'Alarm', 'Status' ) == 'Inloopvertraging' ) then
		-- Het alarm is niet uitgezet binnen de inloopvertraging, dus het alarm moet nu afgaan.
		addCommand( '$Sirene', 'On FOR 3 MINUTES' )
		--addCommand( '$Deurbel', 'Off' )
		addCommand( 'Alarm', 'On AFTER 5 MINUTES' )
		os.execute( '/usr/bin/killall mplayer' )
		log( 'ALARM MELDING', 'Alarm', true )
		store( 'Alarm', 'Status', 'Alarm' )
	elseif ( retrieve( 'Alarm', 'Status' ) == 'Uitloopvertraging' ) then
		-- Het alarm is ingeschakeld na een uitloopvertraging.
		--addCommand( '$Deurbel', 'Off' )
		os.execute( '/usr/bin/killall mplayer' )
		log( 'Het alarm is ingeschakeld.', 'Alarm', true )
		store( 'Alarm', 'Status', 'Ingeschakeld' )
	elseif ( retrieve( 'Alarm', 'Status' ) == 'Alarm' ) then
		-- Er is nog steeds een alarm actief.
		addCommand( 'Alarm', 'On AFTER 5 MINUTES' )
		log( 'HERHALING ALARM MELDING', 'Alarm', true )
	else
		-- Eerst wordt er gecontroleerd of het alarm er wel opgezet kan worden.
		local sGeweigerd = 'niet'
		if ( otherdevices['$Achterdeur Sensor'] == 'Open' ) then
			sGeweigerd = 'Het alarm kan niet worden ingeschakeld omdat de achterdeur nog open staat.'
		elseif ( otherdevices['$Badkamer Lamp'] == 'On' ) then
			sGeweigerd = 'Het alarm kan niet worden ingeschakeld omdat de lamp op de badkamer nog aan staat.'
		elseif ( otherdevices['$WC Lamp'] == 'On' ) then
			sGeweigerd = 'Het alarm kan niet worden ingeschakeld omdat de lamp op de WC nog aan staat.'
		end
		if ( 'niet' ~= sGeweigerd ) then
			addCommand( '$Sirene', 'On FOR 0.3 SECOND' )
			addCommand( 'Alarm', 'Off' )
			log( sGeweigerd, 'Alarm', true )
		else
			os.execute( '/usr/bin/mplayer -loop 99 ~/domoticz-data/sounds/ding.mp3 &' )
			--addCommand( '$Deurbel', 'On FOR 0.5 SECONDS REPEAT 15 INTERVAL 0.5 SECONDS' )
			addCommand( 'Alarm', 'On AFTER 15 SECONDS' )
			store( 'Alarm', 'Status', 'Uitloopvertraging' )
		end
	end
end

if ( devicechanged['Alarm'] == 'Off' ) then
	addCommand( 'Alarm', 'Clear' )
  	--addCommand( '$Deurbel', 'Off' )
  	os.execute( '/usr/bin/killall mplayer' )
	addCommand( '$Sirene', 'Off' )
	if ( retrieve( 'Alarm', 'Status' ) == 'Uitloopvertraging' ) then
		addCommand( '$Sirene', 'On FOR 0.3 SECOND' )
		log( 'Het inschakelen van het alarm is geannuleerd.', 'Alarm', true )
	elseif  (
		retrieve( 'Alarm', 'Status' ) == 'Ingeschakeld'
		or retrieve( 'Alarm', 'Status' ) == 'Inloopvertraging'
	) then
		log( 'Het alarm is uitgeschakeld.', 'Alarm', true )
	elseif  ( retrieve( 'Alarm', 'Status' ) == 'Alarm' ) then
		log( 'Het alarm is uitgeschakeld na een alarm melding.', 'Alarm', true )
	end
	store( 'Alarm', 'Status', 'Uitgeschakeld' )
end

if (
	devicechanged['$Voordeur Sensor'] == 'Open'
	or devicechanged['$Achterdeur Sensor'] == 'Open'
	or devicechanged['$Entree Sensor Activiteit'] == 'On'
	or devicechanged['$Keuken Sensor Activiteit'] == 'On'
) then
	if ( retrieve( 'Alarm', 'Status' ) == 'Ingeschakeld' ) then
		--addCommand( '$Deurbel', 'On FOR 0.5 SECONDS REPEAT 15 INTERVAL 0.5 SECONDS' )
		os.execute( '/usr/bin/mplayer -loop 99 ~/domoticz-data/sounds/ding.mp3 &' )
		addCommand( 'Alarm', 'On AFTER 15 SECONDS' )
		store( 'Alarm', 'Status', 'Inloopvertraging' )
	end
end
