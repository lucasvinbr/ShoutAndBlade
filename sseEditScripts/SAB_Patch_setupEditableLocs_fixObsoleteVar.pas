{
  Attempts to setup faction quests.
  Requires SkyrimUtils!!! https://github.com/AngryAndConflict/skyrim-utils
  Assigning any nonzero value to Result will terminate script
}
unit SAB_Patch_setupEditableLocs_fixObsoleteVar;

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
  baseEditableLocsQuest, curEditedElement, curEditedElementTwo, curEditedListElement: IInterface;
  locationIndex, propertyName, createdUnitIndex: string;
  i, j, nextAliasId: integer;

begin

  // 5 is SAB's index if no other scripts are loaded before it
  sabFile := FileByLoadOrder(5);
  baseEditableLocsQuest := getRecordByFormID('0520B606');

  curEditedListElement := ElementByPath(baseEditableLocsQuest, 'VMAD\Aliases');
  // we have already adjusted the first 4 aliases, we just have to fix the rest
  j := ElementCount(curEditedListElement);

  for i := 4 to j do
  begin

	curEditedElement := ElementByIndex(curEditedListElement, i);
	// get the properties list of the first and only script of the loc alias
	curEditedElement := ElementByIndex(ElementByPath(curEditedElement, 'Alias Scripts'), 0);
	curEditedElementTwo := ElementByPath(curEditedElement, 'Properties');
	// we know the var is index 4
	Remove(ElementByIndex(curEditedElementTwo, 4));

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
  //log('Processing: ' + FullPath(e));
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
