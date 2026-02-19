# Capital Market Data Generator — TODO List

## 1. Add Level 2 (Order Book Depth) Data Generation

Implement support for generating Level 2 market data (depth). Bid/ask prices and sizes can be represented either as arrays or as separate columns.
Reference: https://dataintellect.com/blog/level-2-storage-formats/

## 2. Enhance Data Generation Model for More Realistic Behaviour

Improve the statistical model to better reflect real‑world market dynamics. For example, the current distribution of trade counts is too uniform across instruments (see `(min;max) @\: select cnt: count i by sym from trade`). Increase dispersion so that heavily traded instruments appear significantly more often than thinly traded ones.