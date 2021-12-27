scriptname SAB_SpawnersUpdater extends Quest
{ updater for things that should spawn units, like nearby commanders. }

SAB_AliasUpdater Property CmderUpdater Auto

function Initialize()
	debug.Trace("spawners updater: initialize!")
	CmderUpdater.Initialize()
	RegisterForSingleUpdate(1.0)
endfunction


Event OnUpdate()
	debug.Trace("spawners updater: start loop!")

	while true
		;debug.Trace("spawners updater loop begin")
		
		CmderUpdater.RunUpdate(0.0, 1)

		Utility.Wait(0.1)

		;debug.Trace("spawners updater loop end")
	endwhile

EndEvent