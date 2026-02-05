DEPTS: `finance`packing`logistics`management`hoopjumping`trading`telesales
OS: `win7`win8`osx`vista`ubuntu`redhat9

getCPUSignals: {[compNr:`j; frequency:`t; start:`t; end:`t]
    allSignals: compNr * signals: floor (end-start) % frequency;
    offsetLower: neg div[;2] offsetUpper: frequency div 3;
    ([]
        sym: raze signals#' til compNr;
        time: start+0|(offsetLower + allSignals?offsetUpper)+allSignals#frequency*til signals;
        cpu: 100&3|raze signals {[signals; x] x+sums signals?-2 -1 -1 0 0 1 1 2}' compNr?20
        / or
        / cpu: 100&3|raze (rand[20]+ sums@) each signals cut allSignals?-2 -1 -1 0 0 1 1 2
    )
  }

getInMemoryTables: {[params]
    if[1<count params; '"Too many parameters passed to getInMemoryTables"];
    / default values
    p: ([
        compNr: 1000;               / computer number
        frequency: 00:01:00.0;      / measure frequency
        avgIncNrPerComputer: 2;     / incident number per computer per day
        start: 00:00:00.0;
        end: .z.T]);

    if[not (::) ~ first params;
        if[not 99h ~ type last params; '"Dictionary is expected as parameter"];
        p,: last params];

    master: ([sym: til p `compNr] dept: p[`compNr]?DEPTS; os: p[`compNr]?OS);
    computer: update `g#sym from `time xasc getCPUSignals[p `compNr; `time$p `frequency; `time$p`start; `time$p`end];

    allIncNr: p[`compNr] * p `avgIncNrPerComputer;
    incidents: ([]
        sym: allIncNr?p `compNr;
        time:`s#p[`start] + asc allIncNr?`time$p[`end]-p`start;
        severity: allIncNr?1 2 3
    );
    (master; computer; incidents)
  } enlist ::;

export: ([getInMemoryTables])