# Sistema de Libros y Autores con Triggers, Parámetros y Bitácora (Oracle PL/SQL)

Script SQL*Plus que modela un esquema de **Libros y Autores** en Oracle, con funciones, procedimientos y **triggers** que controlan qué operaciones están permitidas mediante una tabla de **parámetros configurables**, además de una **bitácora de auditoría** automática sobre los autores.

## 📋 Modelo de datos

| Tabla | Descripción |
|---|---|
| `parametros` | Interruptores `S`/`N` que activan o desactivan operaciones del sistema (crear/modificar libros, crear autores, bitácora de inserción/actualización/eliminación de autores). |
| `libros` | Catálogo de libros: título (único), año de publicación, género y estado (`Activo`/`Inactivo`). |
| `autores` | Catálogo de autores: nombre (único), nacionalidad, fecha de nacimiento y estado. |
| `libros_autores` | Tabla intermedia que asocia libros con sus autores (relación muchos a muchos). |
| `autores_log` | Bitácora de auditoría: registra cada inserción, actualización o eliminación sobre `autores`, guardando los valores anteriores y nuevos de nombre, nacionalidad y estado. |

## ⚙️ Función

- **`fun_param_valor(PId)`** — devuelve el valor (`S`/`N`) de un parámetro dado su id; se usa internamente en los triggers para decidir si una operación está permitida.

## 🧩 Procedimientos

| Procedimiento | Descripción |
|---|---|
| `prc_ins_libro(titulo, anno, genero, estado)` | Inserta un libro nuevo, validando que el título no sea nulo. |
| `prc_upd_libro(id_libro, titulo, genero, estado)` | Actualiza un libro existente; valida que exista y solo actualiza los campos no nulos (`nvl`). |
| `prc_ins_autor(nombre, nacionalidad, fecha_nacimiento, estado)` | Inserta un autor nuevo, validando nombre no nulo y con al menos 3 caracteres. |
| `prc_asocia_libro_autor(id_libro, id_autor)` | Crea la relación entre un libro y un autor, validando que ambos existan. |
| `prc_del_autor(id_autor)` | Realiza un **borrado lógico** del autor (cambia su estado a `Inactivo` en vez de eliminarlo físicamente). |

## 🔒 Triggers de control (parametrizables)

Antes de insertar o actualizar, cada trigger consulta `fun_param_valor` y bloquea la operación con `raise_application_error` si el parámetro correspondiente está en `N`:

- `libros_trg_bir` — controla si se permite **crear** libros.
- `libros_trg_bur` — controla si se permite **modificar** libros.
- `autores_trg_bir` — controla si se permite **crear** autores.

## 🧾 Triggers de bitácora (auditoría de autores)

Registran automáticamente en `autores_log` cada operación sobre `autores`, también condicionados por un parámetro que permite activarlos/desactivarlos:

- `autores_trg_air` — después de **insertar** un autor.
- `autores_trg_aur` — después de **actualizar** un autor.
- `autores_trg_adr` — después de **eliminar físicamente** un autor.

## 🧪 Pruebas incluidas

El script incluye una batería de pruebas que demuestra el comportamiento completo del sistema:

1. Inserción y actualización de libros permitida y bloqueada (alternando los parámetros).
2. Inserción de autores permitida y bloqueada.
3. Asociación de libros con autores, incluyendo el caso de relación duplicada.
4. Bitácora de autores con inserción, actualización y eliminación, tanto con la bitácora activa como desactivada.
5. Borrado lógico de un autor mediante `prc_del_autor`.
6. Demostración de `ROLLBACK` sobre un `UPDATE` sin confirmar.
7. Consultas finales de revisión: listados de libros y autores, join de libros con sus autores, bitácora completa, funciones de texto (`LENGTH`, `SUBSTR`, `UPPER`, `LOWER`, `NVL`, `INITCAP`) y listado de todos los objetos creados en el esquema (`user_objects`).

## 🛠️ Tecnología

- **Oracle Database** (probado contra un contenedor `FREEPDB1`)
- **SQL*Plus** / PL/SQL

## 🚀 Cómo ejecutarlo

1. Conéctate a tu instancia de Oracle (el script ya incluye la conexión de ejemplo, ajústala a tu usuario):

   ```sql
   conn bases1/bases123@FREEPDB1
   ```

2. Ejecuta el script completo desde SQL*Plus, pasando un nombre para el archivo de log de la sesión:

   ```sql
   SQL> @nombre_del_script.sql nombre_log
   ```

   (El script usa `SPOOL &1..log`, por lo que el primer parámetro pasado define el nombre del archivo `.log` generado.)

3. El script deja `SERVEROUTPUT` activado, por lo que los mensajes de `dbms_output.put_line` de los procedimientos y triggers se muestran automáticamente en consola.

> ⚠️ El script inicia eliminando (`drop`) todos los triggers, procedimientos, función, tablas y secuencias si ya existen, por lo que **recreará desde cero** el esquema de Libros y Autores en la base donde se ejecute.

## 👤 Autor

Keneth Jara Herrera

## 📄 Licencia

Trabajo académico desarrollado con fines educativos.
