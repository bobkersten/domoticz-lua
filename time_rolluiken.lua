---------------------------------------------------------------------------------------------------------------------------
-- Tijden in seconden
---------------------------------------------------------------------------------------------------------------------------
local iHelemaalDichtTijd = 60
local iHalfOpenTijd = 25
local iKierOpenTijd = 5
local iTussenRolluikenTijd = 25
---------------------------------------------------------------------------------------------------------------------------

local sLastUpdate = otherdevices_lastupdate['Rolluik Badkamer'] -- is used in all situations
if (
	sLastUpdate == nil
	or timeOffset( sLastUpdate ) > ( 15 * 60 ) -- 15 minutes
) then
	if ( tonumber( otherdevices_svalues['Entree Sensor Lichtsterkte'] ) < 25 ) then
		-- Hiet is DONKER buiten.
		if ( otherdevices['Iemand Aanwezig'] == 'On' ) then
			-- Er is WEL iemand htuis thuis.
			-- De rolluiken worden op een kier gezet voor de ontluchting.
			if ( retrieve( 'Rolluiken', 'Stand' ) ~= 'Donker en thuis' ) then
				addCommand( "Rolluik Badkamer", "On AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Badkamer", "Off AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Badkamer", "Stop AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iKierOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Joep", "On AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Joep", "Off AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Joep", "Stop AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iKierOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Stef", "On AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Stef", "Off AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Stef", "Stop AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iKierOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Bob en Elvira", "On AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Bob en Elvira", "Off AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Bob en Elvira", "Stop AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iKierOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				store( 'Rolluiken', 'Stand', 'Donker en thuis' )
			end
		else
			-- Er is NIEMAND thuis.
			-- De rolluiken worden deels open gezet voro NOG meer ontluchting.
			if ( retrieve( 'Rolluiken', 'Stand' ) ~= 'Donker en niemand thuis' ) then
				addCommand( "Rolluik Badkamer", "On AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Badkamer", "Off AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Badkamer", "Stop AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iHalfOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Joep", "On AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Joep", "Off AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Joep", "Stop AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iHalfOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Stef", "On AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Stef", "Off AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Stef", "Stop AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iHalfOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Bob en Elvira", "On AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Bob en Elvira", "Off AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Bob en Elvira", "Stop AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iHalfOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				store( 'Rolluiken', 'Stand', 'Donker en niemand thuis' )
			end
		end
	else
		-- Het is LICHT buiten.
		if ( otherdevices['Iemand Aanwezig'] == 'On' ) then
			-- Er is WEL iemand thuis.
			-- De rolluiken worden op een kier gezet voor de ontluchting. De badkamer rolluik wordt wel
			-- verder open gezet.
			if ( retrieve( 'Rolluiken', 'Stand' ) ~= 'Licht en thuis' ) then
				addCommand( "Rolluik Badkamer", "On AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Badkamer", "Off AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Badkamer", "Stop AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iHalfOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Joep", "On AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Joep", "Off AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Joep", "Stop AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iKierOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Stef", "On AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Stef", "Off AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Stef", "Stop AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iKierOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Bob en Elvira", "On AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Bob en Elvira", "Off AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Bob en Elvira", "Stop AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iKierOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				store( 'Rolluiken', 'Stand', 'Licht en thuis' )
			end
		else
			-- Er is NIEMAND thuis.
			-- De rolluiken worden deels open gezet voro NOG meer ontluchting.
			if ( retrieve( 'Rolluiken', 'Stand' ) ~= 'Licht en niemand thuis' ) then
				addCommand( "Rolluik Badkamer", "On AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Badkamer", "Off AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Badkamer", "Stop AFTER " .. tostring( ( 1 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iHalfOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Joep", "On AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Joep", "Off AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Joep", "Stop AFTER " .. tostring( ( 2 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iHalfOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Stef", "On AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Stef", "Off AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Stef", "Stop AFTER " .. tostring( ( 3 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iHalfOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				addCommand( "Rolluik Kamer Bob en Elvira", "On AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECOND" )
				addCommand( "Rolluik Kamer Bob en Elvira", "Off AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) + iHelemaalDichtTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )
				addCommand( "Rolluik Kamer Bob en Elvira", "Stop AFTER " .. tostring( ( 4 * iTussenRolluikenTijd ) + iHelemaalDichtTijd + iHalfOpenTijd ) .. " SECONDS REPEAT 3 INTERVAL 0.5 SECONDS" )

				store( 'Rolluiken', 'Stand', 'Licht en niemand thuis' )
			end
		end
	end
end
