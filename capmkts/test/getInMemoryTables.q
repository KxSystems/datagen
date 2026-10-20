([getInMemoryTables]): use `$"....capmkts";

t: use `kx.test;
t.setDefaults ([verbose:0b])

/ Run the common table checks, mocking the tables so assertions can see them
testInMemoryTables: {[label; tabs]
  t.feature label;

  `trade`quote`nbbo`master`exnames t.mock' tabs;
  t.assertTrue[{all 0<count each (trade; quote; nbbo; master; exnames)}; ([name: "tables have data"])];

  / Check attributes
  t.assertTrue[{all `g = {meta[x][`sym]`a} each (trade; quote; nbbo)}; ([name: "`g attribute on sym"])];
  t.assertTrue[{all `s = {meta[x][`time]`a} each (trade; quote; nbbo)}; ([name: "`s attribute on time"])];

  / Check if we can run some basic queries
  t.assertTrue[{0<count asc select sum size by exch: exnames ex from trade}; ([name: "simple select"])];
  t.assertTrue[{0<count aj[`sym`time; select from trade where sym in `MSFT`GOOG`AMZN; select sym, time, bid, ask from quote]}; ([name: "aj"])];
  }

///////////////////////////////////////////////////////////
testInMemoryTables[`default; getInMemoryTables[]]

/ Check if we can pass trades per day parameter
testInMemoryTables[`tradesPerDay; getInMemoryTables[2000]]

t.feature `parameterValidation
t.mock[`getInMemoryTables; getInMemoryTables];
t.assertError[{getInMemoryTables[2000; `dummyparameter]}; "Too many parameters passed to getInMemoryTables"; ([name: "too many parameters"])];
t.assertError[{getInMemoryTables `notadictionary}; "A numeric or a dictionary is expected as optional parameter"; ([name: "dictionary type check"])];
t.assertError[{getInMemoryTables ([tradesPerDay: 2000; invalidkey: 3])}; "Unknown parameter(s): invalidkey"; ([name: "invalid parameter"])];

/ Check if we can pass exchange open/close times of different formats (minute vs second)
exchopen: 10:00;
exchclose: 15:00:00;
testInMemoryTables[`exchangeHours; getInMemoryTables ([tradesPerDay: 2000; exchopen; exchclose])]
t.mock[`exchopen; exchopen];
t.mock[`exchclose; exchclose];
t.assertFalse[{count select from trade where time<exchopen}; ([name: "no trade before exchopen"])];
t.assertFalse[{count select from trade where time>exchclose}; ([name: "no trade after exchclose"])];

t.teardown[];
r: t.getReport[];
if[count f: select feature, name, status, details from r where not status=`pass;
  -2 "Failed tests:"; -2 .Q.s f; exit 1];

-1 "All in-memory tests passed";

if[not any "-debug" ~/: .z.x; exit 0]
