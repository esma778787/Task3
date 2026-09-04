import socket
import pyodbc

instances = [
    '.',
    '.\\SQLEXPRESS',
    '.\\SQL2022',
    '.\\SQLSIM',
    'localhost',
    'localhost\\SQLEXPRESS',
    'localhost\\SQL2022',
    'localhost\\SQLSIM',
    socket.gethostname(),
    socket.gethostname() + '\\SQLEXPRESS',
    socket.gethostname() + '\\SQL2022',
    socket.gethostname() + '\\SQLSIM',
]

driver = 'ODBC Driver 17 for SQL Server'
print('DRIVER', driver)

for inst in instances:
    try:
        print('---', inst)
        conn = pyodbc.connect(f'DRIVER={{{driver}}};SERVER={inst};DATABASE=master;Trusted_Connection=yes;', timeout=5)
        cur = conn.cursor()
        cur.execute("SELECT name FROM sys.databases WHERE name='erasmusdb';")
        rows = cur.fetchall()
        print('FOUND', rows)
        conn.close()
    except Exception as e:
        print('ERR', inst, type(e).__name__, e)
