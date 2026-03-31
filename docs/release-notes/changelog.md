# Datagen Module Changelog

_This page documents the version history of the KDB-X Datagen Module, including released versions, fixes, and improvements._

## 1.3.2

**Release Date**: 2026-03-30

**Fixes and Improvements**:

- Capital Markets domain:
  - speed up in data generation

## 1.3.1

**Release Date**: 2026-03-13

**Fixes and Improvements**:

- Capital Markets domain:
  - table daily is splayed instead of flat

## 1.3.0

**Release Date**: 2026-03-06

**Fixes and Improvements**:

- Capital Markets domain:
  - MASTER is keyed for `getInMemoryTables`
  - `buildPersistedDB` option to have linked column `master` for tables `trade`, `quote` and `nbbo` on column `sym` to table `master`

## 1.2.0

**Release Date**: 2026-03-03

**Fixes and Improvements**:

- Capital Markets domain:
  - model change: most symbols can be traded/quoted on multiple exchanges.
  - `buildPersistedDB` api change: dictionary is expected as second parameter
  - improved error handling
  - `buildPersistedDB` default parameter bug fix for `segmentPattern`

## 1.1.0

**Release Date**: 2026-02-23

**Fixes and Improvements**:

- Capital Markets domain: Changing the type of time column from `time` to `timespan`

## 1.0.3

**Release Date**: 2026-02-19

**Fixes and Improvements**:

- Capital Markets domain: Fixing the distribution of the time column

## 1.0.2

**Release Date**: 2026-02-13

**Fixes and Improvements**:

- Install notes fixes

## 1.0.1

**Release Date**: 2026-02-12

**Fixes and Improvements**:

- Documentation fixes
