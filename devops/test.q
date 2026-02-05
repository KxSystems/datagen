([getInMemoryTables]): use `$"...devops";

fail: {-2 x;'`failed}

testInMemoryTables: {[(master; computer; incidents)]
  / Check if all tables have data
  if[not all count each (master; computer; incidents);
    fail "empty table(s) found"];

  /check attributes
  if[not all `g = {meta[x][`sym]`a} each enlist computer;
    fail "missing `g attribute from `sym"];

  if[not all `s = {meta[x][`time]`a} each (computer; incidents);
    fail "missing `s attribute from `time"];

    / Check if we can run some basic queries
  if[0=count asc select avg cpu by sym from computer where time within (-00:10 00:00) + last time;
    fail "simple select failed"];
  }

///////////////////////////////////////////////////////////
testInMemoryTables getInMemoryTables[]

/ Check if we can pass trades per day parameter
testInMemoryTables getInMemoryTables[([compNr: 500])]

res: .[getInMemoryTables;(()!(); `dummyparameter); ::]
if[not res like "Too many parameters passed to getInMemoryTables";
  fail "Too many parameters check failure"];

res: @[getInMemoryTables; `notadictionary; ::]
if[not res like "Dictionary is expected as parameter";
  fail "Dictionary type check failure"];

-1 "All in-memory tests passed";

exit 0;