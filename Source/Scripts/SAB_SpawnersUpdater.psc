scriptname SAB_SpawnersUpdater extends Quest
{ updater for things that should spawn units, like nearby commanders. }

SAB_AliasUpdater Property CmderUpdater Auto
SAB_AliasUpdater Property LocationUpdater Auto

function Initialize()
	debug.Trace("[SAB] spawners updater: initialize!")
	CmderUpdater.updateTypeIndex = 1
	LocationUpdater.updateTypeIndex = 1
	; cmder updater is attached to this quest as well, so there's no need to register for updates there
	CmderUpdater.Initialize(false)
	LocationUpdater.Initialize(true)
	RegisterForSingleUpdate(1.0)
endfunction


Event OnUpdate()

	; nothing here for now! 
	; We're just calling update to update other scripts attached to this quest as well
	RegisterForSingleUpdate(0.2)

EndEvent