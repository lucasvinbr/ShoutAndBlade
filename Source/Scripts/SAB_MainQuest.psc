scriptname SAB_MainQuest extends Quest

SAB_SpawnerScript Property SpawnerScript Auto

; an array of jMaps, each one defining a unit's data
int Property jSABUnitDatasArray Auto

; a unit data jMap just for testing
int Property jTestGuyData Auto

event OnInit()
	Debug.Notification("SAB initializing...")
	
    jSABUnitDatasArray = JArray.object()
    JValue.retain(jSABUnitDatasArray, "ShoutAndBlade")

    jTestGuyData = JMap.object()
    JValue.retain(jTestGuyData, "ShoutAndBlade")
	
	Debug.Notification("SAB initialized!")
endEvent



int Function GetUnitIndexByUnitName(string name)
    int i = JArray.count(jSABUnitDatasArray)

    while i > 0
        i -= 1

        int unitData = JArray.getObj(jSABUnitDatasArray, i)
        if unitData != 0
            string unitName = jMap.getStr(unitData, "Name", "")

            if unitName == name
                return i
            endif
        endif
    endwhile

    return -1
EndFunction