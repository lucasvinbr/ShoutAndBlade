Scriptname SAB_Utils hidden

int function GetJObjectRepresentingMarkerPosition(ObjectReference marker) global
	if marker == None
		return -1
	endif

	int jReturnedMap = jMap.object()

    jMap.setForm(jReturnedMap, "Worldspace", marker.GetWorldspace())
	jMap.setForm(jReturnedMap, "ParentCell", marker.GetParentCell())
	jMap.setFlt(jReturnedMap, "PosX", marker.GetPositionX())
	jMap.setFlt(jReturnedMap, "PosY", marker.GetPositionY())
	jMap.setFlt(jReturnedMap, "PosZ", marker.GetPositionZ())

	return jReturnedMap
endfunction

bool function ApplyJObjectRepresentingMarkerPosition(ObjectReference marker, int jPosMap = -1) global
	if marker == None || jPosMap == -1 || jPosMap == 0
		return false
	endif

    Form worldForm = jMap.getForm(jPosMap, "Worldspace")
	Debug.Trace("[SAB] load Worldspace form: " + worldForm)

	Form parentCellForm = jMap.getForm(jPosMap, "ParentCell")
	Debug.Trace("[SAB] load parentcell form: " + parentCellForm)

    Cell targetCell = None
    ObjectReference targetLocationRef = None

	Cell parentCell = parentCellForm as Cell
	if parentCell == None || parentCell.GetNumRefs() <= 0
		; Debug.Trace("[SAB] got invalid parent cell for ApplyJObjectRepresentingMarkerPosition")
        ; try the worldspace path!
        ; find a way to place the marker in the worldspace, then set its position
        Worldspace markerWorld = worldForm as Worldspace
        if markerWorld == None
            Debug.Trace("[SAB] also got invalid worldspace for ApplyJObjectRepresentingMarkerPosition! aborting")
            return false
        endif

        ; requires Dylbills Papyrus Functions - https://www.nexusmods.com/skyrimspecialedition/mods/65410
        Cell[] allCellsOfWorld = DbSkseFunctions.GetAllExteriorCells(None, markerWorld)
        if allCellsOfWorld.Length <= 0
            Debug.Trace("[SAB] no valid cells found in valid worldspace for ApplyJObjectRepresentingMarkerPosition! aborting")
            return false
        endif
        
        ; find a valid cell in the obtained list
        int i = allCellsOfWorld.Length

        while i > 0
            i -= 1
            targetCell = allCellsOfWorld[i]
            if targetCell != None && targetCell.GetNumRefs() > 0
                ; break
                i = -1
            endif
        endwhile
        
    else
        targetCell = parentCell
    endif

    ; find some ref in the target cell, so that we can move the marker to it
    targetLocationRef = targetCell.GetNthRef(0)
    
    marker.MoveTo(targetLocationRef)
    marker.SetPosition(jMap.getFlt(jPosMap, "PosX"), jMap.getFlt(jPosMap, "PosY"), jMap.getFlt(jPosMap, "PosZ"))

	return true
endfunction