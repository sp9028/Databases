-- 1. Zapišite SQL skripto, ki ustvari tabeli dept_emp in salaries. Tabeli naj imata določene tudi primarne in tuje ključe ter
-- omejitev, da polje to_date ne more biti manjše od polja from_date, pri čemer je polje to_date lahko tudi prazno.

create table dept_emp
(emp_no INTEGER(11) not null,
dept_no VARCHAR(4) not null,
from_date date not null,
to_date date,
primary key(emp_no, dept_no),
foreign key(dept_no) references departments(dept_no),
foreign key(emp_no) references employees(emp_no),
constraint to_date check (to_date>from_date)
);

create table salaries
(emp_no INTEGER(11) not null,
salary INTEGER(11) not null,
from_date date not null,
to_date date,
primary key(from_date, emp_no),
foreign key(emp_no) references employees(emp_no),
constraint to_date check (to_date > from_date)
);

-- 1. Obstoječa baza rešuje nezaključene časovne intervale na svoj način. Napišite kako in komentirajte zakaj je tak način
-- smiseln za uporabo. Kakšna bi bila alternativa?

-- V SQL velja pravilo da morajo biti datumi med vrednostima 1/1/1753 in 1/1/9999
-- Obstoječa baza rešuje nezaključene intervale tako da je nastavljena največja vrednosti to_date ki je 1/1/9999 drugače pride do date
-- overflow in se vrednost ne more več shraniti. Alternativa je da take datume spremenimo v vrednost NULL in jo ali nastavimo datum z uporabo CASE.

SELECT MAX(to_date) FROM salaries;
SELECT MIN(from_date) FROM salaries;

-- 2. Naredite pogled (CREATE VIEW) x_view, ki bo iz tabelemployees, salariesin titles naredil denormalizacijo in bo
-- prikazal vse podatke v enem pogledu tako, da se pri ponovni normalizacji ne izgubi ali podvoji noben podatek.
-- Pazite na imena stolpcev.

-- 2. S pomočjo SQL poizvedbe naredite pogled x_reverse_title, ki iz pogleda x_viewprikaže originalne podatke iz
-- tabele titles. Z uporabo CTE tudi preverite, če x_reverse_title in titles vsebujeta enake vrstice. (10%)

-- 2. *S pomočjo ustreznih DDL ukazov ustvarite tabelo top3(dept_no, SteviloZaposlenih), ki hrani zgornjih 10
-- oddelkov z največ zaposlenimi. Dodajte bazne prožilce tako, da se bo lista posodabljala vsakič, ko se spremeni
-- število zaposlenih.(10%)

-- 3. a) Katerih 10 zaposlenih je dobilo največje izplačilo. Izpis uredite po priimku in imenu.
SELECT e.emp_no, e.first_name, e.last_name, MAX(s.salary) AS sestevek FROM employees e, salaries s
WHERE s.emp_no = e.emp_no
GROUP BY s.emp_no
ORDER BY sestevek DESC, e.last_name, e.first_name 
LIMIT 10;

-- b) Kakšna je povprečna starost zaposlenih na dan 1.1.2000.

select round(avg(abs(year(birth_date) - 2000))) from employees;

-- c) Izpišite imena tistih, ki so bili dlje vodja, kot navadni zaposleni, urejeno naraščajoče po priimkih.

SELECT first_name
FROM employees e
JOIN dept_emp ON e.emp_no = dept_emp.emp_no
JOIN departments d ON dept_emp.dept_no = d.dept_no
JOIN dept_manager ON d.dept_no = dept_manager.dept_no
WHERE YEAR(dept_manager.to_date)-YEAR(dept_manager.from_date) > YEAR(dept_emp.to_date)-YEAR(dept_emp.from_date)
ORDER BY last_name ASC;

-- d) *Izpišite imena in priimke zaposlenih, katerih imena se začnejo na dva zaporedna samoglasnika, priimki pa
-- vsebujejo dva zaporedna samoglasnika kjerkoli in se ne končajo na samoglasnik.

select first_name, last_name 
from employees 
where first_name regexp '^[AEIOUaeiou]{2}' and
last_name regexp '[AEIOUaeiou]{2}' and
last_name regexp '[^AEIOUaeiou]$';

-- e) Med katerimi leti obstajajo podatki za plače v bazi? Napišite eno poizvedbo, ki vam poda odgovor.

select YEAR(min(from_date)), YEAR(max(to_date)) from salaries;

-- f) Oceniti želimo število zaposlenih na dan 1.1.2000. Ker je datum zaposlitve pri nekaterih zaposlenih odprt (do
-- 1.1.9999) predpostavimo, da so vsi zaposleni do svojega 60 leta starosti, potem pa grejo v pokoj.

select count(first_name) from employees
where (2000 - year(birth_date)) < 60;


-- g) Napišite shranjen podprogram, ki za poljubno leto in mesec (parametra leto in mesec) izpiše zaposlene z
-- okroglo obletnico od časa zaposlitve (npr. 10, 20, 30… let) in so tega leta in meseca pri podjetju še vedno
-- zaposleni.

delimiter $
create procedure izpis
(in leto int, in mesec int)
begin
select first_name, last_name from employees
where year(hire_date) < leto and
(month(hire_date) - mesec) = 0 and 
(year(hire_date) - leto) mod 10 = 0;
end;
$

-- h) Kateri oddelki imajo zaposlenih nadpovprečno število žensk?

select dept_name from employees
join dept_emp on employees.emp_no = dept_emp.emp_no
join departments on dept_emp.dept_no = departments.dept_no
where employees.gender = 'F'
group by dept_emp.dept_no 
having count(last_name) > ( select avg(x.count) 
							from
							(select count(first_name) as count, dept_name from employees
								join dept_emp on employees.emp_no = dept_emp.emp_no
								join departments on dept_emp.dept_no = departments.dept_no
								where employees.gender = 'F'
								group by dept_emp.dept_no
								) as x );


-- i) Izpišite imena zaposlenih, ki so delali natanko na enemoddelku in niso bili vodje (managers). Izpis uredite po
-- naraščajočistarostizaposlenega in imenu.

select first_name from employees 
join dept_emp on employees.emp_no = dept_emp.emp_no
group by employees.emp_no 
having count(dept_emp.dept_no) = 1 and 
employees.emp_no not in (select emp_no from dept_manager);

set profiling=1;
show profiles;

-- j) Pospešite izvajanje poizvedbe iz naloge h) s kreiranjem ustreznih indeksov (CREATE INDEX). Svoje predloge
-- dokumentirajte s faktorji pohitritve in jih utemeljite (za čas lahko uporabite ukaz set profiling=1; vaš sql;
-- show profiles;).


select sum(x.count) from
(
select count(emp_no) as count, dept_no, month(from_date), year(from_date) from dept_emp
group by dept_no, month(from_date), year(from_date) order by  year(from_date), dept_no,month(from_date)
) as x;

drop table steviloZaposleni;

select count(emp_no) as count, dept_no, month(from_date), year(from_date) from dept_emp
where year(from_date) = 1996 and month(from_date) = 1
group by dept_no, month(from_date), year(from_date) order by  year(from_date), dept_no,month(from_date)

select * from steviloZaposlenih;
