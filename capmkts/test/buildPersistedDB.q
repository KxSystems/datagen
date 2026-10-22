dbdir: first .z.x

([buildPersistedDB]): use `....capmkts;

t: use `kx.test;
t.setDefaults ([verbose:0b])

PWD: first system "pwd";

/ Remove the DB and go back to the original directory
cleanup: {system "cd ", PWD; system "rm -rf ", dbdir}

/ Evaluate f in the root namespace; an error counts as a failure
check: {[name; f] t.mock[`passed; @[f; ::; {0b}]]; t.assertTrue[{passed}; ([name])]}

/ Load the DB and run the common checks, mocking the tables so assertions can see them
testPersistedTables: {[label; dbdir:`C]
  system "l ", dbdir;
  t.feature label;

  t.mock[`rootFiles; all `daily`exnames`master`sym in key hsym `$dbdir];
  t.assertTrue[{rootFiles}; ([name: "files in DB root"])];

  `trade`quote`nbbo`master`exnames t.mock' get each `trade`quote`nbbo`master`exnames;
  t.assertTrue[{all 0<count each (trade; quote; nbbo; master; exnames)}; ([name: "tables have data"])];

  / Partitioned tables need the `date virtual column, so these run in the root namespace and the outcome is asserted
  / Check attributes
  check["`p attribute on sym"; {all `p = {meta[x][`sym]`a} each (trade; quote; nbbo)}];

  / Check if we can run some basic queries
  check["simple select"; {0<count asc select sum size by exch: exnames ex from trade where date=max date}];
  check["aj"; {0<count aj[`sym`time; select from trade where date=min date, sym in `MSFT`GOOG`AMZN; select sym, time, bid, ask from quote where date=min date]}];
  }

/ Is the master table stored as a flat file?
masterIsFlat: {masterfile ~ key masterfile: hsym `$dbdir, "/master"}

///////////////////////////////////////////////////////////

-1 "DB directory: ", dbdir;

buildPersistedDB dbdir;
testPersistedTables[`default; dbdir];
t.mock[`flat; masterIsFlat[]];
t.assertTrue[{flat}; ([name: "master is flat"])];
cleanup[];

/ dbdir as symbol
buildPersistedDB `$dbdir;
testPersistedTables[`dbdirSymbol; dbdir];
cleanup[];

/ dbdir as file symbol
buildPersistedDB hsym `$dbdir;
testPersistedTables[`dbdirFileSymbol; dbdir];
cleanup[];

buildPersistedDB[dbdir; ([mastertype: `splayed])];
testPersistedTables[`splayedMaster; dbdir];
t.mock[`flat; masterIsFlat[]];
t.assertFalse[{flat}; ([name: "master is splayed"])];
cleanup[];

buildPersistedDB[dbdir; 2000];
testPersistedTables[`tradesPerDay; dbdir];
cleanup[];

buildPersistedDB[dbdir; ([linked: 1b])];
testPersistedTables[`linked; dbdir];
t.mock[`linkedCols; all `master = {exec first f from meta[x] where c=`master} each (trade; quote; nbbo)];
t.assertTrue[{linkedCols}; ([name: "master linked column"])];
cleanup[];

buildPersistedDB[dbdir; ([tbls: `trade`quote])];
system "l ", dbdir;
t.feature `tbls;
t.mock[`onlyTbls; `master`trade`quote ~ tables[]];
t.assertFalse[{onlyTbls}; ([name: "tbls selection"])];
cleanup[];

t.feature `parameterValidation;
t.mock[`buildPersistedDB; buildPersistedDB];
t.mock[`dbdirs; (enlist; dbdir)];
t.assertError[{buildPersistedDB[first dbdirs; ()!(); `dummyparameter]}; "Too many parameters passed to buildPersistedDB"; ([name: "too many parameters"])];
t.assertError[{buildPersistedDB[first dbdirs; `notadictionary]}; "A numeric or a dictionary is expected as optional parameter"; ([name: "type check"])];
t.assertError[{buildPersistedDB[first dbdirs; ([tradesPerDay: 2000; invalidkey: 3])]}; "Unknown parameter(s): invalidkey"; ([name: "invalid parameter"])];

buildPersistedDB[dbdir, "/segmentdb"; ([segmentNr: 4; segmentPattern: dbdir, "/db{}"])];
testPersistedTables[`segmented; dbdir, "/segmentdb"];
cleanup[];

///////////////////////////////////////////////////////////
t.teardown[];
r: t.getReport[];
if[count f: select feature, name, status, actual: details@\:`actual from r where status<>`pass;
  -2 "Failed tests:"; -2 .Q.s f; exit 1];

-1 "All persistent DB tests passed";

if[not "-debug" in .z.x; exit 0]
