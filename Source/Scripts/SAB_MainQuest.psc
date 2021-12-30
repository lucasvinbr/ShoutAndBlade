scriptname SAB_MainQuest extends Quest

SAB_SpawnerScript Property SpawnerScript Auto
SAB_UnitDataHandler Property UnitDataHandler Auto
SAB_FactionDataHandler Property FactionDataHandler Auto
SAB_LocationDataHandler Property LocationDataHandler Auto
SAB_BackgroundUpdater Property BackgroundUpdater Auto
SAB_SpawnersUpdater Property SpawnersUpdater Auto
SAB_UnitsUpdater Property UnitsUpdater Auto


bool hasInitialized = false

event OnInit()
	if !hasInitialized
		hasInitialized = true
		Debug.Notification("SAB initializing...")
		Debug.Trace("SAB OnInit begin")
		UnitDataHandler.InitializeJData()
		FactionDataHandler.InitializeJData()
		LocationDataHandler.Initialize()
		BackgroundUpdater.Initialize(FactionDataHandler.SAB_FactionQuests)
		SpawnersUpdater.Initialize()
		UnitsUpdater.Initialize()
		Debug.Notification("SAB initialized!")
	endif
endEvent
