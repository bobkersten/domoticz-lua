if (
	devicechanged['Bovenste Groepen']
	or devicechanged['Onderste Groepen']
) then
	local iEigenVerbruikDeviceId = otherdevices_idx['Eigen Verbruik']
	local oBovensteGroepenEnergy = splitkWhValues( otherdevices['Bovenste Groepen'] )
	local oOndersteGroepenEnergy = splitkWhValues( otherdevices['Onderste Groepen'] )

	addCommand( 'UpdateDevice', tostring( iEigenVerbruikDeviceId ) .. '|0|' .. tostring( oBovensteGroepenEnergy.watt + oOndersteGroepenEnergy.watt ) .. ';' .. tostring( oBovensteGroepenEnergy.total + oOndersteGroepenEnergy.total ) )

	-- DEBUG
	addCommand( 'UpdateDevice', '835|0|' .. tostring( oBovensteGroepenEnergy.total + oOndersteGroepenEnergy.total ) )

end
