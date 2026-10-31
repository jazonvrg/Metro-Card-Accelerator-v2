# Verification Plan (VPLAN) — Metro Card Accelerator

## Scope and assumptions
- APB3 like peripheral with no wait states.
- Bloom Filter uses four deterministic hash functions; simulation overrides `BIT_COUNT=4096` (RTL default 9,600,000 bits).
- Exact-match fallback table contains 16 32-bit entries at `0x10 + 4*n`. It catches only IDs explicitly loaded into that table.
- `STAT_REG[0]=DONE`, `[1]=MATCH (Bloom OR fallback)`, `[2]=FALLBACK_MATCH`.

## Testcases
| ID | UVM test | Scenario / stimulus | Expected result | Priority |
|---|---|---|---|---|
| VPLAN-001 | `metro_reset_test` | Read status after reset | `STAT_REG=0` | P1 |
| VPLAN-002 | `metro_register_test` | Read/write ID and CTRL registers | Readback matches programmed values; START is a pulse | P1 |
| VPLAN-003 | `metro_hash_program_test` | Insert several IDs, then query same IDs | All inserted IDs match; fallback flag stays 0 | P1 |
| VPLAN-004 | `metro_fallback_miss_test` | Add ID to fallback only, never Bloom; query it | `DONE=1`, `MATCH=1`, `FALLBACK_MATCH=1` | P0 |
| VPLAN-005 | `metro_fallback_miss_test` | Query ID absent from both Bloom and fallback | Expected clean result `MATCH=0`, `FALLBACK_MATCH=0` for controlled test data | P1 |
| VPLAN-006 | `metro_fallback_miss_test` | Read fallback slot back; clear it and query again | Readback matches; after clear, fallback no longer hits | P1 |
| VPLAN-007 | `metro_fallback_table_test` | Write/read slots 0, 1 and 15 | All legal boundary slots read back correctly | P1 |
| VPLAN-008 | `metro_fallback_table_test` | Overwrite slot 1, clear slot 0 | New value is observed; cleared ID no longer matches if absent from Bloom | P1 |
| VPLAN-009 | `metro_smoke_test` | Run fallback-miss and Bloom insertion/query scenarios sequentially | Both mechanisms work in one regression | P1 |
| VPLAN-010 | Scoreboard (all tests) | Compare observed APB status against independent Bloom/fallback reference model | Any mismatch raises `UVM_ERROR` | P0 |
| VPLAN-011 | Metrics script | Run labelled truth/prediction CSV | Reports TP/FP/TN/FN, Accuracy, Precision, Recall, F1 and specificity | P2 |

## Coverage goals
- Registers: ID, CTRL, STAT and fallback slot read/write.
- Operation mode: Bloom program and query.
- Fallback: hit, miss, overwrite, clear, first slot, middle slot, last slot.
- Result combinations: Bloom hit; fallback-only hit; clean miss.
- Reset: status/control state reset.

## Out of scope / known limitations
- Bloom false-positive probability across one million IDs is not proven by this small directed simulation.
- This RTL uses a simulation `initial` clear of the bit array; ASIC implementation needs a suitable SRAM macro and initialization/clear strategy.
- The fallback table is finite (16 entries) and not a complete exact duplicate of a million-entry blacklist. It is a delta/exception table for known omissions.
- F1/Accuracy are meaningful only when computed against a labelled ground-truth dataset; the metric script does not train or imply an AI model.


## Classification metrics collection (`metro_metrics_test`)

**Purpose:** collect predictions observed on the DUT and calculate confusion-matrix metrics.

**Stimulus:** load 240 known blacklist IDs into the Bloom Filter; load 16 additional known blacklist IDs only into fallback; query those 256 blacklist IDs and 1024 clean IDs that were not loaded.

**Observed result:** `STAT_REG[1]` is recorded as `predicted_label`; the testbench's known dataset membership is written as `true_label`. Results are saved to `sim/log/metro_metrics_results.csv`.

**Evaluation:** run `python3 metrics/ai_metrics.py sim/log/metro_metrics_results.csv` from the project root, or `make metrics` from `sim/`.

**Limitations:** data IDs are synthetic and the simulation uses a 4096-bit Bloom array. These metrics characterize this controlled test only, not the production-scale filter, real card population, or an AI model.
