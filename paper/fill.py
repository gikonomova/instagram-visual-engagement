"""Fill {{tokens}} in paper.md with numbers from outputs/tables, so every number in the paper is
traceable to a pipeline output. Usage: fill.py paper.md [--draft] > paper.filled.md   (--draft marks missing results as pending)
Unknown tokens raise an error rather than leaving a placeholder in the manuscript.
"""
import csv
import json
import math
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
T = pathlib.Path(os.environ.get("TABLES", ROOT / "outputs/tables"))  # override for testing


def rows(name):
    with open(T / name) as f:
        return list(csv.DictReader(f))


def f(x, k=3):
    return "[pending]" if x in ("", "NA", None) else f"{float(x):.{k}f}"


def p(x):
    x = float(x)
    return "< 0.001" if x < 0.001 else f"{x:.3f}"


def ci(lo, hi, k=3):
    return f"[{f(lo, k)}, {f(hi, k)}]"


def n(x):
    return f"{int(float(x)):,}"


def md_table(header, body):
    out = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    out += ["| " + " | ".join(r) + " |" for r in body]
    return "\n".join(out)


def tokens(draft=False):
    t = {}
    flow = json.loads((T / "02_sample_flow.json").read_text())
    prof = json.loads((T / "01_profile.json").read_text())
    for k, v in flow.items():
        t["flow_" + k] = n(v)
    t["prof_accounts"] = n(prof["accounts"])
    t["prof_2plus"] = n(prof["accounts_with_2plus_posts"])
    t["prof_2plus_posts"] = n(prof["posts_in_2plus_accounts"])
    t["share_2019"] = f(100 * prof["posts_by_year"]["2019"] / prof["rows"], 1)

    part = {r["partition"]: r for r in rows("02_partitions.csv")}
    t["TABLE_PARTITIONS"] = md_table(
        ["Partition", "Posts", "Accounts", "Accounts ≥ 2 posts", "Posts in them",
         "Within share: aesthetic", "vivid colour", "person"],
        [[k, n(r["posts"]), n(r["accounts"]), n(r["accounts_2plus"]), n(r["posts_in_2plus"]),
          f(r["within_share_AestheticScore"]), f(r["within_share_VividColorScore"]),
          f(r["within_share_person_present"])] for k, r in part.items()])
    t["within_aes"] = f(100 * float(part["all"]["within_share_AestheticScore"]), 1)
    t["within_person"] = f(100 * float(part["all"]["within_share_person_present"]), 1)
    t["acc2_all"] = n(part["all"]["accounts_2plus"])
    t["acc2_posts_all"] = n(part["all"]["posts_in_2plus"])
    if draft and not (T / "04_confirmatory.csv").exists():
        return t

    H = {r["H"]: r for r in rows("04_confirmatory.csv")}
    body = []
    for h in ["H1", "H2", "H3", "H4"]:
        r = H[h]
        t[f"{h}_irr"], t[f"{h}_ci"] = f(r["irr"]), ci(r["lo95"], r["hi95"])
        t[f"{h}_ci90"] = ci(r["lo90"], r["hi90"])
        t[f"{h}_p"], t[f"{h}_ptost"] = p(r["p_holm"]), p(r["p_tost_holm"])
        t[f"{h}_A"], t[f"{h}_B"], t[f"{h}_v"] = f(r["A"]), f(r["B"]), r["verdict"]
        t[f"{h}_pct"] = f(100 * (float(r["irr"]) - 1), 1)
        body.append([h, f(r["irr"]), ci(r["lo95"], r["hi95"]), p(r["p_holm"]), p(r["p_tost_holm"]),
                     f"{f(r['A'])} / {f(r['B'])}", "yes" if r["replicated"] == "TRUE" else "no",
                     r["verdict"]])
    r = H["H5"]
    t["H5_v"], t["H5_p"] = r["verdict"], p(r["p_holm"])
    body.append(["H5", f(r["est"], 4) + " nats", ci(r["lo95"], r["hi95"], 4), p(r["p_holm"]), "--",
                 f"{f(r['A'], 4)} / {f(r['B'], 4)}", "yes" if r["replicated"] == "TRUE" else "no",
                 r["verdict"]])
    t["TABLE_CONFIRMATORY"] = md_table(
        ["H", "Estimate (IRR or Δ)", "95% CI", "p (Holm)", "p TOST (Holm)", "Half A / B",
         "Replicated", "Verdict"], body)

    h5 = {r["metric"]: float(r["value"]) for r in rows("04_h5_prediction.csv")}
    t["H5_delta"] = f(h5["delta_post"], 4)
    t["H5_ci"] = ci(h5["delta_lo95"], h5["delta_hi95"], 4)
    t["H5_60"] = f(h5["delta_post_60nodes"], 4)
    t["H5_acctw"] = f(h5["delta_account_weighted"], 4)
    t["H5_A"], t["H5_B"] = f(h5["delta_A"], 4), f(h5["delta_B"], 4)
    t["H5_ls0"], t["H5_ls2"] = f(h5["logscore_post_M0"], 4), f(h5["logscore_post_M2"], 4)
    t["H5_rho0"], t["H5_rho2"] = f(h5["spearman_rate_M0"]), f(h5["spearman_rate_M2"])
    t["H5_gm"] = f(100 * (math.exp(h5["delta_post"]) - 1), 2)
    t["test_posts"], t["test_accounts"] = n(h5["test_posts"]), n(h5["test_accounts"])

    cal = rows("04_h5_calibration.csv")
    t["TABLE_CALIB"] = md_table(["Model", "Coverage 50%", "Coverage 90%", "PIT mean", "PIT SD", "KS D"],
                                [[r["model"], f(r["cover50"]), f(r["cover90"]), f(r["pit_mean"]),
                                  f(r["pit_sd"]), f(r["ks_D"])] for r in cal])
    for r in cal:
        t[f"cal_{r['model']}_50"], t[f"cal_{r['model']}_90"] = f(r["cover50"]), f(r["cover90"])

    ex = {r["quantity"]: r for r in rows("04_extra_quantities.csv")}
    e = ex["follower elasticity R1_M2"]
    t["EL_M2"], t["EL_M2_ci"] = f(e["est"]), ci(e["lo95"], e["hi95"])
    e = ex["follower elasticity R1_M1"]
    t["EL_M1"], t["EL_M1_ci"] = f(e["est"]), ci(e["lo95"], e["hi95"])
    e = ex["IRR one person vs none (M2, combined)"]
    t["ONE_PERSON"], t["ONE_PERSON_ci"] = f(e["est"]), ci(e["lo95"], e["hi95"])
    t["ONE_PERSON_pct"] = f(100 * (float(e["est"]) - 1), 0)

    dg = {r["model"]: r for r in rows("04_model_diagnostics.csv")}
    t["all_converged"] = "all" if all(r["converged"] == "TRUE" and r["pdHess"] == "TRUE"
                                      for r in dg.values()) else "not all"
    t["nonconv"] = ", ".join(k for k, r in dg.items()
                             if not (r["converged"] == "TRUE" and r["pdHess"] == "TRUE")) or "none"
    for m in ["M1", "M2", "R4_M2", "M2_train", "M0_train"]:
        t[f"theta_{m}"], t[f"su_{m}"] = f(dg[m]["theta"]), f(dg[m]["sigma_u"])
    bad = [k for k, r in dg.items() if not (r["converged"] == "TRUE" and r["pdHess"] == "TRUE")]
    refit = sorted(p.name.replace("_firstfit.rds", "") for p in (ROOT / "data/models").glob("*_firstfit.rds"))
    t["CONVERGENCE_SENTENCE"] = (
        f"All {len(dg)} fitted models converged with positive-definite Hessians"
        + (f". {', '.join(refit)} reported a false-convergence warning from nlminb; re-optimisation from its own estimates with an independent optimiser (BFGS) converged to the same optimum (identical log-likelihood and coefficients; D20)." if refit else ".")
        if not bad else f"Models {', '.join(bad)} did not pass the convergence checks and are not used for confirmatory verdicts.")
    t["TABLE_DIAG"] = md_table(["Model", "Posts", "Accounts", "θ", "σ_u", "Converged", "pd Hessian"],
                               [[k, n(r["n"]), n(r["accounts"]), f(r["theta"]), f(r["sigma_u"]),
                                 r["converged"].lower(), r["pdHess"].lower()]
                                for k, r in sorted(dg.items())])

    rob = rows("04_robustness.csv")
    lab = {"z_AestheticScore": "Aesthetic (H1)", "person_present": "Person (H2)",
           "z_VividColorScore": "Vivid colour (H3)"}
    desc = {"M1": "Main", "M2": "Main", "R1_M1": "R1 followers free", "R1_M2": "R1 followers free",
            "R2_M1": "R2 2019 only", "R2_M2": "R2 2019 only", "R3_M1": "R3 comments",
            "R3_M2": "R3 comments", "R4_M1": "R4 ≥ 2 posts", "R4_M2": "R4 ≥ 2 posts",
            "R5_M2W": "R5 full Mundlak (within)", "R6_M1": "R6 extremes removed",
            "R6_M2": "R6 extremes removed"}
    t["TABLE_ROBUST"] = md_table(["Term", "Specification", "IRR", "95% CI"],
                                 [[lab[r["term"]], desc.get(r["model"], r["model"]), f(r["irr"]),
                                   ci(r["lo95"], r["hi95"])] for r in rob])
    t["rob_rows"] = {}
    got = {(r["model"], r["term"]): f"{f(r['irr'])} {ci(r['lo95'], r['hi95'])}" for r in rob}
    parts = []
    for m1, m2, text in [("R2_M1", "R2_M2", "Restricting to 2019 posts (R2)"),
                         ("R6_M1", "R6_M2", "Removing extreme observations (R6)"),
                         ("R3_M1", "R3_M2", "Using comments as the outcome (R3)")]:
        a, b = got.get((m1, "z_AestheticScore")), got.get((m2, "person_present"))
        if a and b:
            parts.append(f"{text} gives aesthetic {a} and person {b}.")
    if ("R5_M2W", "person_present") in got:
        parts.append(f"In the full Mundlak model (R5), the within-account associations are person "
                     f"{got[('R5_M2W', 'person_present')]} and vivid colour {got[('R5_M2W', 'z_VividColorScore')]}.")
    t["ROBUST_REST"] = " ".join(parts)
    for r in rob:
        t[f"rob_{r['model']}_{r['term']}"] = f"{f(r['irr'])} {ci(r['lo95'], r['hi95'])}"

    coef = {}
    for path in T.glob("03_coef_*.csv"):
        for r in csv.DictReader(open(path)):
            coef[(r["model"], r["term"])] = r
    for (m, term), r in coef.items():
        if m in ("M2", "M1W", "R5_M2W"):
            key = re.sub(r"\W", "_", term)
            t[f"c_{m}_{key}"] = f"{f(r['irr'])} {ci(r['lo95'], r['hi95'])}"
            t[f"i_{m}_{key}"] = f(r["irr"])

    w = {r["term"]: float(r["est"]) for r in csv.DictReader(open(T / "03_coef_M1W.csv"))}
    t["BETWEEN_AES"] = f(math.exp(w["z_AestheticScore"] + w["m_z_AestheticScore"]))
    t["BETWEEN_PERSON"] = f(math.exp(w["person_present"] + w["m_person_present"]))

    pl = {r["image_shot"]: r for r in rows("04_feature_plausibility_by_shot.csv")}
    t["pl_selfie"] = f(100 * float(pl["Selife Shot"]["person_share"]), 1)
    t["pl_portrait"] = f(100 * float(pl["Portrait Shot"]["person_share"]), 1)
    t["pl_aerial"] = f(100 * float(pl["Aerial Shot"]["person_share"]), 1)
    t["pl_closeup"] = f(100 * float(pl["Close Up Shot"]["person_share"]), 1)
    t["pl_dof_ecu"] = f(pl["Extreme Close Up Shot"]["mean_z_DoF"], 2)
    t["pl_dof_ews"] = f(pl["Extreme Wide Shot"]["mean_z_DoF"], 2)

    cr = rows("04_attribute_correlations_train.csv")
    attrs = [c for c in cr[0] if c not in ("feature", "z_AestheticScore")]
    vals = [abs(float(r[c])) for r in cr if r["feature"] in attrs for c in attrs if c != r["feature"]]
    t["corr_max"], t["corr_med"] = f(max(vals), 2), f(sorted(vals)[len(vals) // 2], 2)
    t["TABLE_CORR"] = md_table([""] + [a.replace("z_", "").replace("Score", "")[:6] for a in attrs],
                               [[r["feature"].replace("z_", "").replace("Score", "")] +
                                [f(r[c], 2) for c in attrs] for r in cr if r["feature"] in attrs])

    sens = rows("04_sesoi_sensitivity.csv")
    t["TABLE_SENS"] = md_table(["H", "±1%: outside / inside", "±3%", "±5%"],
                               [[h] + [f"{'yes' if s['outside'] == 'TRUE' else 'no'} / "
                                       f"{'yes' if s['inside'] == 'TRUE' else 'no'}"
                                       for s in sens if s["H"] == h] for h in ["H1", "H2", "H3", "H4"]])
    del t["rob_rows"]
    return t


def main(path, draft=False):
    t = tokens(draft)
    text = pathlib.Path(path).read_text()
    missing = sorted(set(re.findall(r"\{\{(\w+)\}\}", text)) - set(t))
    if missing and not draft:
        sys.exit(f"unfilled tokens: {missing}")
    t.update({k: "[pending: model results]" for k in missing})
    out = re.sub(r"\{\{(\w+)\}\}", lambda m: str(t[m[1]]), text)
    sys.stdout.write(out.replace("p = < ", "p < "))


if __name__ == "__main__":
    main(sys.argv[1], draft="--draft" in sys.argv)
