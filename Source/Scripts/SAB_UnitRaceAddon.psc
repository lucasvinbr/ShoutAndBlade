scriptname SAB_UnitRaceAddon extends Quest
{script for adding one or more new races for the mod.}

SAB_UnitDataHandler Property UnitHandlerScript Auto

String Property RaceUniqueID Auto
{ an ID, used to store the addon's data in the main SAB units handler. Should be unique among all race addons, so don't make it too generic}

LeveledActor Property LooksList_Male Auto
{ leveled actor with all male appearance variations of this race }
LeveledActor Property LooksList_Female Auto
{ leveled actor with all female appearance variations of this race }

event OnInit()

    ; wait until the main location handler script is set up. 
    ; Then we set up our extra locations and add them to the handler
    while !UnitHandlerScript.IsDoneSettingUp()
        Utility.Wait(1.0)
    endwhile

    UnitHandlerScript.AddNewRaceFromAddon(self)

endevent