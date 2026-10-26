# Metrics from real UVM DUT observations

## 1. Generate a labelled result CSV

From the project root, run the metrics testcase in Questa:

```bash
cd sim
source ./project_env.bash
make clean
make all TESTNAME=metro_metrics_test SEED=1
```

The UVM sequence writes `sim/log/metro_metrics_results.csv` (relative to the
`sim/` working directory). Each `predicted_label` is read from the DUT's
`STAT_REG[1]`; it is not copied from the scoreboard's expected value. The
`true_label` is the known label in this controlled test dataset.

Then, still from `sim/`, calculate metrics:

```bash
make metrics
```

Equivalent command from the project root:

```bash
python3 metrics/ai_metrics.py sim/log/metro_metrics_results.csv
```

## 2. Dataset semantics and limitations

- 240 known blacklist IDs are inserted into the Bloom Filter.
- Up to 16 additional known blacklist IDs are loaded only into the exact-match
  fallback table.
- 1024 clean IDs are not loaded into either structure.
- The dataset is synthetic and controlled for functional evaluation; it is not
  a real Metro-card population and is not a trained-AI evaluation.
- The testbench uses `BIT_COUNT=4096` for faster simulation, not the default
  9,600,000-bit configuration. False-positive rate depends on capacity and
  the number of inserted IDs, so do not claim this FPR represents production.

The output is based on actual DUT predictions for the simulated cases. The labels
come from the known membership of the test dataset. Keep the generated CSV and
Questa log together as evidence.

## 3. Input format for external datasets

The script also accepts a CSV containing at least these columns:

```csv
true_label,predicted_label
1,1
0,0
```

Labels use `1=blacklist`, `0=clean`. Extra columns such as `card_id`,
`fallback_match`, `status_word`, and `source` are allowed. Do not include real
card identifiers or personal data in a report unless authorized.
