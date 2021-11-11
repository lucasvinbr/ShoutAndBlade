scriptname SAB_MCM extends SKI_ConfigBase

SAB_MainQuest Property SAB_MainQuest Auto

int editedUnitIndex = 0
int editedFactionIndex = 0
int editedZoneIndex = 0

string editedUnitName = ""

Event OnConfigInit()
    Pages = new string[5]
    Pages[0] = "My troops"
    Pages[1] = "Edit units"
    Pages[2] = "Edit factions"
    Pages[3] = "Edit zones"
    Pages[4] = "Load/Save data"
EndEvent

Event OnPageReset(string page)
    ; check page, add options according to which page was picked and all that
    if page == Pages[0] || page == "" ; my troops
        SetupMyTroopsPage()
    elseif page == Pages[1] ; edit units
        SetupEditUnitsPage()
    elseif page == Pages[2] ; edit factions
        SetupEditFactionsPage()
    elseif page == Pages[3] ; edit zones
        SetupEditZonesPage()
    elseif page == Pages[4] ; load/save data
        SetupLoadSaveDataPage()
    endif
EndEvent

Function SetupMyTroopsPage()
    ; code
EndFunction

Function SetupEditUnitsPage()
    SetCursorFillMode(TOP_TO_BOTTOM)

    AddMenuOptionST("UNITEDIT_CUR_UNIT", "Current Unit", editedUnitName)
    

    AddHeaderOption("Base Info")
EndFunction

Function SetupEditFactionsPage()
    ; code
EndFunction

Function SetupEditZonesPage()
    ; code
EndFunction

Function SetupLoadSaveDataPage()
    ; code
EndFunction