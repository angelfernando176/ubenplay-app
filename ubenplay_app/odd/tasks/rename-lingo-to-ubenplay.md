# Rename lingo → ubenplay

Renombrar el proyecto completo de "lingo" a "ubenplay" en todas las capas (carpetas, paquete Dart, Android applicationId, nombre visible, base de datos), con pruebas entre cada grupo de cambios.

## Specs

- S1: "quiero cambiar el nombre del proyecto de 'lingo' a 'ubenplay'"
- S2: Alcance confirmado por el usuario (custom, textual): "Realiza toso los cambios: pero en cada grupo de cambios realiza pruebas para evitar problemas de consistencia futuros, los cambios solicitados son: Carpetas/ nombres de paquete/ Android applicationId/ nombre visible de app/ base de datos"
- S3: Nombre de paquete/applicationId exacto elegido por el usuario: `com.ubenplay.app`
- S4: Carpetas y nombres de paquete Dart: `lingo_app` → `ubenplay_app`, `lingo_admin` → `ubenplay_admin`; `pubspec.yaml` `name:` y todos los `import 'package:lingo_app/...'` en `lib/` y `test/`.
- S5: Android applicationId / iOS bundle id → `com.ubenplay.app` (actualmente `com.lingo.lingo_app`).
- S6: Nombre visible de la app (label en launcher/AndroidManifest/Info.plist).
- S7: Base de datos SQLite local `lingo_nouns.db` → renombrar (riesgo de datos: evaluar si hay instalaciones existentes con datos antes de renombrar sin migración).
- S8: Tras cada grupo de cambios, correr pruebas (`flutter analyze`, `flutter test`, build/run) antes de avanzar al siguiente grupo.

## Tasks

- T1 [S4] Renombrar carpeta `lingo_app` → `ubenplay_app`, `pubspec.yaml name:`, imports `package:lingo_app` → `package:ubenplay_app` en lib/test. Verificar `flutter analyze` + `flutter test`.
- T2 [S5] Cambiar Android applicationId a `com.ubenplay.app` (build.gradle.kts, AndroidManifest, carpetas de paquete Kotlin/Java si existen). Verificar build Android (`flutter build apk --debug` o equivalente rápido) y que `flutter doctor`/app sigue corriendo.
- T3 [S6] Cambiar nombre visible (label) en AndroidManifest.xml (`android:label`) e Info.plist (iOS) a "Ubenplay" (o el texto que el usuario confirme si difiere del nombre de paquete).
- T4 [S7] Evaluar impacto de renombrar `lingo_nouns.db` (¿hay datos de usuarios reales en dispositivos ya instalados?) y aplicar el rename en `database_service.dart` con plan de migración si corresponde. Verificar que la app sigue leyendo/creando la DB correctamente.
- T5 [S4] Renombrar carpeta `lingo_admin` → `ubenplay_admin` y ajustar referencias internas (rutas de scripts, nombre de la app Flask si aplica). Verificar que el server sigue levantando (`python run_supabase.py` → 200 OK).
- T6 [S2] Revisión final de consistencia: grep de "lingo" remanente en todo el proyecto (excluyendo historial git y nombres de terceros como Supabase), reportar lo que quede y por qué (ej. nombres de tablas en Supabase que no se tocan sin pedido explícito).

## Log

- L1: Usuario (verbatim): "Antes de continuar, quiero cambiar el nombre del proyecto de "lingo" a "ubenplay", lo hacemos ahora o luego de cargar a gitlab"
- L2: El Gentleman recomendó hacerlo antes de subir a GitLab; usuario confirmó: "si, procede"
- L3: Usuario (verbatim, respuesta a pregunta de alcance): "Realiza toso los cambios: pero en cada grupo de cambios realiza pruebas para evitar problemas de consistencia futuros, los cambios solicitados son: Carpetas/ nombres de paquete/ Android applicationId/ nombre visible de app/ base de datos"
- L4: Usuario eligió nombre de paquete: `com.ubenplay.app`
