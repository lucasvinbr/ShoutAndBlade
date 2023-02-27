{
  Attempts to create more units based on unit00.
  Requires SkyrimUtils!!! https://github.com/AngryAndConflict/skyrim-utils
  Assigning any nonzero value to Result will terminate script
}
unit SAB_AddNewUnits;

interface
implementation

// include SkyrimUtils functions
uses SkyrimUtils, xEditAPI;

var
  sabFile: IwbFile;

// Called before processing
// You can remove it if script doesn't require initialization code
function Initialize: integer;
var
  baseNpc, baseGear, baseOutfit, baseLooks,
  newNpc, newGear, newOutfit, newLooks, curEditedElement,
  allLooksList, allGearsList, allUnitsList : IInterface;
  unitIndex : string;
  i: integer;

begin
  //5 is SAB's index if no other scripts are loaded before it
  sabFile := FileByLoadOrder(5);
  baseNpc := getRecordByFormID('050477EC');
  baseGear := getRecordByFormID('050477EE');
  baseOutfit := getRecordByFormID('050477EF');
  baseLooks := getRecordByFormID('050477ED');

  allLooksList := getRecordByFormID('050240E0');
  allGearsList := getRecordByFormID('050240DD');
  allUnitsList := getRecordByFormID('050240DF');

  //create new entries!
  for i := 256 to 512 do begin

    unitIndex := i;
    //pad index with zeroes
    if i < 100 then begin
      unitIndex := '0' + unitIndex;
      if i < 10 then begin
        unitIndex := '0' + unitIndex;
      end;
    end;


    //the line below copies SAB_UNIT00! But we've got to change the ID, outfits and all that
    newNpc := wbCopyElementToFile(baseNpc, sabFile, true, true);
    SetEditValue(ElementByPath(newNpc, 'EDID'), 'SAB_UnitBase_' + unitIndex); //set editor ID
    //create unitGear copy
    newGear := wbCopyElementToFile(baseGear, sabFile, true, true);
    SetEditValue(ElementByPath(newGear, 'EDID'), 'SAB_UnitGear_' + unitIndex);
    //create unitOutfit copy
    newOutfit := wbCopyElementToFile(baseOutfit, sabFile, true, true);
    SetEditValue(ElementByPath(newOutfit, 'EDID'), 'SAB_UnitOutfit_' + unitIndex);
    //create looksList copy
    newLooks := wbCopyElementToFile(baseLooks, sabFile, true, true);
    SetEditValue(ElementByPath(newLooks, 'EDID'), 'SAB_UnitLooks_' + unitIndex);

    //make the newOutfit use newGear instead of the base one
    curEditedElement := ElementByPath(newOutfit, 'INAM');
    SetNativeValue(ElementByIndex(curEditedElement, 0), FormID(newGear));

    //add new gear, unit and looks to their "allX" formLists
    curEditedElement :=
      ElementAssign(ElementByPath(allUnitsList, 'FormIDs'), HighInteger, nil, false);
    SetNativeValue(curEditedElement, FormID(newNpc));
    curEditedElement :=
      ElementAssign(ElementByPath(allGearsList, 'FormIDs'), HighInteger, nil, false);
    SetNativeValue(curEditedElement, FormID(newGear));
    curEditedElement :=
      ElementAssign(ElementByPath(allLooksList, 'FormIDs'), HighInteger, nil, false);
    SetNativeValue(curEditedElement, FormID(newLooks));

    //make the new unit use the new outfit and looks
    curEditedElement := ElementByPath(newNpc, 'TPLT');
    SetNativeValue(curEditedElement, FormID(newLooks));
    curEditedElement := ElementByPath(newNpc, 'DOFT');
    SetNativeValue(curEditedElement, FormID(newOutfit));


    log('added unit ' + unitIndex);
  end;


  Result := 0;
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
begin
  Result := 0;

  // comment this out if you don't want those messages
  { AddMessage('Processing: ' + FullPath(e)); }
  // same as above line, but using SkyrimUtils
  log('Processing: ' + FullPath(e));
  // processing code goes here

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