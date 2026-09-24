# HumanBot comparison ledger

Keep the same driver/seeds. Server counters and imperfect client behavior are complementary; a single run cannot establish difficulty or acceptance rates. Full M2/M3 suites and human sessions remain required.

| Build/run | Clears | Seconds | Stocks lost | Snapshot damage | Idle | Flank windows | Cap violations |
|---|---:|---:|---:|---:|---:|---:|---:|
| M0 five-run baseline |5/5|278.27 mean|0.80 mean|543 mean|16.10% pooled|45.45% pooled|0|
| WO-2.1 extraction seed1101 |1/1|265.15|1|448|14.52%|12.50%|0|
| WO-2.2 director seed1101 |1/1|292.37|0|430|10.58%|90.91%|0|

The director run used reviewed combat `3bbc5cc`, original art and WO-1.3 special presentation. AI callback mean0.04394ms; this is **not** the required12-enemy/four-player MicroProfiler measurement. Raw anonymous report: `evidence/director-seed1101.json`. Improved flank/idle results in one run are promising but not the five-run acceptance gate. Damage/stocks remain too forgiving for the M3 target; M3 has not been applied yet.

An early WO-2.3 campaign probe was deliberately stopped after projectile warning review found a geometry mismatch. It is not counted as a completed run or a tuning result. The corrected build must be measured fresh. Actual two-client grab/rescue fixture did pass ally rescue, cancellation of the pending throw and unrescued timed-throw damage; this is a scripted authority test, not normal-input campaign evidence.
