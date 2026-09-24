"""Prepare public QA evidence: retain metrics, replace account identifiers with run-local labels."""
import argparse
import json
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('reports', nargs='+',type=Path)
args=parser.parse_args()
root=Path(__file__).resolve().parents[1]
private=root/'build/private-qa'
private.mkdir(parents=True,exist_ok=True)
for path in args.reports:
    original=path.read_text(encoding='utf-8-sig')
    data=json.loads(original)
    telemetry=data.get('telemetry') or {}
    identifiers=sorted({key for field in ('hits','stocks','damage') for key in telemetry.get(field,{}) if key.lstrip('-').isdigit()})
    labels={key:f'Player{index+1}' for index,key in enumerate(identifiers)}
    if identifiers:
        backup=private/path.name
        if not backup.exists(): backup.write_text(original,encoding='utf-8')
        for field in ('hits','stocks','damage'):
            if isinstance(telemetry.get(field),dict):telemetry[field]={labels.get(key,key):value for key,value in telemetry[field].items()}
    data['privacy']='Account identifiers replaced with run-local Player labels; raw originals remain ignored locally.'
    serialized=json.dumps(data,indent=2)+'\n'
    for identifier in identifiers:
        assert '"'+identifier+'"' not in serialized,'Identifier remains in public report'
    path.write_text(serialized,encoding='utf-8')
    print(path.name+': anonymized public evidence, measurements unchanged')
