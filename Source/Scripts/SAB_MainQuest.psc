scriptname SAB_MainQuest extends Quest

SAB_SpawnerScript Property SpawnerScript Auto
SAB_UnitDataHandler Property UnitDataHandler Auto
SAB_FactionDataHandler Property FactionDataHandler Auto

event OnInit()
	Debug.Notification("SAB initializing...")
	
    UnitDataHandler.InitializeJData()
	FactionDataHandler.InitializeJData()
	
	Debug.Notification("SAB initialized!")
endEvent
