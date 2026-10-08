"""Descriptive and study-design figures (no model output needed).

All figures are one CSIR journal column wide (3.4 in) with 8 pt text.
Run after src/02: .venv/bin/python -I src/05_descriptive_figures.py
"""
import json
import pathlib

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pyarrow.parquet as pq
from matplotlib.patches import FancyBboxPatch

ROOT = pathlib.Path(__file__).resolve().parents[1]
FIG, TAB = ROOT / "outputs/figures", ROOT / "outputs/tables"
BLUE, GREY, ORANGE = "#4C72B0", "#8C8C8C", "#DD8452"
W = 3.4
plt.rcParams.update({"font.size": 8, "axes.spines.top": False, "axes.spines.right": False})


def box(ax, x, y, w, h, title, body="", color=BLUE):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.008,rounding_size=0.015",
                                fc=color, ec="none", alpha=0.13))
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.008,rounding_size=0.015",
                                fc="none", ec=color, lw=0.8))
    ax.text(x + 0.02, y + h - 0.012, title, va="top", fontsize=7.5, weight="bold")
    if body:
        ax.text(x + 0.02, y + h - 0.045, body, va="top", fontsize=6.6, linespacing=1.25)


def arrow(ax, x0, y0, x1, y1):
    ax.annotate("", (x1, y1), (x0, y0), arrowprops=dict(arrowstyle="-|>", lw=0.8, color="#333333"))


def design():
    """CRISP-DM phases mapped to this study's artefacts."""
    phases = [
        ("1  Business understanding", "Question: visual features vs likes per recorded\nfollower; success = Holm + SESOI + replication"),
        ("2  Data understanding", "606K posts, 485K accounts; profile, feature\nprovenance & degeneracy checks (no outcome links)"),
        ("Pre-registration (tag prereg-v1)", "H1-H5, SESOI ±3%, Holm, split-half replication;\namendment A1 before any result"),
        ("3  Data preparation", "Exclusions, train-only z-scores, hashed\naccount partitions (train/test, halves A/B)"),
        ("4  Modelling", "NB2 GLMM, log(followers) offset, account RE;\nM1, M2, Mundlak M1-W; robustness R1-R6"),
        ("5  Evaluation", "Decision rules, held-out joint log score,\ncalibration (PIT), residual diagnostics"),
        ("6  Deployment", "Public repository, run_all.sh, paper built\nfrom output tables (fill.py)"),
    ]
    fig, ax = plt.subplots(figsize=(W, 4.6))
    ax.set_axis_off(); ax.set_xlim(0, 1); ax.set_ylim(0, 1)
    h, gap = 0.112, 0.03
    for k, (t, b) in enumerate(phases):
        y = 1 - (k + 1) * h - k * gap
        box(ax, 0.02, y, 0.96, h, t, b, ORANGE if t.startswith("Pre") else BLUE)
        if k:
            arrow(ax, 0.5, y + h + gap, 0.5, y + h + 0.004)
    fig.savefig(FIG / "figA_study_design.png", dpi=300, bbox_inches="tight")


def flow():
    """Sequential sample flow and account-level partitions."""
    f = json.loads((TAB / "02_sample_flow.json").read_text())
    part = pd.read_csv(TAB / "02_partitions.csv").set_index("partition")
    fig, ax = plt.subplots(figsize=(W, 3.9))
    ax.set_axis_off(); ax.set_xlim(0, 1); ax.set_ylim(0, 1)
    c = lambda v: f"{int(v):,}"
    box(ax, 0.18, 0.86, 0.64, 0.12, "Source dataset", f"{c(f['1_raw'])} posts")
    box(ax, 0.18, 0.67, 0.64, 0.12, "Recorded followers > 0", f"{c(f['2_remaining'])} posts")
    box(ax, 0.18, 0.48, 0.64, 0.12, "Analysis sample (photos)",
        f"{c(f['3_remaining'])} posts, {c(f['accounts'])} accounts")
    ax.text(0.86, 0.80, f"−{c(f['2_removed_followers_0'])}\nzero followers", fontsize=6.5, va="center")
    ax.text(0.86, 0.61, f"−{c(f['3_removed_videos'])}\nvideos", fontsize=6.5, va="center")
    arrow(ax, 0.5, 0.86, 0.5, 0.79); arrow(ax, 0.5, 0.67, 0.5, 0.60)
    for x, key, title in [(0.01, "train", "Train (80%)"), (0.51, "test", "Test (20%)")]:
        r = part.loc[key]
        box(ax, x, 0.25, 0.48, 0.14, title, f"{c(r.posts)} posts\n{c(r.accounts)} accounts", GREY)
        arrow(ax, 0.5, 0.48, x + 0.24, 0.395)
    for x, key, title in [(0.01, "half_A", "Replication half A"), (0.51, "half_B", "Replication half B")]:
        r = part.loc[key]
        box(ax, x, 0.02, 0.48, 0.14, title, f"{c(r.posts)} posts\n{c(r.accounts)} accounts", GREY)
    ax.text(0.5, 0.205, "independent hash: halves cut across train/test", ha="center", fontsize=6.3,
            style="italic")
    fig.savefig(FIG / "figB_sample_flow.png", dpi=300, bbox_inches="tight")


def composition(d):
    """Image category and shot scale composition of the analysis sample."""
    fig, ax = plt.subplots(2, 1, figsize=(W, 4.6), gridspec_kw={"height_ratios": [18, 12]})
    for a, col, title in [(ax[0], "image_category", "Image category"), (ax[1], "image_shot", "Shot scale")]:
        g = d.groupby(col).agg(n=("person_present", "size"), person=("person_present", "mean")).sort_values("n")
        a.barh(g.index.str.replace("Selife", "Selfie").str.replace(" Shot", ""), g.n / 1000, color=BLUE)
        a.set_xlabel("posts (thousands)"); a.set_title(title, fontsize=8, loc="left", weight="bold")
        a.tick_params(axis="y", length=0)
    fig.tight_layout()
    fig.savefig(FIG / "figC_composition.png", dpi=300, bbox_inches="tight")


def plausibility(d):
    """Cross-classifier agreement: person detection and depth of field by shot scale."""
    g = d.groupby("image_shot").agg(person=("person_present", "mean"), dof=("z_DoFScore", "mean"))
    g.index = g.index.str.replace("Selife", "Selfie").str.replace(" Shot", "")
    g = g.sort_values("person")
    fig, ax = plt.subplots(1, 2, figsize=(W, 2.9), sharey=True)
    ax[0].barh(g.index, 100 * g.person, color=BLUE)
    ax[0].set_xlabel("% person detected"); ax[0].set_xticks([0, 50, 100]); ax[0].tick_params(axis="y", length=0)
    ax[1].axvline(0, color=GREY, lw=0.6)
    ax[1].scatter(g.dof, g.index, color=ORANGE, s=12, zorder=3)
    ax[1].set_xlabel("mean DoF score (z)"); ax[1].set_xticks([-0.3, 0, 0.3])
    fig.tight_layout()
    fig.savefig(FIG / "figD_feature_plausibility.png", dpi=300, bbox_inches="tight")


def correlations(d):
    cols = ["z_AestheticScore", "z_BalancingElements", "z_ColorHarmony", "z_ContentAesthetics",
            "z_DoFScore", "z_LightScore", "z_ObjectScore", "z_RuleOfThirdsScore", "z_VividColorScore"]
    lab = ["Aesthetic", "Balance", "ColourHarm.", "Content", "DoF", "Light", "Object", "RuleOf3rds", "VividCol."]
    c = d.loc[d.split == "train", cols].corr().values
    fig, ax = plt.subplots(figsize=(W, 3.0))
    im = ax.imshow(c, cmap="RdBu_r", vmin=-1, vmax=1)
    ax.set_xticks(range(9)); ax.set_xticklabels(lab, rotation=55, ha="right", fontsize=6.5)
    ax.set_yticks(range(9)); ax.set_yticklabels(lab, fontsize=6.5)
    for i in range(9):
        for j in range(9):
            ax.text(j, i, f"{c[i, j]:.2f}", ha="center", va="center", fontsize=5,
                    color="white" if abs(c[i, j]) > 0.6 else "black")
    ax.spines[:].set_visible(False); ax.tick_params(length=0)
    fig.colorbar(im, ax=ax, fraction=0.04, pad=0.02).ax.tick_params(labelsize=6)
    fig.tight_layout()
    fig.savefig(FIG / "figE_attribute_correlations.png", dpi=300, bbox_inches="tight")


def within(d):
    """Share of each predictor's variance lying within accounts (information for Mundlak terms)."""
    cols = {"z_AestheticScore": "Aesthetic score", "z_BalancingElements": "Balancing elements",
            "z_ColorHarmony": "Colour harmony", "z_ContentAesthetics": "Content",
            "z_DoFScore": "Depth of field", "z_LightScore": "Lighting", "z_ObjectScore": "Object emphasis",
            "z_RuleOfThirdsScore": "Rule of thirds", "z_VividColorScore": "Vivid colour",
            "person_present": "Person present", "log_n_objects": "log(1+objects)"}
    multi = d[d.groupby("account").account.transform("size") >= 2]
    out = {}
    for c, name in cols.items():
        x = multi[c].astype(float)
        dev = x - x.groupby(multi.account).transform("mean")
        out[name] = (dev ** 2).sum() / ((x - x.mean()) ** 2).sum()
    s = pd.Series(out).sort_values()
    fig, ax = plt.subplots(figsize=(W, 2.6))
    ax.barh(s.index, 100 * s.values, color=BLUE)
    ax.set_xlabel("% of variance within accounts\n(accounts with ≥ 2 posts)")
    ax.tick_params(axis="y", length=0)
    fig.tight_layout()
    fig.savefig(FIG / "figF_within_share.png", dpi=300, bbox_inches="tight")
    s.rename("within_share_2plus").to_csv(TAB / "05_within_share_2plus.csv")


def main():
    d = pq.read_table(ROOT / "data/processed/model_data.parquet").to_pandas()
    design(); flow(); composition(d); plausibility(d); correlations(d); within(d)


if __name__ == "__main__":
    main()
