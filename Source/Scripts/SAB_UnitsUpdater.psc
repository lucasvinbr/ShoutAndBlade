scriptname SAB_UnitsUpdater extends Quest
{ updater for units, actors that are spawned by troop containers. }

SAB_AliasUpdater Property UnitUpdater Auto

function Initialize()
	debug.Trace("unit updater: initialize!")
	; unit alias updater is attached to this quest as well, so there's no need to register for updates there
	UnitUpdater.Initialize(false)
	RegisterForSingleUpdate(1.0)
endfunction


Event OnUpdate()
	; nothing here for now! 
	; We're just calling update to update other scripts attached to this quest as well
	RegisterForSingleUpdate(0.1)

EndEvent