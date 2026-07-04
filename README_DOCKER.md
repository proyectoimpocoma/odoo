# Desarrollo Odoo con Docker

Este workspace puede ejecutarse con Docker Compose usando la imagen oficial de
Odoo 19, Postgres 16 y los modulos locales montados como addons externos.

## Estructura usada

```text
/Users/angel/Documents/Projects/odoo
├── Dockerfile.odoo
├── docker-compose.yml
├── config/
│   └── odoo.docker.conf
└── modules/
    ├── risk_module/
    └── theme_impocoma/
```

Los modulos custom viven en `modules/` y se montan dentro del contenedor en
`/mnt/extra-addons`.

## Servicios

`docker-compose.yml` levanta dos servicios:

- `db`: Postgres 16, base `mi_empresa`, usuario `odoo`, password `odoo`.
- `odoo`: imagen derivada de `odoo:19.0`, con `msal` y `requests` instalados.

Se usa Postgres 16 porque es una version moderna, estable y conservadora para
desarrollo Odoo. PostgreSQL 18 es la ultima version estable actual, con mejoras
como async I/O, skip scans y `uuidv7()`, pero para este proyecto no aporta una
ventaja clara frente al riesgo de compatibilidad y migracion.

No uses PostgreSQL 19 Beta para este entorno.

## Archivos principales

`Dockerfile.odoo` extiende la imagen oficial:

```dockerfile
FROM odoo:19.0

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3-pip \
    && pip3 install --break-system-packages --no-cache-dir msal requests \
    && rm -rf /var/lib/apt/lists/*

USER odoo
```

`config/odoo.docker.conf` contiene rutas internas del contenedor:

```ini
[options]
admin_passwd = admin
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons
db_host = db
db_port = 5432
db_user = odoo
db_password = odoo
db_name = mi_empresa
data_dir = /var/lib/odoo
http_interface = 0.0.0.0
http_port = 8069
```

No reutilices `config/odoo.config` dentro de Docker: ese archivo tiene rutas
absolutas del Mac y `db_host = localhost`, que no apuntan al servicio `db` de
Compose.

## Levantar el entorno

Desde el root del workspace:

```bash
cd /Users/angel/Documents/Projects/odoo
docker compose up --build
```

O en segundo plano:

```bash
docker compose up --build -d
```

Luego abre:

```text
http://127.0.0.1:8069
```

## Instalar modulos por primera vez

Con los contenedores arriba:

```bash
./scripts/docker.sh install theme_impocoma,risk_module
```

## Actualizar modulos durante desarrollo

Usa este comando despues de cambios en modelos, vistas XML, seguridad, data,
assets o manifests:

```bash
./scripts/docker.sh update theme_impocoma,risk_module
```

Para actualizar solo `risk_module`:

```bash
./scripts/docker.sh update risk_module
```

## Flujo de desarrollo

Edita normalmente los archivos en macOS:

```text
modules/risk_module/
modules/theme_impocoma/
```

Docker monta esa carpeta en:

```text
/mnt/extra-addons
```

Por eso Odoo ve los modulos sin copiarlos dentro de la imagen.

Regla practica:

- Cambios Python simples: reinicia `odoo`.
- Cambios XML, modelos, security, data o assets: ejecuta `-u <modulo>`.
- Cambios en dependencias Python: modifica `Dockerfile.odoo` y reconstruye.

## Comandos utiles

Tambien hay un script de ayuda para no recordar todos los comandos:

```bash
./scripts/docker.sh help
```

En PowerShell hay entradas separadas para macOS y Windows:

```powershell
pwsh ./scripts/docker-mac.ps1 help
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docker-windows.ps1 help
```

Primera ejecucion:

```bash
./scripts/docker.sh init
```

En Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docker-windows.ps1 init
```

Uso diario recomendado:

```bash
./scripts/docker.sh up
./scripts/docker.sh update risk_module
./scripts/docker.sh logs
./scripts/docker.sh restart
```

El mismo flujo en PowerShell para macOS:

```powershell
pwsh ./scripts/docker-mac.ps1 up
pwsh ./scripts/docker-mac.ps1 update risk_module
pwsh ./scripts/docker-mac.ps1 logs
pwsh ./scripts/docker-mac.ps1 restart
```

El mismo flujo en PowerShell para Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\docker-windows.ps1 up
powershell -ExecutionPolicy Bypass -File .\scripts\docker-windows.ps1 update risk_module
powershell -ExecutionPolicy Bypass -File .\scripts\docker-windows.ps1 logs
powershell -ExecutionPolicy Bypass -File .\scripts\docker-windows.ps1 restart
```

Los comandos disponibles son los mismos en `docker.sh`, `docker-mac.ps1` y
`docker-windows.ps1`: `config`, `build`, `rebuild`, `up`, `up-logs`, `down`,
`stop`, `restart`, `logs`, `ps`, `shell`, `db`, `db-query`, `install`,
`update`, `update-all`, `module-status`, `backup`, `restore` y `reset`.

Instalar modulos:

```bash
./scripts/docker.sh install theme_impocoma,risk_module
```

Actualizar los modulos principales:

```bash
./scripts/docker.sh update-all
```

Forzar `theme_impocoma` como tema activo del website:

```bash
./scripts/docker.sh apply-theme
```

Backup y restore:

```bash
./scripts/docker.sh backup
./scripts/docker.sh restore backups/mi_empresa_YYYYmmdd_HHMMSS.sql
```

El comando destructivo pide confirmacion escribiendo el nombre de la base:

```bash
./scripts/docker.sh reset
```

Validar que Compose puede leer la configuracion:

```bash
docker compose config
```

Construir la imagen de Odoo sin levantar servicios:

```bash
docker compose build odoo
```

Construir sin cache, util si cambias dependencias en `Dockerfile.odoo`:

```bash
docker compose build --no-cache odoo
```

Levantar todo en primer plano:

```bash
docker compose up --build
```

Levantar todo en segundo plano:

```bash
docker compose up --build -d
```

Levantar solo la base de datos:

```bash
docker compose up -d db
```

Levantar solo Odoo, asumiendo que `db` ya esta arriba:

```bash
docker compose up -d odoo
```

Ver logs:

```bash
docker compose logs -f odoo
docker compose logs -f db
```

Ver las ultimas lineas de logs:

```bash
docker compose logs --tail=100 odoo
docker compose logs --tail=100 db
```

Entrar al contenedor de Odoo:

```bash
docker compose exec odoo bash
```

Entrar a Postgres:

```bash
docker compose exec db psql -U odoo -d mi_empresa
```

Ejecutar una consulta rapida en Postgres:

```bash
docker compose exec db psql -U odoo -d mi_empresa \
  -c "select name, state from ir_module_module where name in ('risk_module', 'theme_impocoma');"
```

Ver estado:

```bash
docker compose ps
```

Reiniciar Odoo:

```bash
docker compose restart odoo
```

Reiniciar Postgres:

```bash
docker compose restart db
```

Detener:

```bash
docker compose stop
```

Detener solo Odoo:

```bash
docker compose stop odoo
```

Detener y eliminar contenedores, conservando volumenes:

```bash
docker compose down
```

Eliminar tambien los datos persistentes:

```bash
docker compose down -v
```

Usa `down -v` solo si quieres borrar la base y el filestore.

Ver volumenes del proyecto:

```bash
docker volume ls | grep odoo
```

Ver imagenes relacionadas:

```bash
docker image ls | grep odoo
```

Limpiar contenedores detenidos, redes sin uso e imagenes dangling:

```bash
docker system prune
```

Hacer backup de la base `mi_empresa`:

```bash
mkdir -p backups
docker compose exec -T db pg_dump -U odoo -d mi_empresa > backups/mi_empresa.sql
```

Restaurar backup en una base vacia:

```bash
docker compose exec -T db psql -U odoo -d mi_empresa < backups/mi_empresa.sql
```

Listar modulos instalados desde Odoo:

```bash
docker compose exec odoo odoo -c /etc/odoo/odoo.conf \
  shell -d mi_empresa
```

Dentro del shell de Odoo puedes ejecutar:

```python
env["ir.module.module"].search([("name", "in", ["risk_module", "theme_impocoma"])]).mapped(lambda m: (m.name, m.state))
```

## Probar PostgreSQL 18

Si quieres probar PostgreSQL 18, cambia temporalmente:

```yaml
image: postgres:18
```

Pero no reutilices el mismo volumen `postgres_data`. Una base creada con
Postgres 18 no se puede abrir de vuelta con Postgres 16.

Para probar sin tocar la base actual, usa otro volumen, por ejemplo:

```yaml
volumes:
  - postgres18_data:/var/lib/postgresql/data
```

y agrega:

```yaml
volumes:
  postgres_data:
  postgres18_data:
  odoo_web_data:
```

## Diferencia con Apple Container

Apple Container tambien puede ejecutar imagenes OCI como `odoo:19.0` y
`postgres:16`, pero no reemplaza comodamente a Docker Compose para este caso.
Con Docker Compose el stack queda definido en un solo archivo y el flujo diario
es mas simple: `docker compose up`, `exec`, logs, volumenes y red compartida.

Si se usa Apple Container, la arquitectura seria la misma:

- Postgres en un contenedor.
- Odoo en otro contenedor.
- `modules/` montado en `/mnt/extra-addons`.
- Config interna con `db_host` apuntando al contenedor de Postgres.

La diferencia principal es operacional: con Apple Container habria que ejecutar
mas comandos manuales para red, volumenes y arranque de cada contenedor.
