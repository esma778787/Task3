import pyodbc

driver = 'ODBC Driver 17 for SQL Server'
server = '.\\SQL2022'
print('SERVER', server)
conn = pyodbc.connect(f'DRIVER={{{driver}}};SERVER={server};DATABASE=erasmusdb;Trusted_Connection=yes;', timeout=5)
cur = conn.cursor()
queries = [
    "SELECT OBJECT_ID('dbo.Projects') AS ProjectsTableId;",
    'SELECT COUNT(*) AS ProjectCount FROM dbo.Projects;',
    'SELECT TOP 5 * FROM dbo.Projects;'
]
for q in queries:
    print('--- QUERY:', q)
    try:
        cur.execute(q)
        rows = cur.fetchall()
        for row in rows:
            print(row)
    except Exception as e:
        print('ERR', type(e).__name__, e)
conn.close()
