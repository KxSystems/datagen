os: use`os;

t: use `kx.test;
t.setDefaults ([verbose:0b])

.t.eol:` sv enlist"";

tp: os.proc.start["q ./capmkts/test/mocktp.q -p localhost:0W "; / use a free port
    ([async:1b; stdin:`pipe; stdout:`text; stderr:`text; env: os.env[], ([KX_TTY: enlist "1"])])];
.z.exit: {[x] tp[`stdin] "exit 0", .t.eol}
read0 tp`stdout;    / discard startup messages

tp[`stdin] "\\p", .t.eol;     / fetch the port obtained
freeport: -1_last read0 tp`stdout;

-1 "mock TP started on port ", freeport;

tpH: hopen "J"$freeport

-1 "starting realtime streaming";
([streamToPubSub]): use `$"....capmkts";
batchsize: 10
streamToPubSub[tpH; batchsize; ([exchopen: 09:30:00; exchclose: 09:30:10])]
-1 "realtime streaming finished";

/ Queries run against the mock TP, so evaluate them here and assert on the outcome
t.feature `streamToPubSub;
t.mock[`tablesPopulated; tpH "all 0 < count each value each `master`trade`quote`nbbo"];
t.assertTrue[{tablesPopulated}; ([name: "tables have data"])];

t.mock[`batchSizeOk; first all batchsize=-1 _ tpH "select count i by batchidx from trade"];
t.assertTrue[{batchSizeOk}; ([name: "batch size"])];

t.mock[`realtimeOk; first all 0D00:00:00.01 > tpH "select last rcvt-time by batchidx from trade"];
t.assertTrue[{realtimeOk}; ([name: "realtime: delay below threshold"])];

t.teardown[];
r: t.getReport[];
if[count f: select feature, name, status, actual: details@\:`actual from r where status<>`pass;
  -2 "Failed tests:"; -2 .Q.s f; exit 1];

-1 "All streamToPubSub tests passed";

if[not any "-debug" ~/: .z.x; exit 0]
