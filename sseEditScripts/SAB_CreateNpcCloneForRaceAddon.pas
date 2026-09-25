{
Attempts to create a "stripped" clone of an npc, for race addons.
Apply this script to npcs only!!!
Requires SkyrimUtils!!! https://github.com/AngryAndConflict/skyrim-utils
Assigning any nonzero value to Result will terminate script
}
unit SAB_CreateBaseUnitClone;

interface
implementation

// include SkyrimUtils functions
uses SkyrimUtils, xEditAPI;

var
    sabFile: IwbFile;
    targetRaceAddonFile: IwbFile;
    baseNpc: IInterface;


procedure UpdateUnitElement(elementSignature: string; sourceUnit: IInterface; targetUnit: IInterface);
var
    sourceElement, targetElement : IInterface;
begin
    sourceElement := ElementBySignature(sourceUnit, elementSignature);
    targetElement := ElementBySignature(targetUnit, elementSignature);

    if not Assigned(sourceElement) then begin
        //source unit does not have the field!
        //if target unit has it, we should remove it
        if Assigned(targetElement) then begin
            log('remove ' + elementSignature + ' from target as source does not have it');
            Remove(targetElement);
            Exit;
        end;
    end else begin
        //source unit has the field!
        //if target unit doesn't, we should create it
        if not Assigned(targetElement) then begin
            targetElement := Add(targetUnit, elementSignature, false);
        end;
    end;

    ElementAssign(targetElement, LowInteger, sourceElement, false);
end;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
begin
    // yep, just count it from the first plugin entry
    sabFile := FileByLoadOrder(13);
    log(GetFileName(sabFile));

    // we'll probably have to change this every time, as it should change depending on how many new plugins we have loaded after our race addon.
    // FileCount - 1 is the last plugin!
    targetRaceAddonFile := FileByIndex(FileCount - 4);
    log(GetFileName(targetRaceAddonFile));
    baseNpc := RecordByFormID(sabFile, StrToInt('$0900AB37'), true);
    log(Name(baseNpc));

    Result := 0;
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
    newNpc, targetNpcFile, curEditedElement: IInterface;
    newUnitName: string;
begin
    Result := 0;

    // comment this out if you don't want those messages
    { AddMessage('Processing: ' + FullPath(e)); }
    // same as above line, but using SkyrimUtils
    log('Processing: ' + FullPath(e));
    // processing code goes here

    targetNpcFile := GetFile(e);
    AddMasterIfMissing(targetRaceAddonFile, GetFileName(targetNpcFile));

    // create copy of npc...
    newNpc := wbCopyElementToFile(e, targetRaceAddonFile, true, true);

    //copy configuration data from base unit
    UpdateUnitElement('ACBS', baseNpc, newNpc);

    //copy faction data from base unit
    UpdateUnitElement('SNAM', baseNpc, newNpc);

    //copy effect (magic?) data from base unit
    UpdateUnitElement('SPLO', baseNpc, newNpc);

    //copy perk data from base unit
    UpdateUnitElement('PRKR', baseNpc, newNpc);

    //copy skill data from base unit
    UpdateUnitElement('DNAM', baseNpc, newNpc);

    //copy default outfit from base unit
    UpdateUnitElement('DOFT', baseNpc, newNpc);

    //copy default crime faction from base unit
    UpdateUnitElement('CRIF', baseNpc, newNpc);

    //copy template from base unit
    UpdateUnitElement('TPLT', baseNpc, newNpc);

    //copy default package list from base unit
    UpdateUnitElement('DPLT', baseNpc, newNpc);

    //if new npc has items, remove them!
    curEditedElement := ElementByPath(newNpc, 'Items');
    if Assigned(curEditedElement) then begin
        Remove(curEditedElement);
    end;

    // set new npc's editor id based on their race and name
    curEditedElement := LinksTo(ElementBySignature(newNpc, 'RNAM'));
    log(GetEditValue(ElementBySignature(curEditedElement, 'EDID')));
    newUnitName := 'SAB_' + GetEditValue(ElementBySignature(curEditedElement, 'EDID')) + '_' + GetEditValue(ElementBySignature(newNpc, 'FULL'));
    SetEditValue(ElementBySignature(newNpc, 'EDID'), newUnitName);

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
