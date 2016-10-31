---------------------------------------------------------------------------------------------------------------------------
local iInloopVertraging = 15			-- Inloopvertraging in seconden
local iUitloopVertraging = 15			-- Uitloopvertraging in seconden
---------------------------------------------------------------------------------------------------------------------------

if ( devicechanged['Alarm'] == 'On' ) then
	if ( retrieve( 'Alarm', 'Status' ) == 'Inloopvertraging' ) then
		-- Het alarm is niet uitgezet binnen de inloopvertraging, dus het alarm moet nu afgaan.
		addCommand( '$Sirene', 'On FOR 3 MINUTES' )
		log( '!!! ALARM MELDING !!!', 'Alarm', true )
		store( 'Alarm', 'Status', 'Alarm' )
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
			setCommand( '$Sirene', 'On FOR 0.3 SECOND' )
			setCommand( 'Alarm', 'Off' )
			log( sGeweigerd, 'Alarm', true )
		else
			if ( otherdevices['$Voordeur Sensor'] == 'Open' ) then
				setCommand( '$Deurbel', 'On' )
				setCommand( 'Alarm', 'Off AFTER ' .. tostring( iUitloopVertraging ) .. ' SECONDS' )
				store( 'Alarm', 'Status', 'Uitloopvertraging' )
			else
				log( 'Het alarm is ingeschakeld.', 'Alarm', true )
				store( 'Alarm', 'Status', 'Ingeschakeld' )
			end
		end
	end
end

if ( devicechanged['Alarm'] == 'Off' ) then
	setCommand( '$Deurbel', 'Off' )
	setCommand( '$Sirene', 'Off' )
	if ( retrieve( 'Alarm', 'Status' ) == 'Uitloopvertraging' ) then
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
	devicechanged['$Voordeur Sensor'] == 'Closed'
	and retrieve( 'Alarm', 'Status' ) == 'Uitloopvertraging'
) then
	setCommand( '$Deurbel', 'Off' )
	log( 'Het alarm is ingeschakeld.', 'Alarm', true )
	store( 'Alarm', 'Status', 'Ingeschakeld' )
end

if (
	devicechanged['$Voordeur Sensor'] == 'Open'
	or devicechanged['$Achterdeur Sensor'] == 'Open'
	or devicechanged['$Entree Sensor Activiteit'] == 'On'
	or devicechanged['$Keuken Sensor Activiteit'] == 'On'
) then
	if ( retrieve( 'Alarm', 'Status' ) == 'Ingeschakeld' ) then
		-- Er is activiteit waargenomen terwijl het alarm erop staat. De deurbel geeft aan dat de
		-- inloop vertraging actief is.
		local bOn = false
		local fInterval = 0.4
		local fWait
		for fWait = 0,iInloopVertraging,fInterval do
			local sCmd
			if ( bOn ) then
				sCmd = 'Off'
			else
				sCmd = 'On'
			end
			if ( fWait > 0 ) then
				sCmd = sCmd .. ' AFTER ' .. tostring( fWait ) .. ' SECONDS'
			end
			bOn = not bOn
			addCommand( '$Deurbel', sCmd )
		end
		if ( bOn ) then
			addCommand( '$Deurbel', 'Off AFTER ' .. tostring( fWait + fInterval ) .. ' SECONDS' )
		end
		setCommand( 'Alarm', 'On AFTER ' .. tostring( fWait + fInterval ) .. ' SECONDS' )
		store( 'Alarm', 'Status', 'Inloopvertraging' )
	end
end
