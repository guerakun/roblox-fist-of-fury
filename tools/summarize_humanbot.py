"""Summarize saved HumanBot evidence without changing its measurements."""
import argparse
import json
from pathlib import Path
from statistics import mean

parser = argparse.ArgumentParser()
parser.add_argument('reports', nargs='+', type=Path)
parser.add_argument('--source', default='unspecified')
parser.add_argument('--output', type=Path)
args = parser.parse_args()
rows = []
for path in args.reports:
    raw = json.loads(path.read_text(encoding='utf-8-sig'))
    bot = raw.get('bot', raw)
    if not bot.get('done'):
        raise ValueError(f'{path}: incomplete run cannot enter the aggregate')
    telemetry = bot.get('telemetry') or {}
    audit = raw.get('frustum') or {}
    server_hits = telemetry.get('hits')
    server_hit_count = sum(server_hits.values()) if isinstance(server_hits, dict) else (0 if server_hits == [] else None)
    rows.append({
        'file': path.name, 'seed': bot['seed'], 'clear': bot.get('clear', False), 'outcome': bot.get('outcome'),
        'seconds': bot['seconds'], 'stocksLost': sum(bot['stocksLostByDistrict'].values()) if isinstance(bot.get('stocksLostByDistrict'), dict) else None,
        'stocksLostByDistrict': bot.get('stocksLostByDistrict'), 'damageTaken': bot['damageTaken'],
        'idleTicks': telemetry.get('idleGruntTicks'), 'eligibleTicks': telemetry.get('eligibleGruntTicks'),
        'flankedWindows': telemetry.get('flankedWindows'), 'flankWindows': telemetry.get('flankWindows'),
        'capViolations': telemetry.get('capViolations'), 'minWindup': telemetry.get('minWindup'),
        'serverAcceptedHits': server_hit_count, 'frustumFixture': audit.get('fixture'), 'frustumAuditedHits': audit.get('hits'), 'frustumOutside': audit.get('outside'),
        'frustumInvalidViewportHits': audit.get('invalidViewportHits'),
        'diversityByKind': telemetry.get('actionDiversity', {}).get('byKind', {}),
    })
if len({r['seed'] for r in rows}) != len(rows):
    raise ValueError('Duplicate seed in comparison set')
def total(key):
    return sum(r[key] for r in rows) if all(r[key] is not None for r in rows) else None
def average(key):
    return mean(r[key] for r in rows) if all(r[key] is not None for r in rows) else None
def ratio(numerator, denominator):
    n, d = total(numerator), total(denominator)
    return n / d if n is not None and d else None
diversity = {}
for row in rows:
    for kind, values in row['diversityByKind'].items():
        out = diversity.setdefault(kind, {'eligible': 0, 'passed': 0, 'minDistinct': None})
        out['eligible'] += values.get('eligible', 0)
        out['passed'] += values.get('passed', 0)
        value = values.get('minDistinct')
        if isinstance(value, (int, float)) and not isinstance(value, bool):
            out['minDistinct'] = value if out['minDistinct'] is None else min(out['minDistinct'], value)
result = {
    'sourceCommit': args.source, 'runs': len(rows), 'clears': sum(r['clear'] for r in rows),
    'meanSeconds': average('seconds'), 'meanStocksLost': average('stocksLost'),
    'meanDamageTaken': average('damageTaken'),
    'pooledIdleTicks': total('idleTicks'), 'pooledEligibleTicks': total('eligibleTicks'),
    'pooledIdleRatio': ratio('idleTicks', 'eligibleTicks'),
    'pooledFlankedWindows': total('flankedWindows'), 'pooledFlankWindows': total('flankWindows'),
    'pooledFlankRatio': ratio('flankedWindows', 'flankWindows'),
    'serverAcceptedHits': total('serverAcceptedHits'),
    'hitObservationCoverageComplete': all(r['serverAcceptedHits'] is not None and r['frustumAuditedHits'] is not None and r['frustumInvalidViewportHits'] is not None and r['serverAcceptedHits']==r['frustumAuditedHits']+r['frustumInvalidViewportHits'] for r in rows),
    'capViolations': total('capViolations'), 'actionDiversityByKind': diversity,
    'frustum': {key: sum(r[key] for r in rows) if all(r[key] is not None for r in rows) else None
                for key in ('frustumAuditedHits', 'frustumOutside', 'frustumInvalidViewportHits')},
    'completeMetrics': {key: all(r[key] is not None for r in rows) for key in ('serverAcceptedHits', 'stocksLost', 'idleTicks', 'eligibleTicks', 'flankedWindows', 'flankWindows', 'capViolations', 'frustumAuditedHits', 'frustumOutside', 'frustumInvalidViewportHits')},
    'frustumFixturesValid': all(isinstance(r['frustumFixture'], dict) and r['frustumFixture'].get('passed') is True and r['frustumFixture'].get('width', 0)>1 and r['frustumFixture'].get('height', 0)>1 for r in rows),
    'rows': rows,
    'limit': 'Bot campaigns only. Missing/zero eligible archetype windows are inconclusive; no human/device acceptance implied.',
}
if args.output:
    args.output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: v for k, v in result.items() if k not in ('rows', 'actionDiversityByKind')}, indent=2))
