# datagen kdb-x installation

## Install module with qmamba

qmamba is a package manager for kdb-x. It is currently available in a private preview capacity. You are welcome to try it and provide feedback.
Follow the install instructions for [qmamba](https://github.com/KxSystems/qmamba/blob/main/README.md#installation).

```q
qmamba:use`kx.qmamba
qmamba.create "myenv"
qmamba.activate "myenv"
qmamba.install `SPECS`CHANNEL!(enlist "q-kx-datagen";enlist"kx")
.datagen:use`kx.datagen
```

## Installation

`datagen` is written as a module, under kdb-x's module framework. Though modules can be loaded from anywhere if added to your `$QPATH`, we recommend installing to the `$HOME/.kx/mod/kx` folder. This is to avoid name clashes with other user defined modules, as well as providing a location for other KX modules to cross reference each other.

```bash
export QPATH="$QPATH:$HOME/.kx/mod"
mkdir -p ~/.kx/mod/kx/
cp -r datagen ~/.kx/mod/kx/
```

Now from anywhere you can import the `datagen` library.

```q
q)([getInMemoryTables; buildPersistedDB]): use `kx.datagen.capmkts
q)(trade; quote; nbbo; master; exnames): getInMemoryTables[]
q)asc select sum size by exch: exnames ex from trade where time within 10:00 10:30
exch                                | size
------------------------------------| ----
"The Investors' Exchange"           | 36
"Cboe EDGX Exchange"                | 64
"Chicago Broad Options Exchange"    | 65
"NASDAQ OMX BX"                     | 73
```

Add the export to your `.bashrc` or equivalent to persist across sessions.
