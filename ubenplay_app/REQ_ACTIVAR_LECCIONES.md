# Requerimiento: Activar lecciones + flujo de carga batch

Fecha: 2026-09-12 · Estado: especificación aprobada, pendiente de implementación.

## 1. Resumen del cambio de flujo

**Antes:** la carga batch creaba las lecciones automáticamente (la app derivaba lecciones de
10 palabras de la tabla `palabras`).

**Ahora:** la carga batch **solo escribe metadatos** en `datos_batch` (estado 0 "cargada").
Las lecciones se crean **explícitamente** solo cuando el profesor las **Activa**.

## 2. Flujo de carga batch (nuevo)

1. El profesor carga información ("carga batch") en la app de escritorio.
2. Se guardan metadatos en `datos_batch`: `fecha_carga`, `numero_palabras`, `id_tematica`,
   `id_categoria`, `id_usuario`, `observaciones`, `nombre_archivo`, `estado=0`.
3. Al finalizar, se muestra: **"Recuerde activar las lecciones de esta carga para el
   estudiante, a través de la opción: Activar lecciones"**.

## 3. Pantalla "Activar lecciones" (app de escritorio)

Lista de cargas batch desde `datos_batch`. Columnas:
- **Fecha de carga** (`fecha_carga`)
- **Tipo de carga** (`id_categoria`)
- **Cantidad de palabras** (`numero_palabras`)
- **Estado**: 0 = cargada (no disponible para estudiante) · 1 = disponible · 2 = inactivado
- **Acciones**

### 3.1 Acciones

**Activar** — popup con listado de juegos disponibles (check). Al "Aceptar": advertencia
*"Si la carga es activada, NO podrá borrarse en el futuro"* + Aceptar/Cancelar. Si acepta:
- a1) `datos_batch.estado` → 1 (disponible).
- a2) crea registros en `encabezado_leccion`, `leccion_detalle`, `leccion_palabras`.
- a3) en la bienvenida del estudiante aparece *"Existen nuevos retos para ti"*; al aceptar,
  descarga la información (Supabase→SQLite) de las 3 tablas.

**Revisar** — abre `/words` (pantalla de revisión de palabras).

**Inactivar** — popup *"¿desea desactivar esta carga de información?"*. Si Acepta:
- a) `datos_batch.estado` → 2 (inactivado).
- b) desactiva las lecciones dependientes (campo `estado` en `encabezado_leccion`,
  `leccion_detalle`, `leccion_palabras`); el estudiante deja de verlas.
- c) en la bienvenida del estudiante aparece *"Existen cambios en tus retos"*; al aceptar,
  sincroniza (SQLite ← Supabase) las 3 tablas.

**Borrar** — activo **solo** si la carga nunca se activó (no hay registros en las 3 tablas).

## 4. Acotaciones

### 4.1 `usuarios.id_suscripcion`
Nuevo campo en `usuarios`: `id_suscripcion` (default `0` = uso limitado de la app móvil, sin
acompañamiento para la app de escritorio).

### 4.2 Dedup de palabra
Llave natural: `palabra_es + palabra_de + id_tematica + id_suscripcion`.
Al detectar que una palabra ya estaba cargada, ante inactivación/actualización:
1. Si el estudiante **no tiene avance** en la lección → borrar los datos de la carga
   (`id_leccion + id_suscripcion`) en `encabezado_leccion`, `leccion_detalle`, `leccion_palabras`.
2. Si **tiene avance** → borrar los datos, pero en la interfaz de lecciones mostrar un mensaje
   que invita al repaso de esa lección "x más puntos".

### 4.3 Pantalla 1 (temáticas)
Pantalla justo después de ingresar; muestra temáticas. Datos desde
**`cat_tematica + datos_batch + encabezado_leccion`** (vista `v_tematicas_disponibles`).
Evitar hardcodeo (elimina el bug de temáticas diagnosticado).

### 4.4 Pantalla 2 (lecciones)
Listado de lecciones habilitadas. Siempre revisar **`leccion_palabras`** para los 3 estados:
a) **Sin iniciar** · b) **Iniciada** · c) **Finalizada**.

## 5. Decisiones confirmadas (Fernando)

1. Pantalla 1 → `cat_tematica + datos_batch + encabezado_leccion`.
2. "Tipo de carga" = `id_categoria`.
3. "Finalizada" = `palabras_aprendidas >= porcentaje_aciertos` (default = `cantidad_palabras`).
4. Dedup = `(es + de + tema + id_suscripcion)`.
5. "Revisar" = `/words`.

## 6. Vistas SQL e índices

```sql
-- Pantalla 1: temáticas con lecciones disponibles
CREATE VIEW v_tematicas_disponibles AS
SELECT
    ct.id_tematica,
    ct.nombre_tematica,
    COUNT(el.id_leccion) AS lecciones_disponibles
FROM cat_tematica ct
JOIN datos_batch        db ON db.id_tematica = ct.id_tematica
JOIN encabezado_leccion el ON el.id_datos_batch = db.id_datos_batch
WHERE el.estado = 1
GROUP BY ct.id_tematica, ct.nombre_tematica;

-- Pantalla 2a: lecciones disponibles
CREATE VIEW v_lecciones AS
SELECT
    el.id_leccion,
    db.id_tematica,
    ct.nombre_tematica,
    db.id_categoria,
    el.fecha_inicio,
    el.cantidad_palabras,
    el.porcentaje_aciertos,
    el.tipo_leccion,
    el.id_suscripcion
FROM encabezado_leccion el
JOIN datos_batch db ON db.id_datos_batch = el.id_datos_batch
JOIN cat_tematica ct ON ct.id_tematica = db.id_tematica
WHERE el.estado = 1;

-- Pantalla 2b: progreso por lección y estudiante
CREATE VIEW v_progreso_leccion AS
SELECT
    id_leccion,
    id_usuario,
    COUNT(*) AS palabras_revisadas,
    COUNT(*) FILTER (WHERE aprendida) AS palabras_aprendidas
FROM leccion_palabras
WHERE estado = 1
GROUP BY id_leccion, id_usuario;

-- Índices
CREATE INDEX idx_datos_batch_tematica          ON datos_batch(id_tematica);
CREATE INDEX idx_encabezado_leccion_batch      ON encabezado_leccion(id_datos_batch);
CREATE INDEX idx_encabezado_leccion_estado     ON encabezado_leccion(estado);
CREATE INDEX idx_leccion_palabras_leccion_user ON leccion_palabras(id_leccion, id_usuario);
```

**Estados de Pantalla 2** (cruce de `v_lecciones` + `v_progreso_leccion` para el estudiante):
| Estado | Criterio |
|---|---|
| Sin iniciar | sin fila en `v_progreso_leccion` para (id_leccion, id_usuario) |
| Iniciada | `palabras_aprendidas < porcentaje_aciertos` |
| Finalizada | `palabras_aprendidas >= porcentaje_aciertos` |

## 7. Plan de implementación

- ✅ **Fase 0 — Esquema y vistas**: script ejecutado en Supabase, `usuarios.id_suscripcion`
  añadido (SQLite + Supabase), vistas + índices creados en ambos.
- ✅ **Fase 1 — Admin: carga batch → `datos_batch`**: importación escribe metadatos en
  `datos_batch` (estado=0) + mensaje "Recuerde activar…" en el popup de resumen.
- **Fase 2 — Admin: pantalla "Activar lecciones"**: ruta + template, listar `datos_batch`.
- **Fase 3 — Admin: lógica de acciones** (Activar/Revisar/Inactivar/Borrar + dedup
  `es+de+tema+id_suscripcion`).
- **Fase 4 — App móvil**: mensajes de bienvenida, sync Supabase→SQLite de las 3 tablas,
  Pantalla 1 y Pantalla 2 usando las vistas.
- **Fase 5 — Pruebas**: regresión admin + app + sync.
