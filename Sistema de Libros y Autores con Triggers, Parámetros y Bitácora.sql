-- ============================================================
-- Keneth Jara Herrera - 402600458
-- ============================================================

SET FEEDBACK ON
SET PAGESIZE 50
SET LINESIZE 150
SET TRIMSPOOL ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SPOOL &1..log

PROMPT ====Conectar con bases1===========
conn bases1/bases123@FREEPDB1

drop trigger libros_trg_bir;
drop trigger libros_trg_bur;
drop trigger autores_trg_bir;
drop trigger autores_trg_air;
drop trigger autores_trg_aur;
drop trigger autores_trg_adr;

drop procedure prc_ins_libro;
drop procedure prc_upd_libro;
drop procedure prc_ins_autor;
drop procedure prc_asocia_libro_autor;
drop procedure prc_del_autor;

drop function fun_param_valor;

drop table libros_autores cascade constraints;
drop table autores_log    cascade constraints;
drop table autores        cascade constraints;
drop table libros         cascade constraints;
drop table parametros     cascade constraints;

drop sequence sec_libros;
drop sequence sec_autores;
drop sequence sec_autores_log;
drop sequence sec_parametros;

PROMPT ==================================================
PROMPT ==== 1. Creacion de tablas
PROMPT ==================================================

create table parametros (
  id     number        not null,
  nombre varchar2(50)  not null,
  valor  varchar2(10)  not null
);

create table libros (
  id_libro          number          not null,
  titulo            varchar2(100)   not null,
  anno_publicacion  number(4),
  genero            varchar2(30),
  estado            varchar2(10)    default 'Activo'
);

create table autores (
  id_autor          number          not null,
  nombre            varchar2(80)    not null,
  nacionalidad      varchar2(40),
  fecha_nacimiento  date,
  estado            varchar2(10)    default 'Activo'
);

create table libros_autores (
  id_libro  number  not null,
  id_autor  number  not null
);

create table autores_log (
  id_log            number          not null,
  fecha_log         date,
  accion_log        varchar2(1),
  usuario_log       varchar2(30),
  id_autor          number,
  nombre_ant        varchar2(80),
  nombre_nvo        varchar2(80),
  nacionalidad_ant  varchar2(40),
  nacionalidad_nvo  varchar2(40),
  estado_ant        varchar2(10),
  estado_nvo        varchar2(10)
);

PROMPT ==================================================
PROMPT ==== 2. Llaves
PROMPT ==================================================

alter table parametros     add constraint parametros_pk      primary key (id);
alter table libros         add constraint libros_pk          primary key (id_libro);
alter table autores        add constraint autores_pk         primary key (id_autor);
alter table libros_autores add constraint libros_autores_pk  primary key (id_libro, id_autor);
alter table autores_log    add constraint autores_log_pk     primary key (id_log);

alter table libros_autores add constraint la_fk_libro
  foreign key (id_libro) references libros;
alter table libros_autores add constraint la_fk_autor
  foreign key (id_autor) references autores;

alter table libros     add constraint libros_ck_estado  check (estado in ('Activo','Inactivo'));
alter table libros     add constraint libros_ck_anno    check (anno_publicacion between 1000 and 2100);
alter table autores    add constraint autores_ck_estado check (estado in ('Activo','Inactivo'));
alter table parametros add constraint parametros_ck_val check (valor in ('S','N'));

alter table libros  add constraint libros_uk_titulo  unique (titulo);
alter table autores add constraint autores_uk_nombre unique (nombre);


PROMPT ==================================================
PROMPT ==== 3. Secuencias
PROMPT ==================================================

create sequence sec_parametros  start with 1;
create sequence sec_libros      start with 100;
create sequence sec_autores     start with 200;
create sequence sec_autores_log start with 1000;

PROMPT ==================================================
PROMPT ==== 4. inserts
PROMPT ==================================================

insert into parametros(id, nombre, valor) values (sec_parametros.nextval, 'Permite crear libros',       'S');
insert into parametros(id, nombre, valor) values (sec_parametros.nextval, 'Permite modificar libros',   'S');
insert into parametros(id, nombre, valor) values (sec_parametros.nextval, 'Permite crear autores',      'S');
insert into parametros(id, nombre, valor) values (sec_parametros.nextval, 'Activa bitacora ins autores','S');
insert into parametros(id, nombre, valor) values (sec_parametros.nextval, 'Activa bitacora upd autores','S');
insert into parametros(id, nombre, valor) values (sec_parametros.nextval, 'Activa bitacora del autores','S');
commit;

PROMPT ==== Parametros insertados
select * from parametros order by 1;

PROMPT ==================================================
PROMPT ==== 5. Funcion
PROMPT ==================================================

create or replace function fun_param_valor(PId in number)
return varchar2 is
  VValor varchar2(10);
begin
  select valor into VValor from parametros where id = PId;
  return VValor;
exception
  when no_data_found then
    return null;
  when others then
    dbms_output.put_line('Error en fun_param_valor: ' || sqlerrm);
    return null;
end fun_param_valor;
/

PROMPT ==================================================
PROMPT ==== 6. Procedimientos
PROMPT ==================================================

create or replace procedure prc_ins_libro(
  Ptitulo           in varchar2,
  Panno_publicacion in number,
  Pgenero           in varchar2,
  Pestado           in varchar2
) is
  VTitulo varchar2(100);
begin
  VTitulo := trim(lower(Ptitulo));
  if VTitulo is null then
    raise_application_error(-20001, 'El titulo del libro no puede ser nulo.');
  end if;
  insert into libros(id_libro, titulo, anno_publicacion, genero, estado)
  values (sec_libros.nextval, VTitulo, Panno_publicacion, upper(Pgenero), nvl(Pestado,'Activo'));
  commit;
  dbms_output.put_line('OK: Libro "' || VTitulo || '" insertado correctamente.');
exception
  when dup_val_on_index then
    dbms_output.put_line('Error: Ya existe un libro con ese titulo.');
  when others then
    dbms_output.put_line('Error en prc_ins_libro: ' || sqlerrm);
    rollback;
end prc_ins_libro;
/

create or replace procedure prc_upd_libro(
  Pid_libro in number,
  Ptitulo   in varchar2,
  Pgenero   in varchar2,
  Pestado   in varchar2
) is
  VCant number;
begin
  select count(*) into VCant from libros where id_libro = Pid_libro;
  if VCant = 0 then
    raise_application_error(-20002, 'No existe el libro con ID ' || Pid_libro);
  end if;
  update libros
  set    titulo  = nvl(trim(lower(Ptitulo)), titulo),
         genero  = nvl(upper(Pgenero), genero),
         estado  = nvl(Pestado, estado)
  where  id_libro = Pid_libro;
  commit;
  dbms_output.put_line('OK: Libro ID ' || Pid_libro || ' actualizado correctamente.');
exception
  when others then
    dbms_output.put_line('Error en prc_upd_libro: ' || sqlerrm);
    rollback;
end prc_upd_libro;
/

create or replace procedure prc_ins_autor(
  Pnombre           in varchar2,
  Pnacionalidad     in varchar2,
  Pfecha_nacimiento in date,
  Pestado           in varchar2
) is
  VNombre varchar2(80);
begin
  VNombre := initcap(trim(Pnombre));
  if VNombre is null then
    raise_application_error(-20003, 'El nombre del autor no puede ser nulo.');
  end if;
  if length(VNombre) < 3 then
    raise_application_error(-20004,
      'El nombre debe tener al menos 3 caracteres. Largo: ' || length(VNombre));
  end if;
  insert into autores(id_autor, nombre, nacionalidad, fecha_nacimiento, estado)
  values (sec_autores.nextval, VNombre, upper(trim(Pnacionalidad)), Pfecha_nacimiento, nvl(Pestado,'Activo'));
  commit;
  dbms_output.put_line('OK: Autor "' || VNombre || '" insertado correctamente.');
exception
  when dup_val_on_index then
    dbms_output.put_line('Error: Ya existe un autor con ese nombre.');
  when others then
    dbms_output.put_line('Error en prc_ins_autor: ' || sqlerrm);
    rollback;
end prc_ins_autor;
/

create or replace procedure prc_asocia_libro_autor(
  Pid_libro in number,
  Pid_autor in number
) is
  VCantLibro number;
  VCantAutor number;
begin
  select count(*) into VCantLibro from libros  where id_libro = Pid_libro;
  select count(*) into VCantAutor from autores where id_autor = Pid_autor;
  if VCantLibro = 0 then
    raise_application_error(-20005, 'No existe el libro con ID ' || Pid_libro);
  end if;
  if VCantAutor = 0 then
    raise_application_error(-20006, 'No existe el autor con ID ' || Pid_autor);
  end if;
  insert into libros_autores(id_libro, id_autor) values (Pid_libro, Pid_autor);
  commit;
  dbms_output.put_line('OK: Asociacion libro ' || Pid_libro || ' - autor ' || Pid_autor || ' registrada.');
exception
  when dup_val_on_index then
    dbms_output.put_line('Aviso: La relacion libro ' || Pid_libro || ' - autor ' || Pid_autor || ' ya existe.');
  when others then
    dbms_output.put_line('Error en prc_asocia_libro_autor: ' || sqlerrm);
    rollback;
end prc_asocia_libro_autor;
/

create or replace procedure prc_del_autor(Pid_autor in number) is
  VCant number;
begin
  select count(*) into VCant from autores where id_autor = Pid_autor;
  if VCant = 0 then
    raise_application_error(-20007, 'No existe el autor con ID ' || Pid_autor);
  end if;
  update autores set estado = 'Inactivo' where id_autor = Pid_autor;
  commit;
  dbms_output.put_line('OK: Autor ID ' || Pid_autor || ' marcado como Inactivo (borrado logico).');
exception
  when others then
    dbms_output.put_line('Error en prc_del_autor: ' || sqlerrm);
    rollback;
end prc_del_autor;
/

PROMPT ==================================================
PROMPT ==== 7. Triggers de control
PROMPT ==================================================

create or replace trigger libros_trg_bir
before insert on libros
for each row
begin
  if nvl(fun_param_valor(1), 'N') <> 'S' then
    raise_application_error(-20010,
      'Operacion bloqueada: el parametro "Permite crear libros" esta en N.');
  end if;
end libros_trg_bir;
/

create or replace trigger libros_trg_bur
before update on libros
for each row
begin
  if nvl(fun_param_valor(2), 'N') <> 'S' then
    raise_application_error(-20011,
      'Operacion bloqueada: el parametro "Permite modificar libros" esta en N.');
  end if;
end libros_trg_bur;
/

create or replace trigger autores_trg_bir
before insert on autores
for each row
begin
  if nvl(fun_param_valor(3), 'N') <> 'S' then
    raise_application_error(-20012,
      'Operacion bloqueada: el parametro "Permite crear autores" esta en N.');
  end if;
end autores_trg_bir;
/

PROMPT ==================================================
PROMPT ==== 8. Triggers de bitacora
PROMPT ==================================================

create or replace trigger autores_trg_air
after insert on autores
for each row
begin
  if nvl(fun_param_valor(4), 'N') = 'S' then
    insert into autores_log(id_log, fecha_log, accion_log, usuario_log,
      id_autor, nombre_ant, nombre_nvo, nacionalidad_ant, nacionalidad_nvo, estado_ant, estado_nvo)
    values (sec_autores_log.nextval, sysdate, 'I', user,
      :new.id_autor, null, :new.nombre, null, :new.nacionalidad, null, :new.estado);
  end if;
end autores_trg_air;
/

create or replace trigger autores_trg_aur
after update on autores
for each row
begin
  if nvl(fun_param_valor(5), 'N') = 'S' then
    insert into autores_log(id_log, fecha_log, accion_log, usuario_log,
      id_autor, nombre_ant, nombre_nvo, nacionalidad_ant, nacionalidad_nvo, estado_ant, estado_nvo)
    values (sec_autores_log.nextval, sysdate, 'U', user,
      :old.id_autor, :old.nombre, :new.nombre, :old.nacionalidad, :new.nacionalidad, :old.estado, :new.estado);
  end if;
end autores_trg_aur;
/

create or replace trigger autores_trg_adr
after delete on autores
for each row
begin
  if nvl(fun_param_valor(6), 'N') = 'S' then
    insert into autores_log(id_log, fecha_log, accion_log, usuario_log,
      id_autor, nombre_ant, nombre_nvo, nacionalidad_ant, nacionalidad_nvo, estado_ant, estado_nvo)
    values (sec_autores_log.nextval, sysdate, 'D', user,
      :old.id_autor, :old.nombre, null, :old.nacionalidad, null, :old.estado, null);
  end if;
end autores_trg_adr;
/

PROMPT ============================================================
PROMPT ==== 9. PRUEBAS
PROMPT ============================================================

PROMPT ==================================================
PROMPT ==== PRUEBA 1: Insercion de libros PERMITIDA
PROMPT ==================================================
execute prc_ins_libro('Cien Anos de Soledad',   1967, 'novela',     'Activo');
execute prc_ins_libro('El Principito',          1943, 'literatura', 'Activo');
execute prc_ins_libro('1984',                   1949, 'distopia',   'Activo');
execute prc_ins_libro('Don Quijote',            1605, 'novela',     'Activo');
execute prc_ins_libro('Harry Potter',           1997, 'fantasia',   'Activo');
select id_libro, titulo, anno_publicacion, genero, estado from libros order by 1;


PROMPT ==================================================
PROMPT ==== PRUEBA 2: Insercion de libros BLOQUEADA
PROMPT ==================================================
update parametros set valor = 'N' where id = 1;
commit;
execute prc_ins_libro('Libro Bloqueado', 2024, 'prueba', 'Activo');
update parametros set valor = 'S' where id = 1;
commit;


PROMPT ==================================================
PROMPT ==== PRUEBA 3: Actualizacion de libros PERMITIDA
PROMPT ==================================================
execute prc_upd_libro(100, 'Cien Anos de Soledad - Ed. Especial', 'NOVELA', 'Activo');
select id_libro, titulo, genero from libros where id_libro = 100;


PROMPT ==================================================
PROMPT ==== PRUEBA 4: Actualizacion de libros BLOQUEADA
PROMPT ==================================================
update parametros set valor = 'N' where id = 2;
commit;
execute prc_upd_libro(100, 'Titulo Bloqueado', null, null);
update parametros set valor = 'S' where id = 2;
commit;


PROMPT ==================================================
PROMPT ==== PRUEBA 5: Insercion de autores PERMITIDA
PROMPT ==================================================
execute prc_ins_autor('Gabriel Garcia Marquez',  'COLOMBIANA',  to_date('06-03-1927','dd-mm-yyyy'), 'Activo');
execute prc_ins_autor('Antoine de Saint-Exupery','FRANCESA',    to_date('29-06-1900','dd-mm-yyyy'), 'Activo');
execute prc_ins_autor('George Orwell',            'BRITANICA',  to_date('25-06-1903','dd-mm-yyyy'), 'Activo');
execute prc_ins_autor('Miguel de Cervantes',      'ESPANOLA',   to_date('29-09-1547','dd-mm-yyyy'), 'Activo');
execute prc_ins_autor('J.K. Rowling',             'BRITANICA',  to_date('31-07-1965','dd-mm-yyyy'), 'Activo');
execute prc_ins_autor('Isabel Allende',           'CHILENA',    to_date('02-08-1942','dd-mm-yyyy'), 'Activo');
select id_autor, nombre, nacionalidad, estado from autores order by 1;


PROMPT ==================================================
PROMPT ==== PRUEBA 6: Insercion de autores BLOQUEADA
PROMPT ==================================================
update parametros set valor = 'N' where id = 3;
commit;
execute prc_ins_autor('Autor Bloqueado', 'NINGUNA', null, 'Activo');
update parametros set valor = 'S' where id = 3;
commit;


PROMPT ==================================================
PROMPT ==== PRUEBA 7: Asociacion libros y autores
PROMPT ==================================================
execute prc_asocia_libro_autor(100, 200);
execute prc_asocia_libro_autor(101, 201);
execute prc_asocia_libro_autor(102, 202);
execute prc_asocia_libro_autor(103, 203);
execute prc_asocia_libro_autor(104, 204);
execute prc_asocia_libro_autor(104, 205);
execute prc_ins_libro('El Amor en los Tiempos del Colera', 1985, 'novela', 'Activo');
execute prc_asocia_libro_autor(105, 200);
execute prc_asocia_libro_autor(100, 200);
select * from libros_autores order by 1, 2;


PROMPT ==================================================
PROMPT ==== PRUEBA 8: Bitacoras de autores
PROMPT ==================================================

PROMPT ==== INSERT autor con bitacora activa
execute prc_ins_autor('Pablo Neruda', 'CHILENA', to_date('12-07-1904','dd-mm-yyyy'), 'Activo');

PROMPT ==== INSERT autor con bitacora desactivada
update parametros set valor = 'N' where id = 4;
commit;
execute prc_ins_autor('Ruben Dario', 'NICARAGUENSE', to_date('18-01-1867','dd-mm-yyyy'), 'Activo');
update parametros set valor = 'S' where id = 4;
commit;

PROMPT ==== UPDATE autor con bitacora activa
update autores set nacionalidad = 'COLOMBIANA-MEXICANA' where id_autor = 200;
commit;

PROMPT ==== UPDATE autor con bitacora desactivada
update parametros set valor = 'N' where id = 5;
commit;
update autores set estado = 'Inactivo' where id_autor = 205;
commit;
update parametros set valor = 'S' where id = 5;
commit;

PROMPT ==== DELETE autor con bitacora activa
insert into autores(id_autor, nombre, nacionalidad, estado)
values (sec_autores.nextval, 'Autor Temporal Uno', 'COSTARRICENSE', 'Activo');
commit;
delete from autores where nombre = 'Autor Temporal Uno';
commit;

PROMPT ==== DELETE autor con bitacora desactivada
insert into autores(id_autor, nombre, nacionalidad, estado)
values (sec_autores.nextval, 'Autor Temporal Dos', 'COSTARRICENSE', 'Activo');
commit;
update parametros set valor = 'N' where id = 6;
commit;
delete from autores where nombre = 'Autor Temporal Dos';
commit;
update parametros set valor = 'S' where id = 6;
commit;

PROMPT ==== Bitacora completa despues de pruebas I/U/D
select id_log,
       to_char(fecha_log,'dd-mm-yyyy hh24:mi:ss') fecha,
       accion_log  accion,
       id_autor,
       nvl(nombre_ant,'-') nombre_anterior,
       nvl(nombre_nvo,'-') nombre_nuevo,
       nvl(estado_ant,'-') estado_anterior,
       nvl(estado_nvo,'-') estado_nuevo
from   autores_log
order  by 1;


PROMPT ==================================================
PROMPT ==== PRUEBA 9: Borrado logico con prc_del_autor
PROMPT ==================================================
PROMPT ==== Antes del borrado logico
select id_autor, nombre, estado from autores where id_autor = 204;
execute prc_del_autor(204);
PROMPT ==== Despues del borrado logico (estado = Inactivo)
select id_autor, nombre, estado from autores where id_autor = 204;


PROMPT ==================================================
PROMPT ==== PRUEBA 10: Demostracion de ROLLBACK
PROMPT ==================================================
select id_libro, titulo from libros where id_libro = 101;
update libros set titulo = 'Titulo Que Sera Revertido' where id_libro = 101;
PROMPT ==== Luego del UPDATE sin commit
select id_libro, titulo from libros where id_libro = 101;
rollback;
PROMPT ==== Luego del ROLLBACK
select id_libro, titulo from libros where id_libro = 101;


PROMPT ============================================================
PROMPT ==== CONSULTAS FINALES PARA REVISION
PROMPT ============================================================

PROMPT ==== Tabla libros
column titulo format A45
select id_libro, titulo, anno_publicacion, genero, estado from libros order by 1;

PROMPT ==== Tabla autores
column nombre       format A30
column nacionalidad format A20
select id_autor, nombre, nacionalidad, estado from autores order by 1;

PROMPT ==== Tabla libros_autores
select * from libros_autores order by 1, 2;

PROMPT ==== Libros con autores (inner join explicito)
column titulo        format A38
column nombre_autor  format A25
select l.id_libro,
       upper(l.titulo)    titulo,
       initcap(a.nombre)  nombre_autor,
       a.nacionalidad
from   libros l
inner join libros_autores la on la.id_libro = l.id_libro
inner join autores a         on a.id_autor  = la.id_autor
order  by l.titulo, a.nombre;

PROMPT ==== Bitacora final de autores
column nombre_anterior format A25
column nombre_nuevo    format A25
select id_log,
       to_char(fecha_log,'dd-mm-yyyy hh24:mi:ss') fecha,
       accion_log  accion,
       upper(usuario_log) usuario,
       id_autor,
       nvl(nombre_ant,'-') nombre_anterior,
       nvl(nombre_nvo,'-') nombre_nuevo,
       nvl(estado_ant,'-') estado_anterior,
       nvl(estado_nvo,'-') estado_nuevo
from   autores_log
order  by 1;

PROMPT ==== Funciones de texto: LENGTH SUBSTR UPPER LOWER NVL INITCAP
select id_autor,
       nombre,
       length(nombre)        largo,
       substr(nombre,1,5)    primeras_5,
       upper(nombre)         mayuscula,
       lower(nombre)         minuscula,
       nvl(nacionalidad,'N/A') nac_nvl
from   autores order by 1;

PROMPT ==== Objetos creados en la base de datos
column object_type format A18
column object_name format A30
select object_type, object_name from user_objects order by 1, 2;

PROMPT ============================================================
PROMPT ==== FIN DEL PROYECTO 2
PROMPT ============================================================

SPOOL OFF
EXIT

-- ============================================================
-- Keneth Jara Herrera - 402600458
-- ============================================================