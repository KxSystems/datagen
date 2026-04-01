MASTER: `sym xcol ("S*SSBCHF"; enlist csv) 0: .Q.rp `:::master.csv

COND: " BCEFHIKLMNOPQRTUVXZ456789";  / Sale Condition
MODE: " 456789BCEFHIKLMNOPQRTUVXZ";

/ Exchange ID to Exchange name mapping
EXNAMES: ([A: "NYSE American"; B: "NASDAQ OMX BX"; C: "NYSE National"; D: "FINRA Alternative Display Facility";
  I: "International Securities Exchange"; J: "Cboe EDGA Exchange"; K: "Cboe EDGX Exchange";
  L: "Long-Term Stock Exchange"; M: "Chicago Stock Exchange";
  N: "New York Stock Exchange"; P: "NYSE Arca"; S: "Consolidated Tape System"; T: "NASDAQ Stock Market";
  Q: "NASDAQ Stock Exchange"; V: "The Investors' Exchange"; W: "Chicago Broad Options Exchange";
  X: "NASDAQ OMX PSX"; Y: "Cboe BYX Exchange"; Z: "Cboe BZX Exchange"])

TRADEDON: (neg 1|count[MASTER]?count EXNAMES)?\:key EXNAMES

/ Default parameters for data generation
DEFAULTS: ([
  tradesPerDay: 1000;
  tbls: `trade`quote`nbbo;
  exchopen: 09:30;   / exchange open time
  exchclose: 16:00;  / exchange close time
  quotesPerTrade: 10;     / number of quotes per trade
  nbboPerTrade: 3
  ]);      / number of nbbo per trade

DEFAULTS_PERSISTED: ([start: .z.D-31; end: .z.D-1;
  tbls: `trade`quote`nbbo`daily;
  mastertype: `flat;
  holidays: ("01.01"; "01.19"; "02.16"; "05.25"; "06.19"; "07.03"; "09.07"; "10.12"; "11.11"; "11.26"; "12.25");
  segmentNr: 0; segmentPattern: "/tmp/mnt/ssd{}/testdata";
  linked: 0b])

/utils
PI:acos -1
accum:{prds 1.0,-1 _ x}
int01:{(til x)%x-1}
limit:{(neg x)|x & y}
minmax:{(min x;max x)}
normalrand:{$[x=2*n:x div 2;raze sqrt[-2*log n?1f]*/:(sin;cos)@\:(2*PI)*n?1f;-1_.z.s 1+x]}
rnd:{0.01*floor 0.5+x*100}
xrnd:{exp x * limit[2] normalrand y}
shiv:{(last x)&(first x)|asc x+-2+(count x)?5}
vol:{10+`int$x?90}
vol2:{x?100*1 1 1 1 2 2 3 4 5 8 10 15 20}

/ =========================================================
cholesky:{[x]
  n:count A:x+0.0;
  if[1>=n;:sqrt A];
  p:ceiling n%2;
  X:p#'p#A;
  Y:p _'p#A;
  Z:p _'p _A;
  T:(flip Y) mmu inv X;
  L0:n #' (.z.s X) ,\: (n-1)#0.0;
  L1:.z.s Z-T mmu Y;
  L0,(T mmu p#'L0),'L1
  }

/ =========================================================
/ paired correlation, matrix of variates, min 0.1 coeff
choleskycor:{[x:`f; y]
  x:"f"$x;y:"f"$y;
  n:count y;
  c:0.1|(n,n)#1.0,x,((n-2)#0.0),x;
  (cholesky c) mmu y
  }

/ =========================================================
/ volume profile - random times, weighted toward ends
/ x=count
volprof:{[x:`j]
  p:1.75;
  c:floor x%3;
  b:(c?1.0) xexp p;
  e:2-(c?1.0) xexp p;
  m:(x-2*c)?1.0;
  m,0.5*b,e
  }

VEX:1.0005         / average volume growth per day
CCF:0.5            / correlation coefficient

/ =========================================================
/ qx index, qb/qbb/qa/qba margins, qp price, qn position
batch:{[len:`j; p0; p1:`F; symNr:`j]
  d:xrnd[0.0003] len;
  qx:len?symNr;
  qb:rnd len?1.0;
  qa:rnd len?1.0;
  qbb:qb & -0.02 + rnd len?1.0;
  qba:qa & -0.02 + rnd len?1.0;
  n:(group qx) til symNr;
  s:p0*accum each d n;
  s:s + (p1-last each s)*{int01 count x} each s;
  qp:len#0.0;
  (qp n):rnd s;
  (qx; qb; qa; qbb; qba; qp)
  }

// @overview
// Generates constrained random walk.
//
// @param maxmove         max movement per step
// @param maxoverallmove  max movement at any time (above/below)
// @param stepNr          number of steps
// @return {float[]]}     generated random walk
genConstrRandWalk: {[maxmove:`f; maxoverallmove:`j; stepNr:`j]
  m:reciprocal maxoverallmove;
  while[any (m>p) or maxoverallmove<p:prds 1.0+maxmove*normalrand stepNr];
  p
  }

// @overview
// Returns working days between two dates.
//
// @param start       start date
// @param end         end date
// @param holidays    list of holidays
// @return {date[]]}  list of working dates
getDates:{[start:`d; end:`d; holidays]
  d:start + til 1 + end-start;
  d:d where 5> d-`week$d;
  d where not any each (5_'string d) like/:\: holidays
  }

/ =========================================================
makePrices: {[dateNr:`j]
  r:genConstrRandWalk[0.0375;3] each count[MASTER]#dateNr+1;
  r:choleskycor[CCF;1,'r];
  (MASTER[`issueprice] % first each r) * r *\: 1.1 xexp int01 dateNr+2
  }

/ =========================================================
/ day volumes
makeDailyVolumes: {[dateNr:`j]
  v:genConstrRandWalk[0.03;3;dateNr];
  a:VEX xexp neg dateNr;
  0.05|2&v*a+((reciprocal last v)-a)*int01 dateNr
  }

generateTables: {[tbls: `S; volumes:`J; prices; (quotesPerTrade:`j; nbboPerTrade:`j); (exchopen; exchclose); symNr:`j; dateidx:`j]
  (qx; qb; qa; qbb; qba; qp): batch[volumes[dateidx]; prices[;dateidx]; prices[; dateidx+1];  symNr];
  r:asc (`timespan$exchopen)+floor (`timespan$exchclose-exchopen)*volprof count qx;
  cx:volumes[dateidx]?quotesPerTrade+nbboPerTrade;
  cn:count n:where cx=0;
  sp:1=cn?20;
  s: MASTER `sym;
  res: ();
  if[`trade in tbls;
    res,: enlist ([]sym:s qx n;time:`s#shiv r n;price:qp n;size:vol cn;stop:sp;cond:cn?COND;ex:rand each TRADEDON qx n)];

  if[`quote in tbls;
    cn:count n:where cx<quotesPerTrade;
    res,: enlist ([]sym:s qx n;time:`s#r n;bid:(qp-qb)n;ask:(qp+qa)n;bsize:vol cn;asize:vol cn;mode:cn?MODE;ex:rand each TRADEDON qx n)];

  if[`nbbo in tbls;
    cn:count n:where cx>=quotesPerTrade;
    res,: enlist ([]sym:s qx n;time:`s#r n;bid:(qp-qbb)n;ask:(qp+qba)n;bsize:vol cn;asize:vol cn)];
  res
  }

generateAndSave: {[dbpref:`C; tbls: `S; dst:`s; generator; linked:`b;dates:`D; dateidx:`j]
  d: dates dateidx;

  tlist: {update sym:`p#sym from `sym xasc x} each generator dateidx;
  if[linked;
    tlist: {[s;t] update master:`master!s?sym from t}[MASTER `sym] each tlist];
  (.Q.dd[hsym `$dbpref, "/", string d] each tbls ,' `) set' .Q.en[dst] each tlist;

  if[`trade ~ first tbls;
    :`date xcols 0!select date: d, open:first price,high:max price,
      low:min price,close:last price,price:sum price*size,sum size by sym from first tlist];
  }

processOptParam:{[allowedKeys;optparam]
  if[.Q.ty[optparam] in "HIJ";
    :([tradesPerDay: "j"$optparam])]; / numeric parameter interpreted as trades per day;];

  if[99h = type optparam;
    unknownParams: (key optparam) except allowedKeys;
    if[count unknownParams; '"Unknown parameter(s): ", "," sv string unknownParams];
    if[`tbls in key optparam;
      optparam: (`tbls _ optparam), ([tbls: $[count optparam `tbls; (), optparam `tbls; `$()]]); / a symbol or a general empty list are also accepted
      unknownTbls: optparam[`tbls] except `trade`quote`nbbo`daily;
      if[count unknownTbls; '"Unknown table(s) in tbls parameter: ", "," sv string unknownTbls]];
    :optparam];

  '"A numeric or a dictionary is expected as optional parameter";
  }


// @kind function
// @fileoverview returns in-memory tables trade/quote/nbbo
// @param params {list} optional parameters as a single-element list.
//                      If a numeric is provided, it is interpreted as the number of trades per day.
//                      if a dictionary is provided, then possible keys:
//                        tradesPerDay:   number of trades per day.
//                        exchopen:       exchange open time (default 09:30),
//                        exchclose:      exchange close time (default 16:00),
//                        quotesPerTrade: number of quotes per trade (default 10),
//                        nbboPerTrade:   number of nbbo per trade (default 3),
getInMemoryTables: ('[{[params]
  if[1<count params; '"Too many parameters passed to getInMemoryTables"];
  p: DEFAULTS;
  if[not (::) ~ first params; p,: processOptParam[key p; last params]];

  symNr: count MASTER;
  volumes: floor (symNr*p[`tradesPerDay]*p[`quotesPerTrade]+p `nbboPerTrade) * makeDailyVolumes 1;
  prices: makePrices 1;
  ({update `g#sym from x} each generateTables[p `tbls; volumes; prices; p `quotesPerTrade`nbboPerTrade; p`exchopen`exchclose; symNr; 0]),
    (`sym xkey MASTER; EXNAMES)
  }; enlist]);

// @kind function
// @fileoverview builds a date-partitioned trade/quote/nbbo database
// @param params {list} list of size between 1 and 3:
//                     The first element is the root of the database to be created.
//                     The second element, if provided, is a dictionary with possible keys:
//                        tradesPerDay:   number of trades per day.
//                        start:          begin date (default 31 days ago),
//                        end:            end date (default yesterday),
//                        exchopen:       exchange open time (default 09:30),
//                        exchclose:      exchange close time (default 16:00),
//                        holidays:       list of holidays (default US market holidays),
//                        segmentNr:      number of segments
//                        segmentPattern: pattern for the segments, e.g. "/mnt/ssd{}/testdb"
//                        quotesPerTrade: number of quotes per trade (default 10),
//                        nbboPerTrade:   number of nbbo per trade (default 3),
buildPersistedDB: ('[{[params]
  if[2<count params; '"Too many parameters passed to buildPersistedDB"];
  if[(::) ~ first params;
    '"Destination directory must be provided as first parameter to buildPersistedDB"];
  dst: first params;
  p: DEFAULTS, DEFAULTS_PERSISTED;
  if[1 < count params;
    p,: processOptParam[key p; last params];
    if[not p[`mastertype] in `flat`splayed;
      '"Invalid mastertype parameter, expected `flat or `splayed"]];

  dateNr: count dates: getDates[p`start; p`end; p`holidays];
  symNr: count MASTER;
  volumes: floor (symNr*p[`tradesPerDay]*p[`quotesPerTrade]+p[`nbboPerTrade]) * makeDailyVolumes dateNr;
  prices: makePrices dateNr;

  generator: generateTables[p `tbls;volumes; prices; p `quotesPerTrade`nbboPerTrade; p`exchopen`exchclose; symNr];
  dbprefs: $[p `segmentNr; [
    ssr[p[`segmentPattern];"{}"] each string til[dateNr] mod p `segmentNr];
    dateNr#enlist dst];
  dst: hsym `$dst;
  daily: raze dbprefs generateAndSave[;p[`tbls] except `daily; dst; generator; p `linked; dates; ]' til dateNr;

  if[all `daily`trade in p`tbls; .Q.dd[dst;`daily`] set .Q.en[dst] daily];
  .Q.dd[dst;`master, $[p[`mastertype] ~ `splayed;`;()]] set .Q.en[dst] MASTER;
  .Q.dd[dst;`exnames] set EXNAMES;
  if[p `segmentNr; (` sv dst,`par.txt) 0: distinct dbprefs];
  }; enlist]);


export: ([getInMemoryTables; buildPersistedDB])
