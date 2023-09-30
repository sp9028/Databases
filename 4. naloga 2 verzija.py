import pyodbc

c = pyodbc.connect('DSN=DOMA;UID=pb;PWD=pbvaje')
cursor = c.cursor()
insert = c.cursor()

cursor.execute("drop table if exists steviloZaposlenih")
cursor.execute("create table steviloZaposlenih(dept_no VARCHAR(10), year int, month int, no_employed int);")

leto = input("Vpiši leto: ")
mesec = input("Vpiši mesec: ")


cursor.execute("select count(emp_no) as count, dept_no, month(from_date), year(from_date) from dept_emp " +
               "where year(from_date) = ? and month(from_date) = ? " +
               "group by dept_no, month(from_date), year(from_date) order by  year(from_date), dept_no,month(from_date)",
               leto,mesec)

for i in cursor:
    insert.execute("insert into steviloZaposlenih(dept_no, year, month, no_employed) values (?,?,?,?)",
                   i[1],i[3],i[2],i[0])
insert.commit()
