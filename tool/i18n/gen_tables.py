import json
import os
import re
import sys

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from tr_manual import TR  # noqa: E402

rows = json.load(open(os.path.join(here, 'ui_strings.json'), encoding='utf-8'))
code_like = re.compile(r'^(&|<|Poppins|support@|Harley-Davidson|BMW|Ducati|Honda|Yamaha|Suzuki|Kawasaki|MOTOPRESTO$)')

tables = {'ru': {}, 'en': {}, 'kr': {}}
missing = []
for r in rows:
    uz = r['uz'].replace('\\$', '$')
    if code_like.search(uz):
        continue
    manual = TR.get(uz)
    for i, lang in enumerate(('ru', 'en', 'kr')):
        value = manual[i] if manual else r.get(lang)
        if value:
            tables[lang][uz] = value.replace('\\$', '$')
        elif lang == 'ru':
            missing.append(uz)
# Hand-written entries win, including templates and strings that the code
# builds from several adjacent literals.
for uz, vals in TR.items():
    for i, lang in enumerate(('ru', 'en', 'kr')):
        tables[lang][uz] = vals[i]


def dart(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').replace('\n', '\\n') + "'"


names = {'ru': ('ru', 'Ru'), 'en': ('en', 'En'), 'kr': ('ko', 'Ko')}
app = os.path.abspath(os.path.join(here, '..', '..', 'lib', 'i18n'))
for lang, table in tables.items():
    file, name = names[lang]
    lines = [f'// Generated: Uzbek UI text -> {lang}. Site translations (ignition/public/locales)',
             '// plus hand-written ones; edit tool/i18n/tr_manual.py and regenerate.',
             '', f'const strings{name} = <String, String>{{']
    for k in sorted(table):
        lines.append(f'  {dart(k)}: {dart(table[k])},')
    lines.append('};')
    open(os.path.join(app, f'strings_{file}.dart'), 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print(lang, len(table))
print('missing', len(missing))
for m in missing:
    print('  ', repr(m))
