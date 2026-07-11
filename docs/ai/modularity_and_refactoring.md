# Modularidad y refactorización en Odoo

Guía canónica del repositorio para mantener addons pequeños, sustituibles y
migrables. Aplicar al crear módulos, extender funcionalidades o intervenir
archivos que ya concentran varias responsabilidades.

## Principios

1. Un addon representa una capacidad de negocio o técnica con un límite claro.
2. Un archivo tiene una sola razón principal para cambiar.
3. Los controladores coordinan HTTP; no implementan reglas de negocio.
4. Las integraciones externas viven detrás de servicios y addons puente.
5. Una refactorización no debe cambiar comportamiento, datos ni contratos
   públicos salvo que incluya una migración explícita.

## Presupuesto de tamaño

- Los archivos Python, JavaScript, SCSS y XML mantenidos por el proyecto deben
  tener **máximo recomendado de 400 líneas**.
- Al acercarse a 300 líneas, revisar si ya existen dos responsabilidades que
  puedan separarse.
- Un archivo que supere 400 líneas requiere una decisión consciente:
  factorizarlo en el mismo cambio o documentar temporalmente por qué no es
  seguro hacerlo todavía y crear un plan de extracción.
- El límite no se resuelve minificando, comprimiendo líneas o moviendo todo a
  helpers genéricos. Se resuelve encontrando límites de responsabilidad.
- Archivos generados, traducciones `.po`, datos importados y snapshots pueden
  exceder el límite cuando no se mantienen manualmente.

El número de líneas es una señal, no el único criterio. Un archivo menor puede
requerir separación si mezcla HTTP, ORM, proveedor externo, seguridad y UI.

Comando de revisión:

```bash
find modules/addon_name -type f \
  \( -name '*.py' -o -name '*.js' -o -name '*.scss' -o -name '*.xml' \) \
  -exec wc -l {} + | sort -nr
```

## Cuándo factorizar un archivo

Factorizar cuando aparezca al menos una de estas señales:

- contiene rutas HTTP junto con reglas de estados o escrituras complejas;
- una clase gestiona workflow, validación, formato, notificaciones e
  integración externa;
- necesita encabezados internos extensos para separar secciones no
  relacionadas;
- sus pruebas requieren preparar dominios completamente distintos;
- varios métodos repiten búsquedas, validaciones, payloads o manejo de errores;
- cambiar una pantalla obliga a tocar lógica del proveedor o del dominio;
- tiene imports de demasiadas capas (`http`, ORM, requests, reportes, correo);
- una dependencia opcional se vuelve obligatoria para todo el addon;
- una clase o archivo supera 400 líneas.

No extraer por tamaño de forma mecánica. Antes, nombrar la responsabilidad que
se mueve y definir quién será propietario de sus datos y contratos.

## Cómo dividir dentro de un addon

### Modelos

Usar extensiones enfocadas del mismo modelo:

```text
models/
├── request.py                 # campos y comportamiento esencial
├── request_workflow.py        # transiciones y acciones
├── request_validation.py      # constraints y gates reutilizables
├── request_documents.py       # relaciones y reglas documentales
├── request_notifications.py   # correo y actividades
└── request_formatting.py      # display, etiquetas y presentación
```

Reglas:

- El archivo base define `_name`; los parciales usan `_inherit`.
- No duplicar campos ni reimplementar métodos completos si basta una extensión
  estrecha.
- Mantener transiciones de estado en el dominio, nunca en QWeb o JavaScript.
- Los métodos compartidos deben recibir/retornar datos simples cuando no
  necesitan un recordset completo.

### Controladores

```text
controllers/
├── request_controller.py      # declaraciones de rutas y respuestas
├── request_form_schema.py     # allowlist de campos por paso
├── request_form_session.py    # persistencia en sesión
├── request_form_validation.py # adaptación HTTP hacia validadores
└── request_form_mapper.py     # request/session a valores ORM
```

- El controlador comprueba autenticación, propiedad, CSRF y forma de entrada.
- El modelo/servicio decide reglas, estados y valores permitidos.
- `sudo()` solo después de demostrar acceso y solo sobre campos allowlist.
- Conservar `auth`, métodos, CSRF, URLs y códigos HTTP durante refactors.

### Vistas y frontend

- Separar backend, website, portal, wizard, mail y reportes.
- Dividir formularios website por pasos o componentes con límites claros.
- Un archivo JavaScript debe controlar una interacción concreta, no todo el
  formulario.
- Evitar lógica de negocio duplicada en JS; siempre validar nuevamente en el
  servidor.
- Mantener selectores DOM estables o migrarlos con pruebas de navegador.

### Servicios

Usar `AbstractModel` para fronteras técnicas o lógica reutilizable sin tabla:

- entradas simples y explícitas;
- salidas normalizadas;
- excepciones conocidas y seguras;
- sin recibir recordsets de negocio cuando el servicio es genérico;
- sin escribir modelos ajenos de forma oculta;
- red mockeada en todas las pruebas automáticas.

Los métodos públicos de un conector reutilizable no deben depender de métodos
privados ni nombres del primer consumidor.

## Cuándo crear otro addon

Separar en otro addon cuando la responsabilidad tenga ciclo de vida,
dependencias o consumidores distintos. Casos recomendados:

- **Core de negocio:** modelos, estados, seguridad y contratos neutrales.
- **Canal:** portal, website, API o frontend opcional que depende del core.
- **Conector técnico:** cliente genérico para un proveedor externo, sin modelos
  del negocio.
- **Addon puente:** integra un core con un conector (`risk_sharepoint`) y es el
  único que depende de ambos.

```text
conector_técnico          core_negocio
        ▲                      ▲
        └──── addon_puente ────┘

core_negocio
      ▲
      ├── addon_portal
      └── addon_api
```

No crear un addon por cada modelo relacionado cuando todos comparten el mismo
workflow y ciclo de despliegue. Tampoco crear abstracciones multi-consumidor
antes de tener un segundo consumidor real.

## Dependencias

- Las dependencias apuntan desde lo opcional hacia lo estable.
- El core nunca importa ni busca modelos de un addon puente o canal opcional.
- Un conector genérico no depende del módulo que primero lo utilizó.
- Declarar en el manifest solo dependencias realmente utilizadas.
- Si retirar un addon opcional impide operaciones locales del core, el límite
  está mal diseñado.
- Evitar dependencias circulares; usar hooks neutrales en el core y `_inherit`
  en el addon opcional.

## Contratos neutrales y extensibilidad

El core expone comportamiento local seguro:

```python
def _external_storage_enabled(self):
    return False

def _external_download_content(self):
    self.ensure_one()
    return False
```

El addon puente implementa el contrato con `_inherit`. De esta manera:

- instalar la integración habilita comportamiento adicional;
- desinstalarla conserva la operación local;
- controladores y modelos de negocio no conocen SDKs o servicios externos;
- cada proveedor puede sustituirse sin reescribir el workflow.

## Propiedad de datos

Antes de mover código entre addons, decidir explícitamente:

- qué addon define cada modelo y campo;
- quién crea tablas, constraints, XML IDs y datos iniciales;
- qué addon puede desinstalarse sin eliminar datos de negocio;
- qué metadatos deben permanecer en el core durante una ventana de
  compatibilidad;
- qué información requiere restauración local antes de retirar un proveedor.

No mover campos persistidos solo para “limpiar” arquitectura. Si cambia el
propietario del esquema, usar migraciones pre/post y evidencia de conteos y
checksums.

## Compatibilidad durante refactors

Son contratos públicos aunque no estén documentados formalmente:

- `_name` de modelos;
- nombres de campos y valores de selección;
- XML IDs;
- URLs y configuración de rutas;
- parámetros de sistema;
- estructura de payloads y estados;
- templates QWeb heredados por otros addons;
- nombres de servicios consumidos externamente.

Reglas:

1. No cambiar varios contratos a la vez si se pueden migrar por etapas.
2. Añadir alias o fallback temporal solo con fecha/versión de retirada.
3. Copiar configuración histórica únicamente si la canónica está vacía.
4. Nunca imprimir secretos durante una migración.
5. Eliminar compatibilidad solo después de probar actualización real.
6. Las URLs deben moverse de forma atómica: nunca dos controladores activos ni
   una ventana sin ruta.
7. Al mover QWeb, migrar o aliasar XML IDs antes de borrar los anteriores.

## Refactorización por fases

Para cambios grandes usar como máximo tres bloques coordinados:

1. **Preparar:** línea base, pruebas, contratos neutrales y scaffold sin
   duplicar comportamiento.
2. **Extraer:** mover responsabilidad con compatibilidad y actualizar
   consumidores.
3. **Cerrar:** retirar dependencias/aliases temporales, probar desinstalación y
   documentar operación.

Cada bloque debe tener criterio de salida, comandos reproducibles y evidencia.
No marcar una fase como terminada solo porque el código compila.

## Pruebas obligatorias

Validar las topologías que la arquitectura promete:

- core solo;
- core + canal opcional;
- conector genérico solo;
- core + conector mediante addon puente;
- integración desactivada;
- error del proveedor;
- actualización desde la versión instalada;
- segunda actualización idempotente;
- desinstalación y reinstalación del addon opcional.

Para portal/API incluir dos usuarios y demostrar que uno no puede consultar ni
modificar registros del otro. Para integraciones externas, bloquear toda red en
la suite y usar mocks en el límite técnico.

Cuando se clone una base con campos `attachment=True`, copiar PostgreSQL **y**
filestore. Una copia solo SQL no demuestra disponibilidad documental.

## Rendimiento y ORM

- Evitar `search_count` o `search` dentro de loops; usar operaciones batch y
  `_read_group`.
- Preferir create multi y writes sobre recordsets.
- No usar SQL para eludir seguridad o reglas del ORM.
- Si SQL es necesario para una migración masiva, parametrizarlo y verificar
  conteos antes/después.
- Agregar índices solo para dominios reales y medidos.
- No usar `sudo()` como solución de permisos.

## Documentación mínima por addon

Cada addon mantenido debe documentar:

- responsabilidad y límites;
- dependencias y consumidores;
- modelos/servicios públicos;
- instalación y actualización;
- configuración y permisos;
- pruebas y comandos de validación;
- estrategia de desinstalación/rollback cuando maneja integraciones o datos
  sensibles;
- trabajo futuro condicionado por necesidades reales, no especulativas.

## Checklist de revisión

- [ ] Ningún archivo manual supera 400 líneas sin justificación/plan.
- [ ] Cada archivo tiene una responsabilidad nombrable.
- [ ] Controladores delgados; negocio en modelos/servicios.
- [ ] Core sin dependencias inversas hacia addons opcionales.
- [ ] Integraciones detrás de servicio genérico + addon puente.
- [ ] Dependencias opcionales realmente desinstalables.
- [ ] Datos, rutas, XML IDs y parámetros tienen estrategia de migración.
- [ ] Red externa mockeada y permisos probados.
- [ ] Suites ejecutadas en todas las topologías prometidas.
- [ ] Python/XML/JS, manifest, diff y estado Git revisados.
