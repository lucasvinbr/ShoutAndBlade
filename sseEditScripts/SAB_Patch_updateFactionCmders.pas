{
  Attempts to update some values of faction commanders.
  Requires SkyrimUtils!!! https://github.com/AngryAndConflict/skyrim-utils
  Assigning any nonzero value to Result will terminate script
}
unit SAB_Patch_updateFactionCmders;

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
  baseFacQuest, facAliases, aliasScripts, scriptProperties,
  curEditedElement, curEditedFacQuest, bkgndCmderUpdaterQuest,
  allFacQuestsList : IInterface;
  facIndex : string;
  i,j,k,l: integer;

begin
  //5 is SAB's index if no other scripts are loaded before it
  sabFile := FileByLoadOrder(5);
  baseFacQuest := getRecordByFormID('0506B3F4');

  allFacQuestsList := getRecordByFormID('050755F9');

  bkgndCmderUpdaterQuest := getRecordByFormID('051CE9FE');

  //update entries!
  for i := 0 to 100 do begin

	facIndex := i;

	curEditedFacQuest := LinksTo(ElementByIndex(ElementByPath(allFacQuestsList, 'FormIDs'), i));

	// get aliases scripts list...
	facAliases := ElementByPath(curEditedFacQuest, 'VMAD\Aliases');

	for j := 0 to ElementCount(facAliases) do
	begin
		curEditedElement := ElementByIndex(facAliases, j);
		aliasScripts := ElementByPath(curEditedElement, 'Alias Scripts');

		for k := 0 to ElementCount(aliasScripts) do
		begin
			curEditedElement := ElementByIndex(aliasScripts, k);

			if GetEditValue(ElementByPath(curEditedElement, 'ScriptName')) = 'SAB_CommanderScript' then begin
				// alias updater is the first script property
				curEditedElement := ElementByPath(curEditedElement, 'Properties');
				SetNativeValue(ElementByPath(ElementByIndex(curEditedElement, 0), 'Value\Object Union\Object v2\FormID'), FormID(bkgndCmderUpdaterQuest));
				break;
			end;
		end;

	end;

	log('updated fac ' + facIndex);
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