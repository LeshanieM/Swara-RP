import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

for mode in ("ordinary", "srcd"):
    path = ROOT / "models" / "c2_srcd_gru" / f"results_{mode}.json"
    data = json.loads(path.read_text())
    print(f"\n=== {mode.upper()} ===")
    print(f"{'split':5s} {'class':4s} {'acc':>7s} {'baseline':>9s} {'delta':>8s} "
          f"{'F1':>7s} {'PR-AUC':>7s} {'support':>12s}")
    for split, block in (("val", "val_metrics"), ("test", "test_metrics")):
        for cls, m in data[block]["classes"].items():
            print(f"{split:5s} {cls:4s} "
                  f"{m['accuracy']:>7.4f} "
                  f"{m['majority_baseline_accuracy']:>9.4f} "
                  f"{m['delta_over_baseline']:>+8.4f} "
                  f"{m['f1']:>7.4f} "
                  f"{m['pr_auc']:>7.4f} "
                  f"{str(m['n_positive'])+'/'+str(m['n_total']):>12s}")