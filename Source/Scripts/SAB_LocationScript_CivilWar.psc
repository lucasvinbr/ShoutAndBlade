Scriptname SAB_LocationScript_CivilWar extends SAB_LocationScript
{ script for a location that can be captured by SAB factions... but is also used in the civil war, like the forts. }


Keyword Property locationCWKeyword Auto
{ the keyword used in this location to indicate who currently owns it in the civil war }

ObjectReference Property ImperialsContentParent Auto
{ the enable parent object used by the vanilla CW script; its name is usually something like CWGarrisonMarkerImperial }
ObjectReference Property SonsContentParent Auto
{ the enable parent object used by the vanilla CW script; its name is usually something like CWGarrisonMarkerSons }
ObjectReference Property NeutralContentParent Auto
{ the enable parent object used by the vanilla CW script. May not exist, and that's fine }

ObjectReference[] Property ExtraImperialsContentParents Auto
{ any extra enable parent objects used by the vanilla CW scripts }
ObjectReference[] Property ExtraSonsContentParents Auto
{ any extra enable parent objects used by the vanilla CW scripts }
ObjectReference[] Property ExtraNeutralContentParents Auto
{ any extra enable parent objects used by the vanilla CW scripts }

; enables/disables the default content parent
Function ToggleLocationDefaultContent(bool enableContent)
	parent.ToggleLocationDefaultContent(enableContent)

	if !enableContent
		if ImperialsContentParent
			ImperialsContentParent.Disable()
			SetEnableObjRefArray(ExtraImperialsContentParents, false)
		endif
		if SonsContentParent
			SonsContentParent.Disable()
			SetEnableObjRefArray(ExtraSonsContentParents, false)
		endif
		if NeutralContentParent
			NeutralContentParent.Disable()
			SetEnableObjRefArray(ExtraNeutralContentParents, false)
		endif
	else
		if ThisLocation.HasKeyword(locationCWKeyword)
			float cwOwnershipValue = ThisLocation.GetKeywordData(locationCWKeyword)

			; 1 is imp, 2 is sons, anything else is... neutral
			if ImperialsContentParent && cwOwnershipValue == 1.0
				ImperialsContentParent.Enable()
				SetEnableObjRefArray(ExtraImperialsContentParents, true)
			elseif SonsContentParent && cwOwnershipValue == 2.0
				SonsContentParent.Enable()
				SetEnableObjRefArray(ExtraSonsContentParents, true)
			elseif NeutralContentParent
				NeutralContentParent.Enable()
				SetEnableObjRefArray(ExtraNeutralContentParents, true)
			endif
		endif
	endif
EndFunction

Function SetEnableObjRefArray(ObjectReference[] objRefArray, bool enabled)
	int i = objRefArray.Length
	while i > 0
		i -= 1
		if enabled
			objRefArray[i].Enable()
		else
			objRefArray[i].Disable()
		endif
	endwhile
EndFunction