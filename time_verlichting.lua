if ( otherdevices['$WC Lamp'] == 'On' ) then
	local iOffset = math.ceil( timeOffset( otherdevices_lastupdate['$WC Lamp'] ) / 60 )
	if (
		iOffset > 60
		and iOffset % 15 == 0
	) then
		log( "Zit er nu nog steeds iemand te schijten, of staat de lamp van de WC gewoon al " .. tostring( iOffset ) .. " minuten aan?", 'Verlichting', true )
	end
end

if ( otherdevices['$Badkamer Lamp'] == 'On' ) then
	local iOffset = math.ceil( timeOffset( otherdevices_lastupdate['$Badkamer Lamp'] ) / 60 )
	if (
		iOffset > 90
		and iOffset % 15 == 0
	) then
		log( 'De lamp op de badkamer staat nu al ' .. tostring( iOffset ) .. ' minuten aan, is dat nodig?', 'Verlichting', true )
	end
end

if ( tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) < 40 ) then
	if ( otherdevices['Voordeur Lamp'] == 'Off' ) then
		addCommand( "Voordeur Lamp", "On" )
	end
else
	if ( otherdevices['Voordeur Lamp'] == 'On' ) then
		addCommand( "Voordeur Lamp", "Off" )
	end
end

if (
	isTime( { hour = 1, min = 30 } )
	and otherdevices['Tuin Lampen'] == 'On'
) then
	addCommand( "Tuin Lampen", "Off FOR 0.7 SECONDS REPEAT -5 INTERVAL 0.7 SECONDS" )
end

-- Als de lamp handmatig is aangezet moet deze ook uitgezet worden na verloop van tijd.
if (
	otherdevices['Entree Lamp'] == 'On'
	and otherdevices['$Entree Sensor Activiteit'] == 'Off'
) then
	if ( timeOffset( otherdevices_lastupdate['Entree Lamp'] ) / 60 >= 15 ) then
		addCommand( 'Entree Lamp', 'Off FOR 0.7 SECONDS REPEAT -3 INTERVAL 0.7 SECONDS' )
	end
end

if (
	otherdevices['Keuken Lamp'] == 'On'
	and otherdevices['$Keuken Sensor Activiteit'] == 'Off'
) then
	-- De keukenlamp staat aan terwijl er geen activiteit rond de keuken is waargenomen. Kan deze uit?
	local iMaxAanTijd = 45
	if (
		tonumber( otherdevices_svalues['Keuken Sensor Lichtsterkte'] ) > 80 -- flink veel licht in de keuken regio
		or (
			oDatetime.hour > 9
			and oDatetime.hour < 17
		)
	) then
		-- Overdag mag de tijd terug naar een half uur.
		iMaxAanTijd = 30
	end
	if ( timeOffset( otherdevices_lastupdate['$Keuken Sensor Activiteit'] ) / 60 >= iMaxAanTijd ) then
		addCommand( 'Keuken Lamp', 'Off' )
	end
end

if ( otherdevices['Garage Lampen'] == 'On' ) then
	local iMaxAanTijd = 30
	if ( otherdevices['$Achterdeur Sensor'] == 'Closed' ) then
		iMaxAanTijd = 3
	end
	if (
		oDatetime.hour >= 9
		and oDatetime.hour <= 17
		and (
			oDatetime.wday == 7
			or oDatetime.wday == 1
		)
	) then
		iMaxAanTijd = 60
	end
	if ( timeOffset( otherdevices_lastupdate['Garage Lampen'] ) / 60 >= iMaxAanTijd ) then
		addCommand( 'Garage Lampen', 'Off' )
	end
end
