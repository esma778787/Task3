import json
from pathlib import Path
p = Path('_tmp_live_schema.json')
if not p.exists():
    raise FileNotFoundError(str(p))
with p.open('r', encoding='utf-8') as f:
    data = json.load(f)

lookup = [
    'Projects','ProjectCategories','ProjectTopics','ProjectTopicMap','ProjectRequirements',
    'ProjectSources','Countries','SimulationResults','Applications','MotivationLetters',
    'AssessmentSessions','AssessmentAnswers','ErasmusProjects','DetailedErasmusProjects','Users'
]
for table in lookup:
    cols = [r for r in data['columns']['rows'] if r['TABLE_NAME'] == table]
    if not cols:
        continue
    print(f'=== {table} ({len(cols)}) ===')
    for c in cols:
        default = c['COLUMN_DEFAULT'] or ''
        print(f"{c['COLUMN_NAME']} | {c['DATA_TYPE']} | {c['IS_NULLABLE']} | {default}")
    print()
print('=== foreign keys ===')
for fk in data['foreign_keys']['rows']:
    if fk['child_table'] in lookup or fk['parent_table'] in lookup:
        print(f"{fk['child_schema']}.{fk['child_table']}.{fk['child_column']} -> {fk['parent_schema']}.{fk['parent_table']}.{fk['parent_column']}")
