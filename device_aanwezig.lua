if (
	otherdevices['Alarm'] == 'Off'
	and (
		-- Gebruik alleen NIET aanpasbare sensoren voor het detecten van aanwezigheid, andere
		-- sensoren kunnen ook aangepast worden via LUA en triggeren dan een false positive.
		devicechanged['$Entree Sensor Activiteit'] == 'On'
		or devicechanged['$Keuken Sensor Activiteit'] == 'On'
		or devicechanged['$WC Lamp']
		or devicechanged['$Badkamer Lamp']
	)
) then
	if (
		otherdevices['$Achterdeur Sensor'] == 'Closed'
		and otherdevices['$Voordeur Sensor'] == 'Closed'
	) then
		-- Als beide uitgangen dicht zijn dan is er zeker 100% iemand thuis.
		if ( otherdevices['Iemand Aanwezig'] == 'On' ) then
			addCommand( 'Iemand Aanwezig', 'Clear' )
		else
			addCommand( 'Iemand Aanwezig', 'On' )
		end
	elseif ( otherdevices['$Voordeur Sensor'] == 'Closed' ) then
		-- Als de voordeur open staat is er *altijd* iemand aanwezig. Bij het sluiten wordt
		-- dan verder gekeken. Als de achterdeur open staat dan kan er ook vertrokken worden
		-- door de achterdeur. Als deze al een tijdje open staat dan zal deze wel open zijn
		-- gelaten (grrrrr) en zal er gewoon iemand thuis zijn.
		local iDuur = 45
		if (
			oDatetime.hour >= 20 or oDatetime.hour <= 8
			or timeOffset( otherdevices_lastupdate['$Achterdeur Sensor'] ) / 60 > 60
		) then
			iDuur = 85
		end
		addCommand( 'Iemand Aanwezig', 'Clear' )
		if ( otherdevices['Iemand Aanwezig'] == 'On' ) then
			addCommand( 'Iemand Aanwezig', 'Off AFTER ' .. tostring( iDuur ) .. ' MINUTES' )
		else
			addCommand( 'Iemand Aanwezig', 'On FOR ' .. tostring( iDuur ) .. ' MINUTES' )
		end
	end
end

if ( devicechanged['$Voordeur Sensor'] == 'Open' ) then
	-- Zolang de voordeur open staat is er zeker iemand aanwezig. Dit zorgt tevens
	-- voor een snelle registratie bij thuiskomen.
	addCommand( 'Iemand Aanwezig', 'Clear' )
	if ( otherdevices['Iemand Aanwezig'] ~= 'On' ) then
		addCommand( 'Iemand Aanwezig', 'On' )
	end
end

if ( devicechanged['$Voordeur Sensor'] == 'Closed' ) then
	addCommand( 'Iemand Aanwezig', 'Clear' )
	-- Als de voordeur wordt dichtgedaan dan is het niet zeker of er nog iemand is,
	-- behalve als het alarm er op staat. De variable "Iemand Aanwezig" is altijd aan
	-- omdat de deur net open is geweest.
	if ( otherdevices['Iemand Aanwezig'] ~= 'Off' ) then
		if (
			otherdevices['Alarm'] == 'On'
			and retrieve( 'Alarm', 'Status' ) == 'Uitloopvertraging'
		) then
			addCommand( 'Iemand Aanwezig', 'Off' )
		else
			addCommand( 'Iemand Aanwezig', 'Off AFTER 30 MINUTES' )
		end
	end
end

if ( devicechanged['$Achterdeur Sensor'] ) then
	-- De achterdeur is een lastig verhaal, wordt nogal eens open gemaakt zonder dat er
	-- vertrokken wordt, en wordt ook nogal eens open gelaten. Grrrrr. Vandaar dat er een
	-- grote buffer gebruikt wordt.
	local iDuur = 45
	if ( oDatetime.hour >= 20 or oDatetime.hour <= 8 ) then
		iDuur = 85
	end
	addCommand( 'Iemand Aanwezig', 'Clear' )
	if ( otherdevices['Iemand Aanwezig'] == 'On' ) then
		addCommand( 'Iemand Aanwezig', 'Off AFTER ' .. tostring( iDuur ) .. ' MINUTES' )
	else
		addCommand( 'Iemand Aanwezig', 'On FOR ' .. tostring( iDuur ) .. ' MINUTES' )
	end
end

if ( devicechanged['Alarm'] == 'On' ) then
	-- Als het alarm wordt aangezet dan is er normaal gesproken binnen afzienbare tijd niemand
	-- meer aanwezig. Bij het sluiten van de deur wordt de variable overigens meteen goed gezet.
	-- Het alarm kan echter ook aangezet worden zonder dat er iemand aanwezig is.
	addCommand( 'Iemand Aanwezig', 'Clear' )
	if ( otherdevices['Iemand Aanwezig'] == 'On' ) then
		addCommand( 'Iemand Aanwezig', 'Off AFTER 10 MINUTES' )
	end
end

if ( devicechanged['Iemand Aanwezig'] ) then
	addCommand( 'Home Cinema Schakelaar', 'Clear' )
	if ( devicechanged['Iemand Aanwezig'] == 'Off' ) then
		-- Als er niemand thuis is heeft het ook geen zin om de home cinema aan te laten,
		-- deze moet echter wel goed afgesloten worden als dat nodig is.
		if ( otherdevices['Home Cinema Power Off'] ~= 'On' ) then
			addCommand( 'Home Cinema Power Off', 'On' )
			addCommand( 'Home Cinema Schakelaar', 'Off AFTER 1 MINUTE' )
		else
			addCommand( 'Home Cinema Schakelaar', 'Off' )
		end

		-- Zet alle lampen uit als er niemand meer thuis is.
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

		-- Het huis mag ook even ontlucht worden (dat maakt herrie dus dat kan mooi nu).
		addCommand( 'Centrale Afzuiging Hoog', 'Clear' )
		if ( otherdevices['Centrale Afzuiging Hoog'] == 'On' ) then
			addCommand( 'Centrale Afzuiging Hoog', 'Off AFTER 10 MINUTES' )
		else
			addCommand( 'Centrale Afzuiging Hoog', 'On FOR 10 MINUTES' )
		end
		addCommand( 'Entree Ventilator', 'Clear' )
		if ( otherdevices['Entree Ventilator'] == 'On' ) then
			addCommand( 'Entree Ventilator', 'Off AFTER 10 MINUTES' )
		else
			addCommand( 'Entree Ventilator', 'On FOR 10 MINUTES' )
		end

	else
		-- Zet alles voor de home cinema- en wifi maar weer aan want er is iemand thuis.
		log( 'Welkom thuis.', 'Iemand Aanwezig', true )
		addCommand( 'Home Cinema Schakelaar', 'On' )
	end

	-- De rolluiken moeten ook geupdated worden direct nadat iemand is binnen gekomen of
	-- is vertrokken (niet wachten tot hele minuten).
	require "time_rolluiken"
end
