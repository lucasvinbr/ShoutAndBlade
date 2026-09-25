{
Attempts to add the selected entries to the leveled list.
Apply this script to npcs only!!!
Requires SkyrimUtils!!! https://github.com/AngryAndConflict/skyrim-utils
Assigning any nonzero value to Result will terminate script
}
unit SAB_AddEntriesToLeveledList;

interface
implementation

// include SkyrimUtils functions
uses SkyrimUtils, xEditAPI;

var
    targetRaceAddonFile: IwbFile;
    targetLeveledList, leveledListContent: IInterface;


// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
    // we'll probably have to change this every time, as it should change depending on how many new plugins we have loaded after our race addon.
    // FileCount - 1 is the last plugin!
    targetRaceAddonFile := FileByIndex(FileCount - 1);
    log(GetFileName(targetRaceAddonFile));

    targetLeveledList := MainRecordByEditorID(GroupBySignature(targetRaceAddonFile, 'LVLN'), 'SAB_LooksList_DarkElf_F');
    log(Name(targetRaceAddonFile));
    log(Name(targetLeveledList));
    leveledListContent := ElementByPath(targetLeveledList, 'Leveled List Entries');
    log(Name(leveledListContent));
    Result := 0;
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
    curEditedElement: IInterface;
begin
    Result := 0;

    // comment this out if you don't want those messages
    { AddMessage('Processing: ' + FullPath(e)); }
    // same as above line, but using SkyrimUtils
    log('Processing: ' + FullPath(e));
    // processing code goes here

    // create new empty entry in the leveled list...
    curEditedElement :=
      ElementAssign(leveledListContent, HighInteger, nil, false);
    curEditedElement := ElementByPath(curEditedElement, 'LVLO - Base Data');

    SetNativeValue(ElementByPath(curEditedElement, 'Level'), 1);
    SetNativeValue(ElementByPath(curEditedElement, 'Count'), 1);
    SetNativeValue(ElementByPath(curEditedElement, 'Reference'), FormID(e));

end;

// Called after processing
function Finalize: integer;
begin
    Result := 0;

    // it will check if SkyrimUtils data variables were used and will clean them from memory
    // also finishes any needed internal processes like log()
    FinalizeUtils();

end;

end.
