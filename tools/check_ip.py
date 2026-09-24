"""Launch gate: inspect production source, tests and public notes without scanning history."""
from pathlib import Path
import re,sys
root=Path(__file__).resolve().parents[1]
pattern=re.compile(r'naruto|luffy|tanjiro|one piece|demon slayer|jujutsu|shibuya|straw ?hat|hokage|nichirin|haori|gomu|1453909835|1453912288|943796917|5063791566|5063791598|3657762884|3828742380|3828765577',re.I)
files=[root/'README.md',root/'default.project.json',root/'hub.project.json']
for folder in ('src','docs','tests'):
    files.extend((root/folder).rglob('*'))
hits=[];checked=0
for p in files:
    if not p.is_file() or p.is_relative_to(root/'docs/launch'):continue
    if p.suffix.lower() not in {'.lua','.md','.json','.txt','.toml','.yaml','.yml','.py','.project'}:continue
    checked+=1
    text=p.read_text(encoding='utf-8-sig')
    for n,line in enumerate(text.splitlines(),1):
        if pattern.search(line):hits.append(f'{p.relative_to(root)}:{n}: {line[:180]}')
print('\n'.join(hits) if hits else f'PASS: {checked} source/test/doc files; zero prohibited identities or retired asset IDs')
sys.exit(bool(hits))
