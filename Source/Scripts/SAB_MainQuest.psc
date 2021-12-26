scriptname SAB_MainQuest extends Quest

SAB_SpawnerScript Property SpawnerScript Auto
SAB_UnitDataHandler Property UnitDataHandler Auto
SAB_FactionDataHandler Property FactionDataHandler Auto
SAB_BackgroundUpdater Property BackgroundUpdater Auto
SAB_CloseByUpdater Property CloseByUpdater Auto

event OnInit()
	Debug.Notification("SAB initializing...")
	
    UnitDataHandler.InitializeJData()
	FactionDataHandler.InitializeJData()
	BackgroundUpdater.Initialize(FactionDataHandler.SAB_FactionQuests)
	CloseByUpdater.Initialize()
	
	Debug.Notification("SAB initialized!")
endEvent
