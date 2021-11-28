{
  Attempts to create duplicateItemLists for more units based on unit00.
  Requires SkyrimUtils!!! https://github.com/AngryAndConflict/skyrim-utils
  Assigning any nonzero value to Result will terminate script
}
unit SAB_Patch_addDuplicateItemLists;

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
  baseDups,
  newDups, curEditedElement, curEditedUnit,
  allUnitsList, allDupsList : IInterface;
  unitIndex : string;
  i: integer;

begin
  //6 is SAB's index if no other scripts are loaded before it
  sabFile := FileByLoadOrder(6);
  baseDups := getRecordByFormID('06056EF2');

  allUnitsList := getRecordByFormID('060240DF');
  allDupsList := getRecordByFormID('0605BFF4');

  //create new entries!
  for i := 1 to 255 do begin

    unitIndex := i;
    //pad index with zeroes
    if i < 100 then begin
      unitIndex := '0' + unitIndex;
      if i < 10 then begin
        unitIndex := '0' + unitIndex;
      end;
    end;

    //create dupItemsList copy
    newDups := wbCopyElementToFile(baseDups, sabFile, true, true);
    SetEditValue(ElementByPath(newDups, 'EDID'), 'SAB_UnitDuplicateItems_' + unitIndex);

    //add new dup lists to the "allDups" formList
    curEditedElement :=
      ElementAssign(ElementByPath(allDupsList, 'FormIDs'), HighInteger, nil, false);
    SetNativeValue(curEditedElement, FormID(newDups));
	
	//add new dup list to its respective unit's inventory
	curEditedUnit := LinksTo(ElementByIndex(ElementByPath(allUnitsList, 'FormIDs'), i));

  //create the inventory data entry
  curEditedElement := Add(curEditedUnit, 'Items', false);

  //then add the dup entry
  curEditedElement := ElementByIndex(curEditedElement, 0);
  //curEditedElement :=
  //    ElementAssign(curEditedElement, HighInteger, nil, false);
  SetNativeValue(ElementByPath(curEditedElement, 'CNTO\Item'), FormID(newDups));
  SetEditValue(ElementByPath(curEditedElement, 'CNTO\Count'), 1);


    log('updated unit ' + unitIndex);
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