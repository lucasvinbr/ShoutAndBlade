scriptname SAB_MainQuest extends Quest

SAB_SpawnerScript Property SpawnerScript Auto
SAB_UnitDataHandler Property UnitDataHandler Auto

event OnInit()
	Debug.Notification("SAB initializing...")
	
    UnitDataHandler.InitializeJData()
	
	Debug.Notification("SAB initialized!")
endEvent
