"""Collect UI strings from the Flutter app and pre-fill translations from the site."""
import glob
import json
import os
import re

out_dir = os.path.dirname(os.path.abspath(__file__))
app = os.path.abspath(os.path.join(out_dir, '..', '..'))
site = os.path.join(app, '..', 'ignition', 'public', 'locales')  # the website repo

lit = re.compile(r"""(?<![A-Za-z0-9_])r?(['"])((?:\\.|(?!\1).)*)\1""")
skip_files = ('lib/api/', 'lib/models/', 'lib/data/', 'lib/i18n/', 'lib/config.dart')
code_like = re.compile(r'^[a-z_][a-zA-Z0-9_]*$|^[A-Z_]+$|^(package|dart|assets|http|uploads|mutation|query)[:/ ]|\.dart$|\.png$|^#|^\$')

strings = {}
for f in glob.glob(os.path.join(app, 'lib', '**', '*.dart'), recursive=True):
    rel = os.path.relpath(f, app).replace(os.sep, '/')
    if rel.startswith(skip_files):
        continue
    for line in open(f, encoding='utf-8'):
        t = line.strip()
        if t.startswith(('import ', '//', '///')):
            continue
        for m in lit.finditer(line):
            s = m.group(2)
            if '${' in s or len(s) < 2 or not re.search(r'[A-Za-z]{2}', s):
                continue
            if code_like.search(s):
                continue
            s = s.replace("\\'", "'").replace('\\"', '"').replace('\\n', '\n')
            # $var interpolation -> numbers in templates are handled at runtime
            if re.search(r'\$[a-zA-Z_]', s):
                continue
            strings.setdefault(s, set()).add(rel)

def load(lang):
    return json.load(open(os.path.join(site, lang, 'common.json'), encoding='utf-8'))

uz, ru, en, kr = load('uz'), load('ru'), load('en'), load('kr')
by_uz = {}
for k, v in uz.items():
    by_uz.setdefault(v.strip(), k)

rows = []
for s in sorted(strings):
    key = by_uz.get(s.strip())
    rows.append({
        'uz': s,
        'ru': ru.get(key) if key else None,
        'en': (en.get(key) or key) if key else None,
        'kr': kr.get(key) if key else None,
        'files': sorted(strings[s]),
    })
json.dump(rows, open(os.path.join(out_dir, 'ui_strings.json'), 'w', encoding='utf-8'),
          ensure_ascii=False, indent=1)
print('strings', len(rows), 'matched from site', sum(1 for r in rows if r['ru']))
