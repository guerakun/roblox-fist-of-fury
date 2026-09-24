"""Read saved M3 trials. Never run Studio, modify reports, or manufacture missing evidence.

Each raw report or {bot: report} wrapper must carry top-level difficulty,
sourceCommit and botPolicyRevision, recorded by the collector at run time.
Exit 0 means the complete measured bot curve passed; exit 1 means unmet/incomplete
gates; exit 2 is a CLI/file error. No exit status certifies the whole milestone.
"""
import argparse
import json
import math
from pathlib import Path
from statistics import mean

TIERS = ("Normal", "Hard", "Nightmare")
SEEDS = set(range(1101, 1106))
RANKS = set("DCBAS")


def finite(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and value >= 0


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def read_trial(path):
    raw = load(path)
    errors = []
    if not isinstance(raw, dict):
        return {"file": str(path), "errors": ["Report must be an object"]}
    bot = raw.get("bot", raw)
    if not isinstance(bot, dict):
        return {"file": str(path), "errors": ["bot must be an object"]}
    row = {"file": str(path), "difficulty": raw.get("difficulty"), "seed": bot.get("seed"),
           "sourceCommit": raw.get("sourceCommit"), "botPolicyRevision": raw.get("botPolicyRevision"),
           "outcome": bot.get("outcome"), "seconds": bot.get("seconds"),
           "damageTaken": bot.get("damageTaken"), "stage": bot.get("stage"), "errors": errors}
    if not isinstance(row["difficulty"], str):
        row["difficulty"] = None
    if row["difficulty"] not in TIERS:
        errors.append("Missing/unknown difficulty provenance")
    for key in ("sourceCommit", "botPolicyRevision"):
        if not isinstance(row[key], str) or not row[key].strip():
            errors.append("Missing " + key)
            row[key] = None
    if type(row["seed"]) is not int or row["seed"] not in SEEDS:
        errors.append("Expected integer seed 1101-1105")
        row["seed"] = None
    if bot.get("done") is not True:
        errors.append("Incomplete run")
    if not isinstance(row["outcome"], str):
        row["outcome"] = None
    if row["outcome"] not in ("Victory", "Defeat"):
        errors.append("Nonterminal outcome/timeout is not a valid curve trial")
    if type(bot.get("clear")) is not bool or bot["clear"] != (row["outcome"] == "Victory"):
        errors.append("clear flag does not agree with outcome")
    for key in ("seconds", "damageTaken"):
        if not finite(row[key]):
            errors.append("Missing/invalid " + key)
            row[key] = None
    if type(row["stage"]) is not int or row["stage"] not in (1, 2, 3):
        errors.append("Missing/invalid terminal stage")
        row["stage"] = None
    if row["outcome"] == "Victory" and row["stage"] != 3:
        errors.append("Victory must finish district3")
    stocks = bot.get("stocksLostByDistrict")
    if not isinstance(stocks, dict) or set(stocks) != {"1", "2", "3"} or any(
            not finite(value) or int(value) != value for value in stocks.values()):
        row["stocksLost"] = None
        row["stocksLostByDistrict"] = None
        errors.append("Missing/invalid district stock counters")
    else:
        row["stocksLostByDistrict"] = stocks
        row["stocksLost"] = sum(stocks.values())
    districts = bot.get("districtResults")
    row["districtRanks"] = []
    if not isinstance(districts, list):
        errors.append("Missing districtResults; absence is not zero clears")
    else:
        seen_stages, seen_ids = set(), set()
        for result in districts:
            if not isinstance(result, dict):
                errors.append("Invalid district result")
                continue
            stage, rank, identity = result.get("stage"), result.get("rank"), result.get("id")
            if type(stage) is not int or stage not in (1, 2, 3) or not isinstance(rank, str) or rank not in RANKS or not isinstance(identity, str) or not identity:
                errors.append("Invalid district identity/stage/rank")
                continue
            if stage in seen_stages or identity in seen_ids:
                errors.append("Duplicate district clear")
                continue
            seen_stages.add(stage)
            seen_ids.add(identity)
            row["districtRanks"].append({"stage": stage, "rank": rank, "id": identity})
        expected = {1, 2, 3} if row["outcome"] == "Victory" else (
            set(range(1, row["stage"])) if type(row["stage"]) is int and row["stage"] in (1, 2, 3) else set())
        if not expected.issubset(seen_stages):
            errors.append("Missing ranks for already-cleared districts")
        if row["outcome"] == "Defeat" and row["stage"] is not None and any(stage > row["stage"] for stage in seen_stages):
            errors.append("District rank is beyond terminal stage")
    return row


def summarize(paths, baseline_dir=None):
    rows = [read_trial(path) for path in paths]
    errors = []
    source_values = {row.get("sourceCommit") for row in rows if isinstance(row.get("sourceCommit"), str)}
    bot_values = {row.get("botPolicyRevision") for row in rows if isinstance(row.get("botPolicyRevision"), str)}
    provenance = bool(rows) and len(source_values) == 1 and len(bot_values) == 1 and all(
        isinstance(row.get(key), str) and row[key].strip() for row in rows for key in ("sourceCommit", "botPolicyRevision"))
    if not provenance:
        errors.append("Every trial must declare the same gameplay source and bot policy revisions")
    result = {"schema": 1, "scope": "Solo bot difficulty/rank curve only; not full M3 acceptance",
              "sourceCommit": next(iter(source_values)) if len(source_values) == 1 else None,
              "botPolicyRevision": next(iter(bot_values)) if len(bot_values) == 1 else None,
              "provenanceConsistent": provenance, "tiers": {}, "errors": errors, "rows": rows}
    all_ranks = []
    def average(items, key):
        return mean(row[key] for row in items) if items and all(finite(row.get(key)) for row in items) else None
    for tier in TIERS:
        group = [row for row in rows if row.get("difficulty") == tier]
        seeds = [row.get("seed") for row in group]
        unique = len(seeds) == len(set(str(value) for value in seeds))
        complete = len(group) == 5 and unique and set(seeds) == SEEDS and all(not row["errors"] for row in group)
        clears = sum(row.get("outcome") == "Victory" for row in group)
        ranks = [district for row in group for district in row.get("districtRanks", [])]
        all_ranks.extend(ranks)
        s_count = sum(district["rank"] == "S" for district in ranks)
        target = {"Normal": (3, 4), "Hard": (2,), "Nightmare": (0,)}[tier]
        result["tiers"][tier] = {
            "runs": len(group), "uniqueSeeds": unique, "missingSeeds": sorted(SEEDS - {s for s in seeds if type(s) is int}),
            "complete": complete, "clears": clears, "clearRate": clears / len(group) if group else None,
            "requiredClearsOutOfFive": list(target), "clearRateTargetPassed": complete and clears in target,
            "meanSeconds": average(group, "seconds"), "meanStocksLost": average(group, "stocksLost"),
            "meanDamageTaken": average(group, "damageTaken"),
            "meanStocksLostByDistrict": {str(stage): mean(row["stocksLostByDistrict"][str(stage)] for row in group)
                if group and all(row.get("stocksLostByDistrict") is not None for row in group) else None for stage in (1, 2, 3)},
            "districtClears": len(ranks), "sRanks": s_count, "sRankFrequency": s_count / len(ranks) if ranks else None,
            "terminalDefeatsByStage": {str(stage): sum(row.get("outcome") == "Defeat" and row.get("stage") == stage for row in group)
                                      for stage in (1, 2, 3)},
        }
    data_complete = provenance and len(rows) == 15 and all(value["complete"] for value in result["tiers"].values())
    rank_count = len(all_ranks)
    s_count = sum(district["rank"] == "S" for district in all_ranks)
    stock_mean = result["tiers"]["Normal"]["meanStocksLost"]
    result["gates"] = {
        "completeEvidence": data_complete,
        "tierClearRates": data_complete and all(value["clearRateTargetPassed"] for value in result["tiers"].values()),
        "normalMeanStocksAtLeastTwo": data_complete and stock_mean is not None and stock_mean >= 2,
        "sRanksBelowQuarter": data_complete and rank_count > 0 and s_count / rank_count < .25,
    }
    result["allDistrictClearsIncludingPartialDefeats"] = rank_count
    result["sRanks"] = s_count
    result["sRankFrequency"] = s_count / rank_count if rank_count else None
    result["measuredCurvePassed"] = all(result["gates"].values())
    result["limits"] = ["Five trials per tier have 20 percentage-point resolution; no statistical certification.",
        "Timeouts, missing ranks, missing metrics and mixed revisions prevent a pass.",
        "All recorded trials enter means; defeated campaigns still contribute already-cleared district ranks.",
        "Early-stock rarity and final-boss wipe concentration are qualitative review, not invented thresholds.",
        "Real human tests per tier, multiplayer, camera/device and reward-security evidence remain separate."]
    if baseline_dir is None:
        baseline_dir = Path(__file__).resolve().parents[1] / "docs" / "launch" / "evidence"
    result["before"] = {}
    for name, filename in (("M0", "baseline-summary.json"), ("M2", "m2-final-summary.json")):
        try:
            before = load(Path(baseline_dir) / filename)
            result["before"][name] = {key: before.get(key) for key in ("runs", "clears", "meanSeconds", "meanStocksLost", "meanDamageTaken")}
            result["before"][name]["sourceCommit"] = before.get("sourceCommit", before.get("baselineGameplay"))
            result["before"][name]["file"] = filename
        except (OSError, ValueError):
            result["before"][name] = {"available": False}
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reports", nargs="+", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.output and args.output.resolve() in {path.resolve() for path in args.reports}:
        parser.error("Output must not overwrite an input report")
    try:
        result = summarize(args.reports)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    encoded = json.dumps(result, indent=2, allow_nan=False) + "\n"
    if args.output:
        args.output.write_bytes(encoded.encode("utf-8"))
    print(json.dumps({key: value for key, value in result.items() if key != "rows"}, indent=2, allow_nan=False))
    return 0 if result["measuredCurvePassed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
