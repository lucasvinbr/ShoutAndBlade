scriptname SAB_LocationDataAddon extends Quest
{script for adding one or more new locations for the mod.}

SAB_LocationDataHandler Property LocationHandlerScript Auto

SAB_LocationScript[] Property NewLocations Auto
{ all locations that will be added to the mod }

int indexInRegisteredAddons = -1

Function InitializeLocations()
    int i = 0

    ; set up locations
    while i < NewLocations.Length
        if !NewLocations[i].IsInitialized()
            NewLocations[i].Setup(NewLocations[i].factionScript)
        endif
        
        i += 1
    endwhile

    ; Alias[] locs = GetLocationsInAddon()
    ; int idx = locs.Length

    ; while idx > 0
    ;     idx -= 1

    ;     SAB_LocationScript nthAliasLoc = locs[idx] as SAB_LocationScript

    ;     if nthAliasLoc != None
    ;         if !nthAliasLoc.IsInitialized()
    ;             nthAliasLoc.Setup(nthAliasLoc.factionScript)
    ;         endif
    ;     endIf
    ; endWhile

EndFunction

event OnInit()

    ; wait until the main location handler script is set up. 
    ; Then we set up our extra locations and add them to the handler
    while !LocationHandlerScript.IsDoneSettingUp()
        Utility.Wait(1.0)
    endwhile

    InitializeLocations()

    LocationHandlerScript.AddNewLocationsFromAddon(self, indexInRegisteredAddons)

endevent

Function ReaddLocations()
    while !LocationHandlerScript.IsDoneSettingUp()
        Utility.Wait(1.0)
    endwhile

    InitializeLocations()

    LocationHandlerScript.AddNewLocationsFromAddon(self, indexInRegisteredAddons)
EndFunction

Function SetIndexInRegisteredAddons(int indexInRegAddons)
    indexInRegisteredAddons = indexInRegAddons
EndFunction

; Alias[] function GetLocationsInAddon()

;     Alias[] locsArray = Utility.CreateAliasArray(endingIndex)

;     int i = 0
;     int endingIndex = GetNumAliases()
;     int validEntries = 0

;     while i < endingIndex
;       this GetNthAlias part doesn't seem to work
;         SAB_LocationScript nthAliasLoc = GetNthAlias(i) as SAB_LocationScript

;         if nthAliasLoc != None
;             locsArray[i] = nthAliasLoc
;             validEntries += 1
;         endIf

;         i += 1
;     endwhile

;     Utility.ResizeAliasArray(locsArray, validEntries)

;     return locsArray

; endfunction