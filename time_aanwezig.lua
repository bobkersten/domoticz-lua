-- Als beide deuren al minimaal 2 minuten (instelbaar in z-wave config scherm van PIR detectoren) niet zijn
-- open of dicht geweest dan faken we een PIR update.
if (
	otherdevices['$Entree Sensor Activiteit'] == 'On'
	or otherdevices['$Keuken Sensor Activiteit'] == 'On'
) then
	if (
		timeOffset( otherdevices_lastupdate['$Achterdeur Sensor'] ) > ( 3 * 60 )
		and timeOffset( otherdevices_lastupdate['$Voordeur Sensor'] ) > ( 3 * 60 )
		and oDatetime.minutes % 3 == 0
	) then
		if ( otherdevices['$Entree Sensor Activiteit'] == 'On' ) then
			devicechanged = { ['$Entree Sensor Activiteit'] = 'On' }
		end
		if ( otherdevices['$Keuken Sensor Activiteit'] == 'On' ) then
			devicechanged = { ['$Keuken Sensor Activiteit'] = 'On' }
		end
		require "device_aanwezig"
	end
end
