-- sqlite3 -csv -header domoticz.custom.db "SELECT * FROM Timer_Deltas"
-- this way we can return an object with string keys instead of a numeric array AND we can distinguish between
-- numbers and strings (csv quotes strings).

function executeQuery( sDatabase_, sQuery_ )
	local rHandle = io.popen( "/usr/bin/sqlite3 -list " .. sDatabase_ .. " 'BEGIN;" .. sQuery_ .. ";COMMIT;' 2>&1" )
	local aRows = {} ; local aRow = {}; local iRow = 1 ; local iColumn = 1

	while true do
		local sResultRow = rHandle:read( '*line' )
		if ( sResultRow == nil ) then break end

		for sColumn in sResultRow:gmatch( "([^|]+)" ) do
			aRow[iColumn] = sColumn
			iColumn = iColumn + 1
		end

		aRows[iRow] = aRow

		iRow = iRow + 1
		iColumn = 1
		aRow = {}
	end

	local oReturn = { rHandle:close() }
	if ( tonumber( oReturn[3] ) ~= 0 ) then -- check return code (0 = ok)
		print( sQuery_ )
		if ( iRow > 1 ) then
			print( aRows[iRow - 1][1] )
		else
			print( 'Error while executing query.' )
		end
		return false
	else
		return true, aRows, iRow - 1
	end
end

function executeQueryAndGetValues( sDatabase_, sQuery_ )
	local bSuccess, aRows, iCount = executeQuery( sDatabase_, sQuery_ )
	if ( bSuccess ) then
		if ( iCount > 0 ) then
			return table.unpack( aRows[1] )
		else
			return nil
		end
	else
		return false
	end
end
