#!/usr/bin/env python3
"""Compute binary classification metrics from a CSV file.

Expected CSV columns: true_label,predicted_label
Labels must be 0 (clean/allow) or 1 (blacklisted/block). This evaluates outputs;
it does not train an AI model or make the RTL itself an AI system.
"""
import argparse
import csv
import math
import sys
from pathlib import Path


def safe_div(num, den):
    return num / den if den else 0.0


def main():
    parser = argparse.ArgumentParser(description="Accuracy, precision, recall, F1 and confusion matrix")
    parser.add_argument("csv_file", help="CSV with true_label and predicted_label columns")
    args = parser.parse_args()
    path = Path(args.csv_file)
    if not path.is_file():
        parser.error(f"File not found: {path}")

    tp = fp = tn = fn = total = 0
    with path.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        required = {"true_label", "predicted_label"}
        if not reader.fieldnames or not required.issubset(set(reader.fieldnames)):
            parser.error("CSV must contain headers: true_label,predicted_label")
        for line_no, row in enumerate(reader, start=2):
            try:
                truth = int(row["true_label"])
                pred = int(row["predicted_label"])
            except (TypeError, ValueError):
                parser.error(f"Line {line_no}: labels must be integers 0 or 1")
            if truth not in (0, 1) or pred not in (0, 1):
                parser.error(f"Line {line_no}: labels must be 0 or 1")
            total += 1
            if truth == 1 and pred == 1: tp += 1
            elif truth == 0 and pred == 1: fp += 1
            elif truth == 0 and pred == 0: tn += 1
            else: fn += 1

    if total == 0:
        parser.error("CSV has no data rows")

    accuracy = safe_div(tp + tn, total)
    precision = safe_div(tp, tp + fp)
    recall = safe_div(tp, tp + fn)  # sensitivity / true-positive rate
    specificity = safe_div(tn, tn + fp)
    f1 = safe_div(2 * precision * recall, precision + recall)
    fpr = safe_div(fp, fp + tn)
    fnr = safe_div(fn, fn + tp)

    print("=== Metro Card Binary Classification Metrics ===")
    print(f"Samples      : {total}")
    print(f"TP / FP      : {tp} / {fp}")
    print(f"TN / FN      : {tn} / {fn}")
    print(f"Accuracy     : {accuracy:.4f} ({accuracy * 100:.2f}%)")
    print(f"Precision    : {precision:.4f} ({precision * 100:.2f}%)")
    print(f"Recall       : {recall:.4f} ({recall * 100:.2f}%)")
    print(f"Specificity  : {specificity:.4f} ({specificity * 100:.2f}%)")
    print(f"F1 Score     : {f1:.4f}")
    print(f"False Pos Rate: {fpr:.4f} ({fpr * 100:.2f}%)")
    print(f"False Neg Rate: {fnr:.4f} ({fnr * 100:.2f}%)")
    print("\nConfusion matrix (rows=true, columns=predicted):")
    print("                 predicted 0   predicted 1")
    print(f"true 0 (clean)   {tn:12d}   {fp:12d}")
    print(f"true 1 (black)   {fn:12d}   {tp:12d}")
    print("\nNote: a Bloom Filter may produce false positives. Evaluate with a labelled dataset;")
    print("do not report these metrics as AI-model performance unless an AI model was actually used.")

if __name__ == "__main__":
    main()
