scriptname SAB_LocationDataAddon extends Quest
{script for adding one or more new locations for the mod.}

SAB_LocationDataHandler Property LocationHandlerScript Auto

SAB_LocationScript[] Property NewLocations Auto
{ all locations that will be added to the mod }

Function InitializeLocations()
    int i = 0

    ; set up locations
    while i < NewLocations.Length
        NewLocations[i].Setup(NewLocations[i].factionScript)
        
        i += 1
    endwhile

EndFunction



event OnInit()

    ; wait until the main location handler script is set up. 
    ; Then we set up our extra locations and add them to the handler
    while !LocationHandlerScript.IsDoneSettingUp()
        Utility.Wait(1.0)
    endwhile

    InitializeLocations()

    LocationHandlerScript.AddNewLocationsFromAddon(self)

endevent