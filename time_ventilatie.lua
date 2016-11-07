---------------------------------------------------------------------------------------------------------------------------
local iAfzuigingHoogNa = 3				-- Na hoeveel minuten WC drukken afzuiging hoog
local iAfzuigingHoogDuur = 15			-- Hoeveel minuten hoge afzuiging na drukken
---------------------------------------------------------------------------------------------------------------------------

-- Centrale afzuiging hoog aan na het poepen (dat minimaal 3 minuten moet duren).
if ( otherdevices['$WC Lamp'] == 'On' ) then
	if (
		timeOffset( otherdevices_lastupdate['$WC Lamp'] ) / 60 >= iAfzuigingHoogNa
		and otherdevices['Centrale Afzuiging Hoog'] == 'Off'
	) then
		addCommand( 'Centrale Afzuiging Hoog', 'On' )
	end
end

if (
	otherdevices['$WC Lamp'] == 'Off'
	and otherdevices['Centrale Afzuiging Hoog'] == 'On'
) then
	if ( timeOffset( otherdevices_lastupdate['$WC Lamp'] ) / 60 >= iAfzuigingHoogDuur ) then
		addCommand( 'Centrale Afzuiging Hoog', 'Off' )
	end
end

-- Entree afzuiging aan als het heel erg warm wordt in de entree.
if (
	otherdevices['Entree Ventilator'] == 'Off'
	and tonumber( otherdevices_svalues['Entree Sensor Temperatuur'] ) >= 25
	and tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) > 1000
) then
	addCommand( "Entree Ventilator", "On REPEAT 3 INTERVAL 5 SECONDS RANDOM 5 SECONDS" )
end

if (
	otherdevices['Entree Ventilator'] == 'On'
	and (
		tonumber( otherdevices_svalues['Entree Sensor Temperatuur'] ) <= 24
		or tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) <= 1000
	)
) then
	addCommand( "Entree Ventilator", "Off REPEAT 3 INTERVAL 5 SECONDS RANDOM 5 SECONDS" )
end
