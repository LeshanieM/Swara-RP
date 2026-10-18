"""Create a deterministic participant-independent CASA manifest split."""

from __future__ import annotations

import csv
import json
import random
from collections import defaultdict
from pathlib import Path
from typing import Any


SERVICE_ROOT = Path(__file__).resolve().parents[2]
PROCESSED_ROOT = SERVICE_ROOT / "data" / "casa" / "processed"
MANIFEST_PATH = PROCESSED_ROOT / "manifest.csv"
SPLIT_PATH = PROCESSED_ROOT / "split_manifest.json"
SEED = 42
TASKS = ("interview", "reading")
SPLITS = ("train", "val", "test")
CONSTRAINTS = {
    "min_val_participants": 3,
    "min_test_participants": 3,
    "min_val_windows": 1000,
    "min_test_windows": 1000,
}


def truth(value: str) -> int:
    return int(str(value).strip()) if str(value).strip() else 0


def read_manifest() -> tuple[list[dict[str, str]], list[str]]:
    with MANIFEST_PATH.open("r", newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        fields = list(reader.fieldnames or [])
    required = {"participant_id", "task", "mask", "FG", "HM"}
    missing = sorted(required - set(fields))
    if missing:
        raise ValueError(f"Manifest is missing required columns: {missing}")
    return rows, fields


def participant_statistics(rows: list[dict[str, str]]) -> dict[str, dict[str, Any]]:
    stats: dict[str, dict[str, Any]] = {}
    for row in rows:
        pid = row["participant_id"].strip()
        if not pid:
            raise ValueError("Manifest contains an empty participant_id")
        entry = stats.setdefault(pid, {
            "n_windows": 0, "FG_pos": 0, "HM_pos": 0, "both_pos": 0,
            "tasks": defaultdict(int),
        })
        if str(row["mask"]).strip() != "1":
            continue
        fg, hm = truth(row["FG"]), truth(row["HM"])
        entry["n_windows"] += 1
        entry["FG_pos"] += fg
        entry["HM_pos"] += hm
        entry["both_pos"] += int(fg == 1 and hm == 1)
        entry["tasks"][row["task"].strip()] += 1
    for entry in stats.values():
        count = entry["n_windows"]
        entry["FG_rate"] = entry["FG_pos"] / count if count else 0.0
        entry["HM_rate"] = entry["HM_pos"] / count if count else 0.0
        entry["positive_rate"] = max(entry["FG_rate"], entry["HM_rate"])
        entry["tasks"] = dict(entry["tasks"])
    return stats


def assign_participants(stats: dict[str, dict[str, Any]]) -> dict[str, str]:
    """Spread FG-rate-ranked participants using a deterministic weighted round-robin."""
    rng = random.Random(SEED)
    pids = sorted(stats)
    rng.shuffle(pids)
    pids.sort(key=lambda pid: stats[pid]["FG_rate"])

    # A six-slot cycle approximates 70/15/15 while interleaving low and high rates.
    # For 29 participants this produces 20 train, 5 val, and 4 test participants.
    cycle = ["train", "train", "train", "train", "val", "test"]
    offset = rng.randrange(len(cycle))
    slots = cycle[offset:] + cycle[:offset]
    assignment = {pid: slots[index % len(slots)] for index, pid in enumerate(pids)}

    # Improve task representation and rate balance by deterministic split-label swaps.
    # Participants stay in their split-size slots, and ranked order remains spread
    # across the groups; each proposed swap is accepted only when it improves score.
    def score(candidate: dict[str, str]) -> float:
        split_pids = {split: [pid for pid in pids if candidate[pid] == split] for split in SPLITS}
        penalty = 0.0
        task_totals = {task: sum(stats[pid]["tasks"].get(task, 0) for pid in pids) for task in TASKS}
        for split in SPLITS:
            selected = split_pids[split]
            if not selected:
                penalty += 1_000_000
                continue
            for task in TASKS:
                if task_totals[task] and not any(stats[pid]["tasks"].get(task, 0) for pid in selected):
                    penalty += 100_000
                actual = sum(stats[pid]["tasks"].get(task, 0) for pid in selected)
                target = task_totals[task] * len(selected) / len(pids)
                penalty += abs(actual - target) / max(1, task_totals[task]) * 100
            positive_rate = sum(stats[pid]["FG_rate"] for pid in selected) / len(selected)
            overall_rate = sum(stats[pid]["FG_rate"] for pid in pids) / len(pids)
            penalty += abs(positive_rate - overall_rate) * 100
            windows = sum(stats[pid]["n_windows"] for pid in selected)
            total_windows = sum(stats[pid]["n_windows"] for pid in pids)
            penalty += abs(windows / max(1, total_windows) - len(selected) / len(pids)) * 10
        return penalty

    best_score = score(assignment)
    for _ in range(200):
        improved = False
        for left_index, left_pid in enumerate(pids):
            for right_pid in pids[left_index + 1:]:
                if assignment[left_pid] == assignment[right_pid]:
                    continue
                candidate = assignment.copy()
                candidate[left_pid], candidate[right_pid] = candidate[right_pid], candidate[left_pid]
                candidate_score = score(candidate)
                if candidate_score + 1e-12 < best_score:
                    assignment, best_score = candidate, candidate_score
                    improved = True
        if not improved:
            break
    return assignment


def build_report(rows: list[dict[str, str]], stats: dict[str, dict[str, Any]],
                 assignment: dict[str, str]) -> tuple[dict[str, Any], dict[str, list[str]], list[str]]:
    per_split: dict[str, dict[str, Any]] = {}
    split_pids = {split: sorted(pid for pid, value in assignment.items() if value == split)
                  for split in SPLITS}
    split_rows = {split: [row for row in rows if assignment[row["participant_id"].strip()] == split
                          and str(row["mask"]).strip() == "1"] for split in SPLITS}
    all_usable_count = sum(len(split_rows[s]) for s in SPLITS)
    for split in SPLITS:
        usable = split_rows[split]
        n = len(usable)
        fg = sum(truth(row["FG"]) for row in usable)
        hm = sum(truth(row["HM"]) for row in usable)
        both = sum(truth(row["FG"]) == 1 and truth(row["HM"]) == 1 for row in usable)
        per_split[split] = {
            "n_participants": len(split_pids[split]), "n_windows": n,
            "FG_pos": fg, "HM_pos": hm, "both_pos": both,
            "tasks": {task: sum(row["task"].strip() == task for row in usable) for task in TASKS},
            "positive_rate_FG": fg / n if n else 0.0,
            "positive_rate_HM": hm / n if n else 0.0,
        }
    split_sizes = {split: per_split[split]["n_windows"] / all_usable_count
                   if all_usable_count else 0.0 for split in SPLITS}

    failures: list[str] = []
    if len(split_pids["val"]) < CONSTRAINTS["min_val_participants"]:
        failures.append(f"val participants={len(split_pids['val'])} < {CONSTRAINTS['min_val_participants']}")
    if len(split_pids["test"]) < CONSTRAINTS["min_test_participants"]:
        failures.append(f"test participants={len(split_pids['test'])} < {CONSTRAINTS['min_test_participants']}")
    for split in ("val", "test"):
        if per_split[split]["n_windows"] < CONSTRAINTS[f"min_{split}_windows"]:
            failures.append(f"{split} windows={per_split[split]['n_windows']} < {CONSTRAINTS[f'min_{split}_windows']}")
    for split in SPLITS:
        for task in TASKS:
            if per_split[split]["tasks"][task] == 0:
                failures.append(f"{split} has no usable {task} windows")
    if per_split["test"]["FG_pos"] <= 20:
        failures.append(f"FG_pos[test]={per_split['test']['FG_pos']} <= 20")
    if per_split["test"]["HM_pos"] <= 10:
        failures.append(f"HM_pos[test]={per_split['test']['HM_pos']} <= 10")

    report = {
        "seed": SEED,
        "participants": assignment,
        "participant_statistics": {
            pid: {
                "n_windows": stats[pid]["n_windows"], "FG_pos": stats[pid]["FG_pos"],
                "HM_pos": stats[pid]["HM_pos"], "both_pos": stats[pid]["both_pos"],
                "tasks": stats[pid]["tasks"], "positive_rate": stats[pid]["positive_rate"],
            } for pid in sorted(stats)
        },
        "per_split": per_split,
        "split_sizes": split_sizes,
        "constraints": CONSTRAINTS,
        "constraints_met": not failures,
        "constraint_failures": failures,
        "notes": "Participant IDs were sorted by FG-positive rate and assigned with a seeded weighted round-robin (4 train, 1 val, 1 test per cycle); deterministic swaps improved task representation and balanced FG rate/window totals without changing split participant counts. Overlapping 2s windows at 0.5s stride inflate FG-positive rate (up to 4x); per-window metrics may be optimistic.",
    }
    return report, split_pids, failures


def main() -> None:
    rows, fields = read_manifest()
    stats = participant_statistics(rows)
    assignment = assign_participants(stats)
    report, split_pids, failures = build_report(rows, stats, assignment)

    train_pids, val_pids, test_pids = (split_pids[name] for name in SPLITS)
    overlaps = {
        "train_val": sorted(set(train_pids) & set(val_pids)),
        "train_test": sorted(set(train_pids) & set(test_pids)),
        "val_test": sorted(set(val_pids) & set(test_pids)),
    }
    manifest_pids = {row["participant_id"].strip() for row in rows}
    assigned_pids = set(train_pids) | set(val_pids) | set(test_pids)
    if any(overlaps.values()):
        failures.append(f"Participant overlap found: {overlaps}")
    if manifest_pids != assigned_pids:
        failures.append(f"Participant assignment mismatch: unassigned={sorted(manifest_pids-assigned_pids)}, extra={sorted(assigned_pids-manifest_pids)}")
    report["constraints_met"] = not failures
    report["constraint_failures"] = failures

    split_by_pid = assignment
    for row in rows:
        row["split"] = split_by_pid[row["participant_id"].strip()]
    if "split" not in fields:
        fields.append("split")
    with MANIFEST_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    SPLIT_PATH.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print("=== Participant split (seed=42) ===")
    for split in SPLITS:
        info = report["per_split"][split]
        print(f"{split.upper()}: {info['n_participants']} participants | {info['n_windows']} windows | "
              f"FG+ {info['FG_pos']} ({info['positive_rate_FG']:.1%}) | "
              f"HM+ {info['HM_pos']} ({info['positive_rate_HM']:.1%})")
        print(f"  tasks: interview {info['tasks']['interview']}, reading {info['tasks']['reading']}")
        print(f"  participants: {split_pids[split]}")
    print(f"Constraints met: {'yes' if not failures else 'no'}")
    if failures:
        print(f"Constraint failures: {failures}")
    overall_fg = report["per_split"]["train"]["FG_pos"] + report["per_split"]["val"]["FG_pos"] + report["per_split"]["test"]["FG_pos"]
    overall_windows = sum(report["per_split"][split]["n_windows"] for split in SPLITS)
    fg_rate = overall_fg / overall_windows if overall_windows else 0.0
    print(f"NOTE: FG positive rate is {fg_rate:.1%} of usable windows. This is inflated by 2s/0.5s overlapping window sampling (up to 4x). Reported per-window metrics will be optimistic.")
    print(f"Split manifest: {SPLIT_PATH}")
    print(f"Updated manifest: {MANIFEST_PATH}")

    try:
        assert not overlaps["train_val"] and not overlaps["train_test"] and not overlaps["val_test"], overlaps
        assert manifest_pids == assigned_pids, (sorted(manifest_pids - assigned_pids), sorted(assigned_pids - manifest_pids))
        assert report["per_split"]["test"]["FG_pos"] > 20 and report["per_split"]["test"]["HM_pos"] > 10, report["per_split"]["test"]
        assert not failures, failures
    except AssertionError as error:
        print(f"ASSERTION FAILURE: {error}")
        raise SystemExit(1) from error
    print("All assertions passed.")


if __name__ == "__main__":
    main()
