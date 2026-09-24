"""Summarize stored Studio reports without manufacturing missing metrics."""
import argparse
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('reports', nargs='+', type=Path)
args = parser.parse_args()
reports = [json.loads(path.read_text(encoding='utf-8-sig')) for path in args.reports]
print('| Seed | Outcome | Seconds | Stocks lost D1/D2/D3 | Damage (snapshot) | Eligible idle | Flank windows | Peak windups |')
print('|---|---|---:|---|---:|---|---|---:|')
total_stocks = total_idle = total_eligible = total_flanks = total_windows = 0
for report in reports:
    telemetry = report.get('telemetry') or {}
    losses = report.get('stocksLostByDistrict', {})
    stocks = [losses.get(str(stage), 0) for stage in (1, 2, 3)]
    total_stocks += sum(stocks)
    idle, eligible = telemetry.get('idleGruntTicks', 0), telemetry.get('eligibleGruntTicks', 0)
    flanks, windows = telemetry.get('flankedWindows', 0), telemetry.get('flankWindows', 0)
    total_idle += idle
    total_eligible += eligible
    total_flanks += flanks
    total_windows += windows
    idle_label = f'{idle}/{eligible} ({idle/eligible:.1%})' if eligible else 'unavailable'
    flank_label = f'{flanks}/{windows} ({flanks/windows:.1%})' if windows else 'unavailable'
    print(f"| {report['seed']} | {report['outcome']} | {report['seconds']:.2f} | {'/'.join(map(str, stocks))} | {report['damageTaken']} | {idle_label} | {flank_label} | {telemetry.get('windupPeak', 'unavailable')} |")
count = len(reports)
print(f'\nClear rate: {sum(bool(r.get("clear")) for r in reports)}/{count}. Mean stocks lost: {total_stocks/count:.2f}. Mean duration: {sum(r["seconds"] for r in reports)/count:.2f} s. Mean snapshot damage: {sum(r["damageTaken"] for r in reports)/count:.2f}.')
if total_eligible:
    print(f'Pooled eligible idle: {total_idle}/{total_eligible} = {total_idle/total_eligible:.2%}.')
if total_windows:
    print(f'Pooled qualified flank windows: {total_flanks}/{total_windows} = {total_flanks/total_windows:.2%}.')
print('Rank and frustum unsupported in baseline. Five runs are a coarse engineering comparison, not human certification.')
