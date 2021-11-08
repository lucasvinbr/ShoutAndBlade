scriptname SAB_MainQuest extends Quest

SAB_SpawnerScript Property SpawnerScript Auto

; an array of jMaps, each one defining a unit's data
int jSABUnitDatasArray

; a unit data jMap just for testing
int jTestGuyData

event OnInit()
	Debug.Notification("SAB initializing...")
	
    jSABUnitDatasArray = JArray.object()
    JValue.retain(jSABUnitDatasArray, "ShoutAndBlade")

    jTestGuyData = JMap.object()
    JValue.retain(jTestGuyData, "ShoutAndBlade")
	
	Debug.Notification("SAB initialized!")
endEvent