import copy,json,re,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from tools.prepare_curve_report import prepare
root=Path(__file__).resolve().parents[1]
base=json.loads((root/'docs/launch/evidence/m3-final-normal-1104.json').read_text(encoding='utf-8'))
for field in ('hits','stocks','damage'):
 base['bot']['telemetry'][field]={'918273645':next(iter(base['bot']['telemetry'][field].values()))}
original=copy.deepcopy(base);report,encoded=prepare(base)
assert base==original and '918273645'not in encoded
assert report['bot']['telemetry']['damage']['Player1']==original['bot']['telemetry']['damage']['918273645']
assert report['sourceCommit']==original['sourceCommit'] and report['botPolicyRevision']==original['botPolicyRevision']
assert report['bot']['seconds']==original['bot']['seconds'] and report['bot']['choices']==original['bot']['choices']
assert report['bot']['districtResults'][0]['id'].startswith('RunRef')
assert report['bot']['districtResults'][0]['id']==report['styleObserver']['players'][0]['districts'][0]['id']
assert prepare(base)[1]==encoded
checks=7
for field in ('userId','account_id','userName','displayName','password','accessToken','cookie','reservedPrivateServerId'):
 r=copy.deepcopy(base);r['unexpected']={field:'redacted-test-value'}
 try:prepare(r);raise RuntimeError('sensitive field accepted: '+field)
 except AssertionError:checks+=1
for value in ('https://example.invalid/secret','test@example.invalid','rbxassetid://12345'):
 r=copy.deepcopy(base);r['unexpected']=value
 try:prepare(r);raise RuntimeError('address accepted')
 except AssertionError:checks+=1
r=copy.deepcopy(base);r['unexpected']={'918273645':0,'Player1':1}
try:prepare(r);raise RuntimeError('key collision accepted')
except AssertionError:checks+=1
r=copy.deepcopy(base);r['unexpected']=918273645
try:prepare(r);raise RuntimeError('numeric identity accepted')
except AssertionError:checks+=1
r=copy.deepcopy(base);r['diagnostic']='subject918273645 / aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'
q,text=prepare(r);assert q['diagnostic'].startswith('subjectPlayer1 / RunRef');checks+=1
for field in ('sourceCommit','botPolicyRevision'):
 r=copy.deepcopy(base);r['provenance'][field]='a918273645'+'b'*30
 try:prepare(r);raise RuntimeError('provenance collision accepted')
 except AssertionError:checks+=1
for field in ('hits','stocks','damage'):
 r=copy.deepcopy(base);r['bot']['telemetry'][field]['Player1']=copy.deepcopy(r['bot']['telemetry'][field]['918273645'])
 try:prepare(r);raise RuntimeError('telemetry alias collision accepted')
 except AssertionError:checks+=1
print(f'PASS: {checks} synthetic curve-export privacy and integrity cases; no gameplay evidence produced')
