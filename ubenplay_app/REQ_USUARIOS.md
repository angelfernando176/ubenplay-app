# Requerimiento: Sistema de Usuarios (Registro + Login + Niveles de acceso + LOPDP)

Fecha: 2026-08-19

## Visión general
Sistema completo de gestión de usuarios para Lingo:
- Registro desde la APK con verificación por código de 6 dígitos enviado por correo.
- CRUD de usuarios desde el admin web (búsqueda, orden, paginación, editar/inactivar).
- Niveles de acceso (1 Registrado, 2 Funcional, 3 Licenciamiento1, 4 Licenciamiento2).
- Autorización LOPDP (link en correo + recordatorio en la app).
- Registro de eventos de ingreso/salida (eventos_usuario) con sync en background.
- Historial de cambios de nivel (registro_usuarios) con código encriptado.

## Registro desde APK
Datos: nombre, apellido, correo electrónico, rango de edad, país.
Rango de edad: 1) Menor a 18 años, 2) 18 a 35, 3) 36 a 50, 4) Mayores de 50.
Si elige "Menor a 18" → habilita campo extra: correo electrónico del representante.

## Flujo APK
1. Primer uso: no hay registro → solicitar creación de usuario.
2. "Guardar" → mensaje "Pronto recibirás un correo con un código de 6 dígitos".
3. Guardar info en SQLite + Supabase.
4. Siguiente ingreso → preguntar por el código. Botón "insistir en solicitud" si no llegó.
5. Código correcto → acceso. Estado pasa de Inactivo (0) a Activo (1).
6. Ingresos posteriores → "Bienvenido [nombre] es bueno tenerte de regreso."
7. Si no autorizó LOPDP → recordatorio: "Aun no has autorizado el uso de tus datos personales...
   solo debes dar clic en el link enviado al correo [correo_usuario] [correo_representante]" (representante solo menores).

## Admin (Escritorio) — CRUD de usuarios
- Búsqueda: selector de campo + texto (arriba izquierda).
- Columnas ordenables (asc/desc): Nombre, Apellido, correo electrónico, nivel de acceso, Estado, Insistencias, LOPDP.
- Paginación (inferior).
- Por fila: botones "Editar" e "Inactivar".

### Niveles de acceso
1 Registrado, 2 Funcional, 3 Licenciamiento1, 4 Licenciamiento2.

### Estado
0 inactivo, 1 activo.

### LOPDP (Ley Orgánica de Protección de Datos Personales)
0 no autorizado, 1 autorizado.

### Editar
- Cambiar nivel de acceso (ascendente 1→2, 2→3, 3→4) → SIEMPRE generar código alfanumérico de 6 dígitos → enviar por correo.
- Botón "Insistir en Autorización" → reenviar correo de autorización LOPDP.

## Envío de correo
- Contenido: saludo, razón, código de activación, explicación de la necesidad de autorización LOPDP,
  PDF adjunto (Autorización de uso de datos personales), link de autorización al final.
- Menores (<18): correo a usuario + representante. El correo del REPRESENTANTE SÍ lleva link de autorización;
  el correo del MENOR NO lleva el link.

## Tablas (SQLite + Supabase, salvo eventos_usuario que inicia en SQLite)

### usuarios
nombre, apellido, correo, rango_edad, país, correo_representante (nullable),
nivel_acceso (1-4), estado (0/1), lopdp (0/1), insistencias (int), código_hash (encriptado).

### registro_usuarios (SQLite + Supabase)
fecha_hora, id_usuario, código_enviado (ENCRIPTADO), tipo_cambio (1→2, 2→3, 3→4).

### eventos_usuario (SQLite local; sync a Supabase en background con internet)
Registro de ingreso/salida de la app por el usuario.

## Pendientes por definir (bloqueantes)
1. Servicio SMTP para envío de correos (host, puerto, credenciales/API key).
2. Endpoint público del link de autorización LOPDP (el admin Flask está en IP LAN, no público).
3. Método de encriptación del código (hash vs reversible).
4. Contenido/texto legal del PDF de autorización.
5. Campos exactos de eventos_usuario.
