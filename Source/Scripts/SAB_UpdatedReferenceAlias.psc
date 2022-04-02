scriptname SAB_UpdatedReferenceAlias extends ReferenceAlias
{ a reference alias that should be updated regularly }

SAB_AliasUpdater Property AliasUpdater Auto
int Property indexInUpdater Auto Hidden


bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)
	Debug.Trace("updated ref alias: override me!")
	return true
EndFunction

; enables or disables alias updates
Function ToggleUpdates(bool updatesEnabled)
	
	if updatesEnabled
		if indexInUpdater == -1
			indexInUpdater = AliasUpdater.RegisterAliasForUpdates(self)
		endif
	elseif !updatesEnabled
		if indexInUpdater != -1
			AliasUpdater.UnregisterAliasFromUpdates(indexInUpdater)
			indexInUpdater = -1
		endif
	endif

EndFunction

; clears the alias and stops updates
Function ClearAliasData()
	; debug.Trace("SAB_UpdatedReferenceAlias: clear data!")
	Clear()

	ToggleUpdates(false)
EndFunction