# ☁️ Migración de Lingo a Supabase — Guía Paso a Paso

## 📋 Requisitos previos
- Cuenta de GitHub o Google para registrarte en Supabase
- 5 minutos para crear el proyecto

---

## Paso 1: Crear proyecto en Supabase

1. Ve a https://supabase.com y haz clic en **"Start your project"**
2. Inicia sesión con GitHub o Google
3. Haz clic en **"New project"**
4. Completa:
   - **Name**: `lingo-db`
   - **Database Password**: `LingoAdmin2026!` (anótala)
   - **Region**: South America (São Paulo) o US East
   - **Pricing Plan**: Free
5. Haz clic en **"Create project"** → espera 1-2 minutos

---

## Paso 2: Obtener credenciales

En el dashboard de Supabase:
1. Ve a **Settings → API** (en la barra lateral)
2. Copia estos dos valores:

| Campo | Ejemplo |
|---|---|
| **Project URL** | `https://xxxxxxxxxxxx.supabase.co` |
| **anon public key** | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |

3. Guarda estos valores — los necesitarás para la app

---

## Paso 3: Crear las tablas

1. En Supabase, ve a **SQL Editor** (barra lateral)
2. Haz clic en **"New query"**
3. Copia y pega el contenido de este archivo:

   📁 **`/home/angel/supabase_migration/schema.sql`**

4. Haz clic en **"Run"** (Ctrl+Enter)

---

## Paso 4: Cargar los datos

1. En SQL Editor, haz clic en **"New query"**
2. Copia y pega el contenido de:

   📁 **`/home/angel/supabase_migration/full_data_dump.sql`** (390 sustantivos)

3. Haz clic en **"Run"**

---

## Paso 5: Configurar las credenciales

Una vez que tengas URL y anonKey, ejecuta:

```bash
# En WSL
mkdir -p ~/.lingo
cat > ~/.lingo/supabase.env << 'EOF'
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
EOF
```

Luego reemplaza los valores en:
- `lib/services/supabase_service.dart` → URL y anonKey
- `lib/main.dart` → Inicialización

---

## Paso 6: Actualizar la app

Los archivos ya están preparados:
- ✅ `supabase_service.dart` — todas las operaciones CRUD
- ✅ `pubspec.yaml` — dependencia agregada
- ✅ `main.dart` — inicialización lista (requiere tus credenciales)

Solo necesitas:
1. Abrir `lib/main.dart`
2. Reemplazar `YOUR_SUPABASE_URL` y `YOUR_ANON_KEY` con tus valores
3. Recompilar el APK

---

## 📊 Comparación: Antes vs Después

| | Antes (SQLite local) | Ahora (Supabase ☁️) |
|---|---|---|
| 📱 App Flutter | Lee BD local | Lee BD en la nube |
| 🖥️ Admin Web | Conexión local | Conexión a Supabase |
| 🔄 Sincronización | Manual (copiar archivos) | **Automática** (misma BD) |
| 🌍 Acceso | Solo mismo dispositivo | **Desde cualquier lugar** |
| 💾 Backup | Manual | Automático (Supabase) |
| 🔐 Auth | Básica | **Supabase Auth** (OAuth, email) |

---

## 🗂️ Archivos generados

```
supabase_migration/
├── schema.sql              ← Crear tablas en Supabase
├── full_data_dump.sql      ← 390 sustantivos (desde Dart)
├── data_dump.sql           ← 50 registros (desde BD local)
├── export_to_supabase.py   ← Script de exportación
└── README.md               ← Esta guía
```
