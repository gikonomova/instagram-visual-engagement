"""CRISP-DM phase 2 - Data Understanding.

Downloads the pinned dataset snapshot, verifies its checksum, and writes a data profile.
Nothing here looks at the relation between visual features and likes (see DECISIONS.md, D06).
Run: .venv/bin/python -I src/01_data_understanding.py
"""
import hashlib
import json
import pathlib
import urllib.request

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pyarrow.parquet as pq

ROOT = pathlib.Path(__file__).resolve().parents[1]
RAW = ROOT / "data/raw/ig_train.parquet"
TAB, FIG = ROOT / "outputs/tables", ROOT / "outputs/figures"
URL = ("https://huggingface.co/datasets/vargr/ig_train_dataset/resolve/"
       "refs%2Fconvert%2Fparquet/default/train/0000.parquet")
SHA256 = "0aa06bbfad98704a8a2b32b89b053a66f9c7032f6ac8822807f04908b38f61d5"
# Personal free text and nested boxes are never loaded.
DROP = {"bboxes", "bio", "username", "description"}
VISUAL = ["AestheticScore", "BalancingElements", "ColorHarmony", "ContentAesthetics", "DoFScore",
          "LightScore", "MotionBlurScore", "ObjectScore", "RuleOfThirdsScore", "VividColorScore",
          "RepetitionScore", "SymmetryScore"]


def load():
    RAW.parent.mkdir(parents=True, exist_ok=True)
    if not RAW.exists():
        urllib.request.urlretrieve(URL, RAW)
    h = hashlib.sha256(RAW.read_bytes()).hexdigest()
    assert h == SHA256, f"checksum mismatch: {h}"
    cols = [c for c in pq.read_schema(RAW).names if c not in DROP]
    return pq.read_table(RAW, columns=cols).to_pandas()


def main():
    TAB.mkdir(parents=True, exist_ok=True)
    FIG.mkdir(parents=True, exist_ok=True)
    d = load()
    per_acct = d.groupby("profile_id").size()
    date = pd.to_datetime(d.date)
    profile = {
        "rows": len(d), "columns": d.shape[1], "accounts": int(d.profile_id.nunique()),
        "accounts_with_2plus_posts": int((per_acct >= 2).sum()),
        "posts_in_2plus_accounts": int(per_acct[per_acct >= 2].sum()),
        "posts_per_account_max": int(per_acct.max()),
        "duplicate_shortcodes": int(d.shortcode.duplicated().sum()),
        "date_min": str(date.min()), "date_max": str(date.max()),
        "followers_zero": int((d.followers == 0).sum()),
        "likes_zero_share": float((d.likes == 0).mean()),
        "followers_vary_within_account": int((d.groupby("profile_id").followers.nunique() > 1).sum()),
        "missing_values": int(d.isna().sum().sum()),
        "lang": d.lang.value_counts().to_dict(),
        "post_type": {int(k): int(v) for k, v in d.post_type.value_counts().items()},
        "posts_by_year": date.dt.year.value_counts().sort_index().to_dict(),
    }
    (TAB / "01_profile.json").write_text(json.dumps(profile, indent=2, default=str))

    num = d[["likes", "comments", "followers", "following", "num_posts"] + VISUAL]
    num.describe(percentiles=[.01, .25, .5, .75, .99]).T.to_csv(TAB / "01_numeric_summary.csv")
    d[VISUAL].corr().round(3).to_csv(TAB / "01_visual_correlations.csv")
    for c in ["image_shot", "image_category", "description_category", "is_business_account"]:
        d[c].value_counts().rename("n").to_csv(TAB / f"01_counts_{c}.csv")

    plt.rcParams.update({"font.size": 8})
    fig, ax = plt.subplots(3, 1, figsize=(3.4, 5.4))  # one journal column
    ax[0].hist(np.log10(d.likes + 1), bins=60, color="#4C72B0")
    ax[0].set(xlabel="log10(likes + 1)", ylabel="posts")
    ax[1].hist(np.log10(d.followers + 1), bins=60, color="#4C72B0")
    ax[1].set(xlabel="log10(followers + 1)")
    date.dt.to_period("M").value_counts().sort_index().plot(ax=ax[2], color="#4C72B0")
    ax[2].set(xlabel="month posted", ylabel="posts")
    fig.tight_layout()
    fig.savefig(FIG / "fig1_distributions.png", dpi=300)
    print(json.dumps(profile, indent=2, default=str))


if __name__ == "__main__":
    main()
