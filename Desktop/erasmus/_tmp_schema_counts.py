import json
from pathlib import Path
p = Path('_tmp_live_schema.json')
if not p.exists():
    raise FileNotFoundError(str(p))
with p.open('r', encoding='utf-8') as f:
    data = json.load(f)
print('Row counts:')
for row in data['table_counts']['rows']:
    print(f"{row['table_schema']}.{row['table_name']}: {row['row_count']}")
print('\nPrimary keys:')
for row in data['primary_keys']['rows']:
    print(f"{row['TABLE_SCHEMA']}.{row['TABLE_NAME']}: {row['COLUMN_NAME']}")
print('\nIndexes sample:')
for row in data['indexes']['rows'][:20]:
    print(f"{row['table_schema']}.{row['table_name']} {row['index_name']} {row['type_desc']} unique={row['is_unique']} pk={row['is_primary_key']}")
