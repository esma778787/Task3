import json, os, sys
sys.path.insert(0, os.getcwd())
from database import get_mssql_connection

queries = {
    'tables': "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_SCHEMA, TABLE_NAME;",
    'columns': "SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE, IS_NULLABLE, COLUMN_DEFAULT, ORDINAL_POSITION FROM INFORMATION_SCHEMA.COLUMNS ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;",
    'primary_keys': "SELECT tc.TABLE_SCHEMA, tc.TABLE_NAME, kc.COLUMN_NAME, kc.ORDINAL_POSITION FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kc ON tc.CONSTRAINT_NAME = kc.CONSTRAINT_NAME AND tc.TABLE_SCHEMA = kc.TABLE_SCHEMA AND tc.TABLE_NAME = kc.TABLE_NAME WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY' ORDER BY tc.TABLE_SCHEMA, tc.TABLE_NAME, kc.ORDINAL_POSITION;",
    'foreign_keys': "SELECT fk.name AS foreign_key_name, OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema, OBJECT_NAME(fk.parent_object_id) AS child_table, COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS child_column, OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema, OBJECT_NAME(fk.referenced_object_id) AS parent_table, COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS parent_column FROM sys.foreign_keys fk INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id ORDER BY child_schema, child_table, foreign_key_name, fkc.constraint_column_id;",
    'identity_columns': "SELECT OBJECT_SCHEMA_NAME(ic.object_id) AS table_schema, OBJECT_NAME(ic.object_id) AS table_name, COL_NAME(ic.object_id, ic.column_id) AS column_name, CAST(ic.seed_value AS NVARCHAR(100)) AS seed_value, CAST(ic.increment_value AS NVARCHAR(100)) AS increment_value FROM sys.identity_columns ic ORDER BY OBJECT_SCHEMA_NAME(ic.object_id), OBJECT_NAME(ic.object_id), COL_NAME(ic.object_id, ic.column_id);",
    'indexes': "SELECT OBJECT_SCHEMA_NAME(i.object_id) AS table_schema, OBJECT_NAME(i.object_id) AS table_name, i.name AS index_name, i.is_unique, i.is_primary_key, i.type_desc FROM sys.indexes i WHERE i.object_id IN (SELECT object_id FROM sys.tables) ORDER BY OBJECT_SCHEMA_NAME(i.object_id), OBJECT_NAME(i.object_id), i.name;",
    'unique_constraints': "SELECT tc.TABLE_SCHEMA, tc.TABLE_NAME, tc.CONSTRAINT_NAME, kc.COLUMN_NAME, kc.ORDINAL_POSITION FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kc ON tc.CONSTRAINT_NAME = kc.CONSTRAINT_NAME AND tc.TABLE_SCHEMA = kc.TABLE_SCHEMA AND tc.TABLE_NAME = kc.TABLE_NAME WHERE tc.CONSTRAINT_TYPE='UNIQUE' ORDER BY tc.TABLE_SCHEMA, tc.TABLE_NAME, tc.CONSTRAINT_NAME, kc.ORDINAL_POSITION;",
    'default_constraints': "SELECT OBJECT_SCHEMA_NAME(dc.parent_object_id) AS table_schema, OBJECT_NAME(dc.parent_object_id) AS table_name, c.name AS column_name, dc.name AS default_constraint_name, CAST(dc.definition AS NVARCHAR(MAX)) AS definition FROM sys.default_constraints dc INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id ORDER BY OBJECT_SCHEMA_NAME(dc.parent_object_id), OBJECT_NAME(dc.parent_object_id), c.name;",
    'table_counts': "SELECT OBJECT_SCHEMA_NAME(t.object_id) AS table_schema, t.name AS table_name, SUM(p.rows) AS row_count FROM sys.tables t JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1) GROUP BY OBJECT_SCHEMA_NAME(t.object_id), t.name ORDER BY OBJECT_SCHEMA_NAME(t.object_id), t.name;"
}

try:
    conn = get_mssql_connection()
    cur = conn.cursor()
    results = {}
    for name, sql in queries.items():
        cur.execute(sql)
        cols = [c[0] for c in cur.description]
        rows = [dict(zip(cols, row)) for row in cur.fetchall()]
        results[name] = {'sql': sql, 'count': len(rows), 'rows': rows}
    cur.close()
    conn.close()
    with open('_tmp_live_schema.json', 'w', encoding='utf-8') as fp:
        json.dump(results, fp, indent=2, ensure_ascii=False)
    print('Bağlantı başarılı')
    print('Tablo sayısı:', results['tables']['count'])
    print('Kolon sayısı:', results['columns']['count'])
    print('Primary key sayısı:', results['primary_keys']['count'])
    print('Foreign key sayısı:', results['foreign_keys']['count'])
    print('Index sayısı:', results['indexes']['count'])
    print('Unique constraint sayısı:', results['unique_constraints']['count'])
    print('Default constraint sayısı:', results['default_constraints']['count'])
    print('Tablo kayıt sayısı:', len(results['table_counts']['rows']))
except Exception as e:
    import traceback
    traceback.print_exc()
    raise
