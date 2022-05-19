scriptname SAB_UnitsUpdater extends Quest
{ updater for units, actors that are spawned by troop containers. }

SAB_AliasUpdater Property UnitUpdater Auto

function Initialize()
	debug.Trace("unit updater: initialize!")
	UnitUpdater.Initialize()
	RegisterForSingleUpdate(1.0)
endfunction


Event OnUpdate()
	; debug.Trace("unit updater: start loop!")

	; while true
		;debug.Trace("unit updater loop begin")
		
		UnitUpdater.RunUpdate(0.0, 0)

		; Utility.Wait(0.35)

		;debug.Trace("unit updater loop end")
	; endwhile
	RegisterForSingleUpdate(0.15)

EndEvent