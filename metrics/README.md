# Classification metrics utility

Run from the project root:

```bash
python3 metrics/ai_metrics.py metrics/example_labels.csv
```

Provide a labelled CSV with columns `true_label,predicted_label`; `1` means blacklist/block and `0` means clean/allow. The script reports Accuracy, Precision, Recall, F1, Specificity, false-positive/false-negative rates and the confusion matrix. Replace the example with labelled results from a test run.

This is a metrics/evaluation utility, not an AI model. Bloom-filter hardware is a probabilistic data structure; use a ground-truth labelled dataset to measure its false positives and false negatives.
