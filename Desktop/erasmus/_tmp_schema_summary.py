import json
from pathlib import Path
p = Path('_tmp_live_schema.json')
if not p.exists():
    raise FileNotFoundError(str(p))
with p.open('r', encoding='utf-8') as f:
    data = json.load(f)
print('tables', len(data['tables']['rows']))
print('columns', len(data['columns']['rows']))
print('fks', len(data['foreign_keys']['rows']))
print('indexes', len(data['indexes']['rows']))
print('uniq', len(data['unique_constraints']['rows']))
print('defaults', len(data['default_constraints']['rows']))
print()
print('TABLES:')
print(', '.join([r['TABLE_NAME'] for r in data['tables']['rows']]))
print()
for table in ['Projects','ProjectCategories','SimulationResults','Applications','MotivationLetters','ProjectTopics','ProjectRequirements','ProjectSources','Countries']:
    cols = [r for r in data['columns']['rows'] if r['TABLE_NAME'] == table]
    if cols:
        print(f'=== {table} ({len(cols)}) ===')
        for c in cols:
            default = c['COLUMN_DEFAULT'] or ''
            print(f"{c['COLUMN_NAME']} | {c['DATA_TYPE']} | {c['IS_NULLABLE']} | {default}")
        print()
print('=== foreign keys ===')
for fk in data['foreign_keys']['rows']:
    print(f"{fk['child_schema']}.{fk['child_table']}.{fk['child_column']} -> {fk['parent_schema']}.{fk['parent_table']}.{fk['parent_column']}")
