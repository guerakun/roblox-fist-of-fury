"""Validate and anonymize one saved Studio trial; retain the raw input under ignored build/."""
import argparse
import copy
import json
import math
import re
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
            remapped = {}
            for key, value in telemetry[field].items():
                public_key = aliases.get(key, key)
                assert public_key not in remapped, 'Telemetry alias key collision'
                remapped[public_key] = value
            telemetry[field] = remapped
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
    report['privacy'] = 'Account identifiers and generated run identifiers replaced by run-local aliases; raw input stays in ignored build/private-qa.'
    report['scope'] = 'Fresh solo scripted bot campaign. Telemetry rank placeholder is superseded by frozen districtResults. Human/device/live acceptance is separate.'
    if not report.get('cameraMotion'):
        report['cameraMotionScope'] = 'Not installed for this trial; frustum hit audit is separate from camera comfort.'
    else:
        report['cameraMotionScope'] = 'Passive desktop observer adds unmeasured overhead; not physical-device or subjective comfort verification.'
    required = ('flooredDamageMatches', 'stocksMatch', 'frustumCountMatches', 'frustumFixtureValid', 'observerInvariantsPassed')
    report['reconciliationComplete'] = all(report['reconciliation'][key] is True for key in required) and (not bot['clear'] or report['reconciliation']['victoryCoverageComplete'] is True)
    # All generated GUIDs are replaced too: no private-derived run identity is exported.
    guid = re.compile(r"\b[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}\b")
    encoded = json.dumps(report, allow_nan=False)
    run_aliases = {value: 'RunRef' + str(index + 1)
                   for index, value in enumerate(sorted(set(guid.findall(encoded))))}
    identity_patterns = [(re.compile(r'(?<![0-9])' + re.escape(identity) + r'(?![0-9])'), alias)
                         for identity, alias in aliases.items()]
    forbidden_key = re.compile(r'user.?id|account.?id|username|displayname|access.?token|password|secret|cookie|access.?code|private.?server', re.I)
    address = re.compile(r'https?://|rbxassetid://|[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}', re.I)

    def clean_string(value):
        assert not address.search(value), 'Unexpected external address in evidence'
        value = guid.sub(lambda match: run_aliases[match.group()], value)
        for pattern, alias in identity_patterns:
            value = pattern.sub(alias, value)
        return value

    def clean(value):
        if isinstance(value, dict):
            result = {}
            for key, item in value.items():
                assert not forbidden_key.search(key), 'Unexpected identity/credential field: ' + key
                public_key = clean_string(key)
                assert public_key not in result, 'Sanitized key collision'
                result[public_key] = clean(item)
            return result
        if isinstance(value, list):
            return [clean(item) for item in value]
        if isinstance(value, str):
            return clean_string(value)
        assert not isinstance(value, (int, float)) or str(value) not in aliases, 'Unexpected numeric account identifier'
        return value

    protected_provenance = {key: report[key] for key in ('sourceCommit', 'botPolicyRevision')}
    report = clean(report)
    for key, expected in protected_provenance.items():
        assert report[key] == expected and report['provenance'][key] == expected, 'Aliasing would change protected provenance: ' + key
    report['privacyAudit'] = {'generatedRunIdentifiersAliased': len(run_aliases),
                              'playerAliases': len(aliases),
                              'unaliasedGuidCount': 0, 'externalAddresses': 0}
    serialized = json.dumps(report, indent=2, allow_nan=False) + '\n'
    assert not guid.search(serialized), 'Unaliased generated identifier remains'
    for pattern, _alias in identity_patterns:
        assert not pattern.search(serialized), 'Account identifier remains'
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
