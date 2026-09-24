"""Validate and anonymize one saved Studio trial; retain the raw input under ignored build/."""
import argparse
import copy
import json
import math
from pathlib import Path


def prepare(raw):
    report = copy.deepcopy(raw)
    bot, provenance = report['bot'], report['provenance']
    settings = provenance['initialSettings']
    assert provenance['configurationStable'] is True and provenance['selectedBeforeRun'] is True
    assert provenance['difficulty'] in ('Normal', 'Hard', 'Nightmare')
    for key in ('sourceCommit', 'botPolicyRevision'):
        assert isinstance(provenance.get(key), str) and provenance[key].strip(), 'Missing source provenance'
    if 'status' in settings:
        assert settings['status'] == 'Waiting'
    report['preflightScope'] = 'Tier fixture asserted Waiting before selection; disabled bot enabled only after root checked fresh defaults. Initial settings status was not separately captured.' if 'status' not in settings else 'Captured initial Waiting status and fresh defaults checked before bot enabled.'
    assert settings['hero'] == 'Gale' and settings['boon'] == 'Guardian'
    assert settings['xp'] == 0 and settings['coins'] == 0
    assert settings['players'] == 1 and settings['profileMode'] == 'Practice'
    assert settings['difficulty'] == provenance['difficulty'] and settings['heat'] == []
    assert bot['done'] is True, 'Save incomplete reports separately, not as a terminal curve trial'
    report.update(schema=1, difficulty=provenance['difficulty'], sourceCommit=provenance['sourceCommit'],
                  botPolicyRevision=provenance['botPolicyRevision'])
    telemetry = bot['telemetry']
    ids = sorted({key for field in ('hits', 'stocks', 'damage')
                  for key in (telemetry.get(field) or {}) if key.lstrip('-').isdigit()})
    aliases = {key: 'Player' + str(index + 1) for index, key in enumerate(ids)}
    for field in ('hits', 'stocks', 'damage'):
        if isinstance(telemetry.get(field), dict):
            telemetry[field] = {aliases.get(key, key): value for key, value in telemetry[field].items()}
    def values(value):
        assert value == [] or isinstance(value, dict)
        return value.values() if isinstance(value, dict) else []
    server_damage = sum(values(telemetry['damage']))
    server_stocks = {str(stage): sum(player.get(str(stage), 0) for player in values(telemetry['stocks']))
                     for stage in (1, 2, 3)}
    hits = sum(values(telemetry['hits']))
    frustum = report.get('frustum') or {}
    observer = report.get('styleObserver') or {}
    report['reconciliation'] = {
        'serverDamage': server_damage,
        'flooredDamageMatches': bot['damageTaken'] == math.floor(server_damage + 1e-8),
        'serverStocksByDistrict': server_stocks,
        'stocksMatch': bot['stocksLostByDistrict'] == server_stocks,
        'serverAcceptedHits': hits,
        'frustumCountMatches': hits == frustum['hits'] + frustum['invalidViewportHits'] if all(key in frustum for key in ('hits', 'invalidViewportHits')) else None,
        'frustumFixtureValid': (frustum.get('fixture') or {}).get('passed') is True,
        'observerInvariantsPassed': observer.get('invariantsPassed') is True,
        'victoryCoverageComplete': observer.get('campaignCoverageComplete') if bot['clear'] else None,
    }
    report['privacy'] = 'Account identifiers replaced by run-local Player labels; raw input stays in ignored build/private-qa.'
    report['scope'] = 'Fresh solo scripted bot campaign. Telemetry rank placeholder is superseded by frozen districtResults. Human/device/live acceptance is separate.'
    if not report.get('cameraMotion'):
        report['cameraMotionScope'] = 'Not installed for this trial; frustum hit audit is separate from camera comfort.'
    else:
        report['cameraMotionScope'] = 'Passive desktop observer adds unmeasured overhead; not physical-device or subjective comfort verification.'
    required = ('flooredDamageMatches', 'stocksMatch', 'frustumCountMatches', 'frustumFixtureValid', 'observerInvariantsPassed')
    report['reconciliationComplete'] = all(report['reconciliation'][key] is True for key in required) and (not bot['clear'] or report['reconciliation']['victoryCoverageComplete'] is True)
    def identity_guard(value):
        if isinstance(value, dict):
            for key, item in value.items():
                assert not key.lower().endswith('userid'), 'Unexpected named account identifier field: ' + key
                identity_guard(item)
        elif isinstance(value, list):
            for item in value:
                identity_guard(item)
    identity_guard(report)
    serialized = json.dumps(report, indent=2, allow_nan=False) + '\n'
    for identity in ids:
        assert '"' + identity + '"' not in serialized, 'Account identifier remains'
    return report, serialized


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('raw', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    assert args.raw.resolve() != args.output.resolve(), 'Preserve the original raw input'
    report, serialized = prepare(json.loads(args.raw.read_text(encoding='utf-8-sig')))
    args.output.write_text(serialized, encoding='utf-8')
    bot = report['bot']
    print(json.dumps({'difficulty': report['difficulty'], 'seed': bot['seed'], 'outcome': bot['outcome'],
                      'seconds': bot['seconds'], 'stocks': bot['stocksLostByDistrict'], 'damage': bot['damageTaken'],
                      'ranks': [d['rank'] for d in bot['districtResults']], 'reconciliation': report['reconciliation']}, indent=2))


if __name__ == '__main__':
    main()
