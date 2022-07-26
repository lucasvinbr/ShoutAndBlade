Scriptname SAB_LocationScript_CivilWar extends SAB_LocationScript
{ script for a location that can be captured by SAB factions... but is also used in the civil war, like the forts. }


Keyword Property locationCWKeyword Auto
{ the keyword used in this location to indicate who currently owns it in the civil war }

ObjectReference Property ImperialsContentParent Auto
ObjectReference Property SonsContentParent Auto
ObjectReference Property NeutralContentParent Auto

; enables/disables the default content parent
Function ToggleLocationDefaultContent(bool enableContent)
	parent.ToggleLocationDefaultContent(enableContent)

	if !enableContent
		if ImperialsContentParent
			ImperialsContentParent.Disable()
		endif
		if SonsContentParent
			SonsContentParent.Disable()
		endif
		if NeutralContentParent
			NeutralContentParent.Disable()
		endif
	else
		if ThisLocation.HasKeyword(locationCWKeyword)
			float cwOwnershipValue = ThisLocation.GetKeywordData(locationCWKeyword)

			; 1 is imp, 2 is sons, anything else is... neutral
			if ImperialsContentParent && cwOwnershipValue == 1.0
				ImperialsContentParent.Enable()
			elseif SonsContentParent && cwOwnershipValue == 2.0
				SonsContentParent.Enable()
			elseif NeutralContentParent
				NeutralContentParent.Enable()
			endif
		endif
	endif
EndFunction