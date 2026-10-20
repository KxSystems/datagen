# Capital market data generator

This module is designed to generate synthetic capital market data, including `trade`, `quote`, and `nbbo` tables, along with instrument and exchange metadata.

## Quickstart

<details>
<summary>Note: OS module dependency</summary>

This module uses the `OS` module, which is installed by default by recent KDB-X installers. If the `OS` module is not installed, update your KDB-X environment to pick up the latest changes.

</details>

The module provides three primary functions:

```q
([getInMemoryTables; buildPersistedDB; streamToPubSub]): use `kx.datagen.capmkts
```

To generate _in-memory_ tables `trade`, `quote`, and `nbbo` along with metadata tables `master` and dictionary `exnames`, use the `getInMemoryTables` function:

```q
(trade; quote; nbbo; master; exnames): getInMemoryTables[]
```

You can run q-sql queries, for example:

```q
q)select sum size by description from trade lj `sym xkey master
description                | size
---------------------------| ----
ADVANCED MICRO DEVICES     | 2191
AMERICAN INTL GROUP INC    | 2482
APPLE INC COM STK          | 3227
AT&T Inc.                  | 2527
```

To generate one month of _date-partitioned data_ and store it in a directory (e.g., `/tmp/testdb`), use the `buildPersistedDB` function:

```q
buildPersistedDB "/tmp/testdb"
```

You can also pass the directory path as a symbol or as a file symbol (`` `:/tmp/testdb``).

Once the data is generated, you can load it into a q session with four [worker threads](https://code.kx.com/kdb-x/reference/syscmds.html#s-number-of-secondary-threads) using the following command (or by `\l` in a running q session):

```bash
$ q /tmp/testdb -s 4
```

You can then run queries on the loaded tables. For example:

```q
q)asc select sum size by exch: exnames ex from trade where time within 10:00 10:30
exch                                | size
------------------------------------| -----
"Cboe BZX Exchange"                 | 75158
"Cboe BYX Exchange"                 | 75862
"New York Stock Exchange"           | 76453
"NYSE National"                     | 76764
"NASDAQ OMX PSX"                    | 76977
..

q)aj[`sym`time; select from trade where date=first date, sym in `MSFT`GOOG`AMZN; select sym, time, bid, ask from quote where date=first date]
date       sym  time                 price size stop cond ex bid   ask
------------------------------------------------------------------------
2026.01.23 AMZN 0D09:30:03.749993525 92.14 52   0    U    A  91.36 92.98
2026.01.23 AMZN 0D09:30:04.439951076 92.26 39   0    4    A  91.69 92.64
2026.01.23 AMZN 0D09:30:05.843364190 92.19 96   0    E    A  92.1  92.97
2026.01.23 AMZN 0D09:30:06.444902389 92.19 37   0    B    A  91.69 93.02
..
```

## Parameters

You can pass optional parameters as a dictionary. If you pass a single number instead, it's interpreted as the `tradesPerDay` parameter.

### Data density/volume

You can adjust the data density (and overall data volume) by specifying the approximate number of trades per day. Note that the exact number depends on various factors, such as the number of instruments.

```q
(trade; quote; nbbo; master; exnames): getInMemoryTables 10000
```

Similarly, for persistent data generation:

```q
buildPersistedDB["/tmp/testdb"; 10000]
```

### Date range (`start` and `end`)

The `buildPersistedDB` function allows you to specify the start and end dates for the data to be generated. These dates are passed as part of a dictionary in the second parameter. For example, to generate one year of data:

```q
buildPersistedDB["/tmp/testdb"; ([tradesPerDay: 10000; start: 2025.01.01; end: 2025.12.31])]
```

### Segmented database

Segmented databases are also supported by `buildPersistedDB`, using the `segmentNr` and `segmentPattern` keys. For instance, to use four drives mounted at `/mnt/ssd0`, `/mnt/ssd1`, `/mnt/ssd2`, and `/mnt/ssd3`, you can use the following command:

```q
buildPersistedDB["/tmp/testdb"; ([segmentNr: 4; segmentPattern: "/mnt/ssd{}/testdb"])]
```

This distributes partitions across `/mnt/ssd0/testdb`, `/mnt/ssd1/testdb`, `/mnt/ssd2/testdb`, and `/mnt/ssd3/testdb`.

### Additional settings

The following parameters can be customized using a dictionary passed to `getInMemoryTables` or `buildPersistedDB` functions. Default values are provided for convenience:

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `tradesPerDay` | `1000` | The number of trades per day. |
| `tbls` | `` `trade`quote`nbbo`` | tables to be generated besides other kdb+ objects like table `master` and dictionary `exnames` |
| `exchopen` | `9:30` | The opening time of the exchange. No trades or quotes are generated before this time. |
| `exchclose` | `16:00` | The closing time of the exchange. No trades or quotes are generated after this time. |
| `quotesPerTrade` | `10` | The number of quotes generated per trade. |
| `nbboPerTrade` | `3` | The number of National Best Bid and Offer (NBBO) entries generated per trade. |

The following parameters control the statistical model used to generate prices, volumes, and quotes. They can be customized using a dictionary passed to `getInMemoryTables` or `buildPersistedDB` functions. Default values are provided for convenience:

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `volumeGrowth` | `1.0005` | The average volume growth per day. |
| `priceCorrelation` | `0.5` | The correlation coefficient between the price movements of different symbols. |
| `midPriceChangeProb` | `0.3` | The probability that the mid price (used for trades) moves on a given tick. Lower values make prices stickier, i.e. mid prices stay the same for longer. |
| `spreadChangeProb` | `0.15` | The probability that a quote's bid or ask margin changes on a given tick. Lower values make spreads stickier. |
| `maxSpread` | `0.0005` | The maximum bid/ask margin, on one side, as a fraction of the mid price. |

In addition, `buildPersistedDB` accepts:

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `tbls` | `` `trade`quote`nbbo`daily`` | tables to be persisted besides other kdb+ objects like table `master` and dictionary `exnames` |
| `linked` | `0b` | `1b` to create linked column `master` for tables `trade`, `quote` and `nbbo` |
| `mastertype` | `flat` | Type of the master table: `flat` or `splayed` |
| `holidays` | `("01.01"; "01.19"; "02.16"; "05.25"; "06.19"; "07.03"; "09.07"; "10.12"; "11.11"; "11.26"; "12.25")` | A list of holidays (in addition to weekends) for which no trading data is generated. There is no trading on some exchanges on weekends and on public holidays. This can challenge some algorithms and cause issues in downstream systems. The module supports holidays to reflect this condition. Only `buildPersistedDB` considers this parameter. |

#### Example usage

To customize the settings, you can pass a dictionary as shown below:

```q
(trade; quote; nbbo; master; exnames): getInMemoryTables ([tradesPerDay: 10000; exchopen: 7:00; exchclose: 18:00; quotesPerTrade:20; nbboPerTrade:6; volumeGrowth: 1.0002])
```

or

```q
buildPersistedDB[`:/tmp/testdb; ([tradesPerDay: 5000; linked: 1b])]
```

or

```q
buildPersistedDB[`$"/tmp/testdb"; ([tbls: `trade; mastertype: `splayed])]
```

## Streaming to a PubSub (Tickerplant or Reliable Transport)

To replay generated data as a live feed instead of a static snapshot, use `streamToPubSub`. It generates in-memory tables with `getInMemoryTables`, publishes `master` immediately, then drip-feeds the `trade`, `quote`, and `nbbo` rows to a running tickerplant (TP) or Reliable Transport (RT) process, pacing the publishes to match the original inter-event timing.

`streamToPubSub` takes a single list argument of 2 or 3 elements:

| Position | Name | Type | Description |
| :--- | :--- | :--- | :--- |
| 0 | `connH` | int handle or composition | Connection handle to publish to. An int handle (e.g. from `hopen`) is treated as a TP connection. A composition (e.g. an RT publish function) is treated as an RT connection. |
| 1 | `batchsize` | long | Number of rows sent per update call. |
| 2 (optional) | — | number or dictionary | Passed through to `getInMemoryTables`: either `tradesPerDay` or a settings dictionary (see [Additional Settings](#additional-settings)). If the dictionary includes `tbls`, it selects which tables are streamed (default `` `trade`quote`nbbo``). The dictionary key `updFn` overrides the default update function name `.u.upd`. |

For example, to stream data to a tickerplant listening on port 5010, in batches of 10 rows:

```q
tpH: hopen 5010
streamToPubSub[tpH; 10]
```

Stream to a [KX Database Service](https://code.kx.com/kdb-x/services/db-service/introduction.html) via an RT publisher. The tables must be [created](https://code.kx.com/kdb-x/services/db-service/manage-tables.html#create) in DB Service before any data is published to them (see the schema creation example below):

```bash
$ q startq.q
q)rtPub: .rt.pub ([path: "/tmp/rtpub"; stream: "data"; cluster: enlist ":localhost:5002"; publisher_id: "datagen"])
q)streamToPubSub[rtPub; 10]
```

You can get `startq.q` by unzipping [`rt.qpk`](https://code.kx.com/insights/1.20/microservices/rt/examples/run-rt-locally.html#publish).

<details>
<summary>trade, quote and nbbo table creation in DB Services</summary>

The code below shows how to create the trade,quote and nbbo tables in memory using the [DB Service client module](https://github.com/KxSystems/kdbx-db-service-q-client)

```q
dbs: use`kx.dbservice_client
session:dbs.createSession[]

tradeCols: (
  ([name: "sym"; type: "symbol"]);
  ([name: "time"; type: "timespan"]);
  ([name: "price"; type: "float"]);
  ([name: "size"; type: "long"]);
  ([name: "stop"; type: "boolean"]))
session.createTable[([table: "trade"; type: "mem_only"; columns: tradeCols])]

quoteCols: (
  ([name: "sym"; type: "symbol"]);
  ([name: "time"; type: "timespan"]);
  ([name: "bid"; type: "float"]);
  ([name: "ask"; type: "float"]);
  ([name: "bsize"; type: "long"]);
  ([name: "asize"; type: "long"]);
  ([name: "mode"; type: "char"]);
  ([name: "ex"; type: "symbol"]))
session.createTable[([table: "quote"; type: "mem_only"; columns: quoteCols])]

nbboCols: (
  ([name: "sym"; type: "symbol"]);
  ([name: "time"; type: "timespan"]);
  ([name: "bid"; type: "float"]);
  ([name: "ask"; type: "float"]);
  ([name: "bsize"; type: "long"]);
  ([name: "asize"; type: "long"]))
session.createTable[([table: "nbbo"; type: "mem_only"; columns: nbboCols])]
```

</details>

To control the volume and which tables are streamed, pass a third element:

```q
streamToPubSub[tpH; 100; ([tradesPerDay: 50000; tbls: `trade`quote])]
```

You can stream to a plain q process by passing `insert` to `updFn`:

```q
tpH: hopen 5010
streamToPubSub[tpH; 100; ([tradesPerDay: 50000; updFn: insert])]
```

`streamToPubSub` has no return value; it publishes until every generated row has been sent, sleeping between batches to simulate real-time pacing.

Performance and memory efficiency were not design goals for `streamToPubSub`; it's intended for demos rather than stress testing.

## Resource requirements

- The kdb+ objects (tables and dictionary) generated with the default `getInMemoryTables` parameters require 1.3 MB of memory.
- Persisted data generated with the default parameters occupies 377 MB of disk space.
