import pyodbc

c = pyodbc.connect('DSN=DOMA;UID=pb;PWD=pbvaje')
cursor = c.cursor()
insert = c.cursor()

cursor.execute("drop table if exists steviloZaposlenih")

cursor.execute("create table steviloZaposlenih(dept_no VARCHAR(10), year int, month int, no_employed int);")

minleto = cursor.execute("select year(min(from_date)) from dept_emp").fetchval()

for leto in range(minleto, 2003):
    for mesec in range(1, 13):
        cursor.execute("select dept_no, count(*) from dept_emp where ((year(from_date) = ? and month(from_date) <= ?) "
                       "or (year(from_date) < ?)) and ((year(to_date) = ? and month(to_date) >= ?) "
                       "or (year(to_date) > ?)) group by dept_no",leto,mesec,leto,leto,mesec,leto)

        for row in cursor.fetchall():
            sql = "insert into steviloZaposlenih (dept_no, year, month, no_employed) VALUES (?, ?, ?, ?)"
            values = (row[0], leto, mesec, row[1])
            cursor.execute(sql, values)
            cursor.commit()
cursor.close()





