if (
	devicechanged['$WC Lamp']
	or devicechanged['$Badkamer Lamp']
) then
	if (
		otherdevices['$WC Lamp'] == 'On'
		or otherdevices['$Badkamer Lamp'] == 'On'
	) then
		if ( otherdevices['Centrale Afzuiging Laag'] == 'Off' ) then
			addCommand( 'Centrale Afzuiging Laag', 'On' )
		end
	else
		if ( otherdevices['Centrale Afzuiging Laag'] == 'On' ) then
			addCommand( 'Centrale Afzuiging Laag', 'Off' )
		end
	end
end
