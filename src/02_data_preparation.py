"""CRISP-DM phase 3 - Data Preparation.

Builds the analysis table used by every model. Each filter and derived variable maps to an
entry in DECISIONS.md. Output: data/processed/model_data.parquet (local only, not committed).
Run: .venv/bin/python -I src/02_data_preparation.py
"""
import hashlib
import json
import pathlib

import numpy as np
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

ROOT = pathlib.Path(__file__).resolve().parents[1]
RAW = ROOT / "data/raw/ig_train.parquet"
OUT = ROOT / "data/processed/model_data.parquet"
TAB = ROOT / "outputs/tables"

# D07: the three degenerate scores (MotionBlur ~1e-34, Repetition/Symmetry constant) are excluded.
ATTRS = ["BalancingElements", "ColorHarmony", "ContentAesthetics", "DoFScore", "LightScore",
         "ObjectScore", "RuleOfThirdsScore", "VividColorScore"]
COLS = ["profile_id", "date", "post_type", "description", "likes", "comments", "followers",
        "is_business_account", "description_category", "image_objects", "image_shot",
        "image_category", "AestheticScore"] + ATTRS


def bucket(profile_id, salt):
    """Deterministic account-level uniform in [0, 1): all posts of an account share it."""
    h = hashlib.sha256(f"{salt}:{profile_id}".encode()).hexdigest()
    return int(h[:12], 16) / 16 ** 12


def main():
    d = pq.read_table(RAW, columns=COLS).to_pandas()
    flow = {"raw": len(d)}
    d = d[d.followers > 0]                       # D08: offset log(followers) undefined at 0
    flow["followers_gt_0"] = len(d)
    d = d[d.post_type == 1]                      # D09: photos only; video scores describe a cover frame
    flow["photos_only"] = len(d)

    date = pd.to_datetime(d.date)
    month = date.dt.to_period("M").astype(str)
    d["month"] = np.where(date < "2018-01-01", "pre2018", month)    # D10: sparse early months pooled
    text = d.description.fillna("")
    d["log_caption_chars"] = np.log1p(text.str.len())
    d["log_hashtags"] = np.log1p(text.str.count(r"#\w+"))
    d["log_mentions"] = np.log1p(text.str.count(r"@\w+"))
    n_person = d.image_objects.map(lambda a: int((a == "person").sum()))
    d["person_present"] = (n_person > 0).astype(int)
    d["log_n_person"] = np.log1p(n_person)
    d["log_n_objects"] = np.log1p(d.image_objects.map(len))
    d["business"] = d.is_business_account.astype(int)
    d["log_followers"] = np.log(d.followers)

    # D11: z-scores so each coefficient is an incidence-rate ratio per 1 SD.
    for c in ["AestheticScore"] + ATTRS:
        d["z_" + c] = (d[c] - d[c].mean()) / d[c].std()

    # D12: account-level splits. test = 20% held-out accounts (H5); half = replication halves.
    u = d.profile_id.map(lambda p: bucket(p, "test"))
    d["split"] = np.where(u < 0.2, "test", "train")
    d["half"] = np.where(d.profile_id.map(lambda p: bucket(p, "half")) < 0.5, "A", "B")
    d["account"] = d.profile_id.astype(str)

    keep = ["account", "likes", "comments", "followers", "log_followers", "month", "business",
            "description_category", "image_shot", "image_category", "person_present",
            "log_n_person", "log_n_objects", "log_caption_chars", "log_hashtags", "log_mentions",
            "split", "half"] + [c for c in d.columns if c.startswith("z_")]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    pq.write_table(pa.Table.from_pandas(d[keep], preserve_index=False), OUT)
    flow.update(final=len(d), accounts=int(d.account.nunique()),
                test_posts=int((d.split == "test").sum()), half_A_posts=int((d.half == "A").sum()))
    (TAB / "02_sample_flow.json").write_text(json.dumps(flow, indent=2))
    print(json.dumps(flow, indent=2))


if __name__ == "__main__":
    main()
