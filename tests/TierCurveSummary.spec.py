"""Synthetic tier-summary regression; no Studio or private/gameplay report input.

Run: python -B tests/TierCurveSummary.spec.py
All generated inputs live in a disposable directory under ignored build/.
"""
import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("tier_curve", ROOT / "tools/summarize_tier_curve.py")
curve = importlib.util.module_from_spec(spec)
spec.loader.exec_module(curve)


def fixtures():
    rows = []
    for tier, wins in (("Normal", 3), ("Hard", 2), ("Nightmare", 0)):
        for index in range(5):
            won = index < wins
            results = [{"id": f"Synthetic{tier}{index}:{stage}", "stage": stage,
                        "rank": "A", "difficulty": tier, "heat": []}
                       for stage in (range(1, 4) if won else range(1, 2))]
            rows.append({
                "difficulty": tier, "sourceCommit": "synthetic-source", "botPolicyRevision": "synthetic-policy",
                "provenance": {"difficulty": tier, "sourceCommit": "synthetic-source",
                    "botPolicyRevision": "synthetic-policy", "selectedBeforeRun": True,
                    "configurationStable": True, "heat": [],
                    "initialSettings": {"hero": "Gale", "boon": "Guardian", "players": 1,
                        "profileMode": "Practice", "xp": 0, "coins": 0, "heat": [], "difficulty": tier}},
                "reconciliation": {"stocksMatch": True, "flooredDamageMatches": True,
                    "observerInvariantsPassed": True, "serverDamage": 500.75,
                    "serverStocksByDistrict": {"1": 1, "2": 1, "3": 0}, "frustumCountMatches": True,
                    "frustumFixtureValid": True, "victoryCoverageComplete": won or None},
                "reconciliationComplete": True,
                "bot": {"seed": 1101 + index, "done": True, "clear": won,
                    "outcome": "Victory" if won else "Defeat", "stage": 3 if won else 2,
                    "seconds": 300, "damageTaken": 500,
                    # Defeat in district2 cannot include any district3 stock loss.
                    "stocksLostByDistrict": {"1": 1, "2": 1, "3": 0}, "districtResults": results}})
    return rows


def main():
    base = fixtures()
    checks = 0
    with tempfile.TemporaryDirectory(dir=ROOT / "build", prefix="tier-summary-spec-") as directory:
        directory = Path(directory)
        # Synthetic comparison baselines exercise the loader, not game acceptance.
        for filename in ("baseline-summary.json", "m2-final-summary.json"):
            (directory / filename).write_text(json.dumps({"runs": 5, "clears": 5,
                "meanSeconds": 300, "meanStocksLost": .8, "meanDamageTaken": 500,
                "sourceCommit": "synthetic-before"}), encoding="utf-8")

        def evaluate(rows):
            paths = []
            for index, row in enumerate(rows):
                path = directory / f"trial-{index}.json"
                path.write_text(json.dumps(row), encoding="utf-8")
                paths.append(path)
            return curve.summarize(paths, baseline_dir=directory)

        def check(condition, label):
            nonlocal checks
            assert condition, label
            checks += 1

        def rejects(label, mutate):
            rows = copy.deepcopy(base)
            mutate(rows)
            check(not evaluate(rows)["measuredCurvePassed"], label)

        def set_stocks(row, stocks):
            row["bot"]["stocksLostByDistrict"] = copy.deepcopy(stocks)
            row["reconciliation"]["serverStocksByDistrict"] = copy.deepcopy(stocks)

        result = evaluate(base)
        check(result["measuredCurvePassed"], "complete consistent curve passes")
        check(result["allDistrictClearsIncludingPartialDefeats"] == 25, "partial-defeat clears included")
        check(result["before"]["M0"]["meanStocksLost"] == .8, "comparison baseline loaded")
        check(not evaluate(base[:-1])["measuredCurvePassed"], "missing run rejects")
        rejects("duplicate seed", lambda r: r[1]["bot"].update(seed=1101))
        rejects("mixed top-level source", lambda r: r[1].update(sourceCommit="other"))
        rejects("missing top-level policy", lambda r: r[1].pop("botPolicyRevision"))
        rejects("timeout", lambda r: r[1]["bot"].update(outcome="Timeout", clear=False))
        rejects("not done", lambda r: r[1]["bot"].update(done=False))
        rejects("clear/outcome mismatch", lambda r: r[1]["bot"].update(clear=False))
        rejects("missing results", lambda r: r[1]["bot"].pop("districtResults"))
        rejects("missing earlier district rank", lambda r: r[4]["bot"].update(districtResults=[]))
        rejects("duplicate rank identity", lambda r: r[1]["bot"]["districtResults"][1].update(id=r[1]["bot"]["districtResults"][0]["id"]))
        rejects("missing stocks", lambda r: r[1]["bot"].pop("stocksLostByDistrict"))
        rejects("fractional stock count", lambda r: r[1]["bot"]["stocksLostByDistrict"].update({"1": .5}))
        rejects("boolean stock count", lambda r: r[1]["bot"]["stocksLostByDistrict"].update({"1": True}))
        rejects("NaN duration", lambda r: r[1]["bot"].update(seconds=float("nan")))
        rejects("missing damage", lambda r: r[1]["bot"].pop("damageTaken"))
        rejects("non-scalar seed", lambda r: r[1]["bot"].update(seed=[]))
        rejects("non-scalar rank", lambda r: r[1]["bot"]["districtResults"][0].update(rank={}))
        rejects("missing terminal stage", lambda r: r[1]["bot"].update(stage=None))
        rejects("wrong Victory stage", lambda r: r[1]["bot"].update(stage=2))
        rejects("too few Normal stocks", lambda r: [set_stocks(x, {"1": 0, "2": 0, "3": 0}) for x in r if x["difficulty"] == "Normal"])
        rejects("future district stocks cannot satisfy Normal mean", lambda r: [set_stocks(x, {"1": 0, "2": 0, "3": 2}) for x in r if x["difficulty"] == "Normal"])

        for field, value in (("sourceCommit", "other"), ("botPolicyRevision", "other"),
                             ("difficulty", "Nightmare"), ("heat", ["Frenzy"]),
                             ("configurationStable", False), ("selectedBeforeRun", False),
                             ("configurationStable", 1), ("selectedBeforeRun", 1)):
            rejects("contradictory captured provenance " + field + repr(value),
                    lambda r, f=field, v=value: r[0]["provenance"].update({f: v}))
        for field, value in (("hero", "Tide"), ("boon", "GlassCannon"), ("players", 4),
                             ("xp", 1), ("coins", 1), ("heat", ["Frenzy"]),
                             ("profileMode", "Live"), ("difficulty", "Hard"), ("status", "Combat")):
            rejects("nonbaseline captured setting " + field,
                    lambda r, f=field, v=value: r[0]["provenance"]["initialSettings"].update({f: v}))
        for field in ("stocksMatch", "flooredDamageMatches", "observerInvariantsPassed"):
            for value in (False, None, 1):
                rejects("invalid supplied accounting " + field + repr(value),
                        lambda r, f=field, v=value: r[0]["reconciliation"].update({f: v}))
        for field, value in (("serverDamage", 499.75), ("serverDamage", float("nan")),
                             ("serverDamage", True), ("serverDamage", None),
                             ("serverStocksByDistrict", {"1": 2, "2": 1, "3": 0}),
                             ("serverStocksByDistrict", {"1": 1, "2": 1}),
                             ("serverStocksByDistrict", {"1": True, "2": 1, "3": 0}),
                             ("serverStocksByDistrict", [])):
            rejects("contradictory raw reconciliation " + field + repr(value),
                    lambda r, f=field, v=value: r[0]["reconciliation"].update({f: v}))
        rejects("malformed provenance", lambda r: r[0].update(provenance=[]))
        rejects("malformed initial settings", lambda r: r[0]["provenance"].update(initialSettings=[]))
        rejects("malformed reconciliation", lambda r: r[0].update(reconciliation=[]))
        rejects("boolean player count", lambda r: r[0]["provenance"]["initialSettings"].update(players=True))
        rejects("district result tier contradiction", lambda r: r[0]["bot"]["districtResults"][0].update(difficulty="Hard"))
        rejects("district result Heat contradiction", lambda r: r[0]["bot"]["districtResults"][0].update(heat=["Frenzy"]))

        rows = copy.deepcopy(base)
        rows[0]["reconciliation"]["serverDamage"] = 500 - 1e-10
        check(evaluate(rows)["measuredCurvePassed"], "collector floating-damage tolerance remains consistent")
        rows = copy.deepcopy(base)
        for row in rows:
            row["provenance"]["initialSettings"]["status"] = "Waiting"
        check(evaluate(rows)["measuredCurvePassed"], "optional explicit Waiting status accepted")
        rows = copy.deepcopy(base)
        for row in rows:
            row.pop("provenance")
            row.pop("reconciliation")
            row.pop("reconciliationComplete")
        check(evaluate(rows)["measuredCurvePassed"], "legacy top-only wrapper remains compatible")
        raw = []
        for row in rows:
            bot = row.pop("bot")
            bot.update(row)
            raw.append(bot)
        check(evaluate(raw)["measuredCurvePassed"], "legacy unwrapped reports remain compatible")
        rows = copy.deepcopy(base)
        for row in rows:
            row["reconciliation"].update(frustumCountMatches=None, frustumFixtureValid=False)
            row["reconciliationComplete"] = False
            row["cameraMotion"] = {"comfortVerified": False, "physicalInputVerified": False}
        check(evaluate(rows)["measuredCurvePassed"], "fairness/device evidence is separate from measured curve")

        rows = copy.deepcopy(base)
        for row in rows:
            if row["bot"]["outcome"] == "Defeat":
                row["bot"]["districtResults"][0]["rank"] = "S"
        result = evaluate(rows)
        check(result["sRankFrequency"] == .4 and not result["measuredCurvePassed"], "partial-defeat S ranks count")
        rows = copy.deepcopy(base)
        for row in rows[-5:]:
            row["bot"].update(stage=1, districtResults=[], stocksLostByDistrict={"1": 2, "2": 0, "3": 0})
            row["reconciliation"]["serverStocksByDistrict"] = {"1": 2, "2": 0, "3": 0}
        for row in rows[:5]:
            row["bot"]["districtResults"][0]["rank"] = "S"
        result = evaluate(rows)
        check(result["gates"]["completeEvidence"] and result["sRankFrequency"] == .25 and not result["gates"]["sRanksBelowQuarter"], "exact25percent fails strict target")
    print(f"PASS: {checks} synthetic tier-summary assertions; no gameplay evidence produced")


if __name__ == "__main__":
    main()
