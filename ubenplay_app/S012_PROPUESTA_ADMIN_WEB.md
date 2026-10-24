# S012 — Propuesta de Herramienta Web de Administración para Lingo

## 🎯 Objetivo

Aplicación web de escritorio para que el administrador (root) pueda:
- Cargar sustantivos masivamente desde archivos Excel
- Gestionar todos los niveles CEFR (A1: 1,400 | A2: 1,400 acum. | B1: 2,500 acum. | B2: 4,000 acum.)
- Administrar usuarios (root, profesor, estudiante)
- Autenticación con restricción de acceso
- Conexión directa con la base de datos SQLite de la app Lingo

---

## 🏆 Tecnología recomendada: Python + Flask

| Criterio | Python + Flask | PHP | Java |
|---|---|---|---|
| Curva de aprendizaje | ✅ Baja | ✅ Baja | ❌ Alta |
| Lectura de Excel | ✅ openpyxl/pandas | ✅ PhpSpreadsheet | ✅ Apache POI |
| SQLite nativo | ✅ sqlite3 (built-in) | ✅ PDO | ✅ JDBC |
| Admin panel integrado | ✅ Flask-Admin | ❌ Manual | ✅ Spring Boot |
| Peso/recursos | ✅ Liviano | ✅ Liviano | ❌ Pesado |
| Despliegue local | ✅ `python app.py` | ✅ XAMPP | ❌ Tomcat |
| Autenticación | ✅ Flask-Login | ✅ Sesiones | ✅ Spring Security |
| Futuro: API REST | ✅ Flask-RESTful | ❌ Más código | ✅ Spring REST |

---

## 📐 Arquitectura propuesta

```
┌─────────────────────────────────────────────────────┐
│                  ADMIN WEB (Python/Flask)            │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │  Login   │  │ Usuarios │  │ Carga Excel      │   │
│  │ (Flask-  │  │ (CRUD)   │  │ (openpyxl)       │   │
│  │  Login)  │  │          │  │                  │   │
│  └──────────┘  └──────────┘  └──────────────────┘   │
│                        │                             │
│                 ┌──────▼──────┐                      │
│                 │  SQLAlchemy │                      │
│                 │  (ORM)      │                      │
│                 └──────┬──────┘                      │
└────────────────────────┼────────────────────────────┘
                         │
              ┌──────────▼──────────┐
              │  lingo_nouns.db     │
              │  (SQLite)           │
              │  Misma BD que la    │
              │  app Flutter        │
              └─────────────────────┘
```

### 🔄 Sincronización con la app Flutter

**Opción A (mismo dispositivo):**
- El admin web lee/escribe directamente `lingo_nouns.db`
- La app Flutter usa `LessonsData.reloadFromDatabase()` al iniciar
- Cambios son inmediatos al reiniciar la app

**Opción B (red local):**
- El admin web expone una API REST (Flask-RESTful)
- La app Flutter consume la API para sincronizar
- Endpoint: `POST /api/import` recibe el Excel y actualiza la BD

**Opción C (archivo compartido):**
- Admin web exporta la BD actualizada
- App Flutter la descarga/sincroniza al iniciar

---

## 🗂️ Estructura del proyecto

```
lingo_admin/
├── app.py                  # Servidor Flask
├── models.py               # SQLAlchemy (usuarios + sustantivos)
├── auth.py                 # Flask-Login
├── excel_import.py         # Procesamiento de Excel
├── templates/
│   ├── base.html           # Layout
│   ├── login.html          # Login
│   ├── dashboard.html      # Panel principal
│   ├── users.html          # CRUD usuarios
│   ├── import.html         # Carga de Excel
│   └── categories.html     # Vista por categoría/nivel
├── static/
│   └── style.css
├── requirements.txt        # Dependencias
└── lingo_nouns.db          # BD compartida
```

---

## 📦 Dependencias (requirements.txt)

```
flask>=3.0
flask-login>=0.6
flask-sqlalchemy>=3.1
openpyxl>=3.1
pandas>=2.2
werkzeug>=3.0
```

---

## 🔐 Modelo de autenticación

| Tipo | Permisos |
|---|---|
| **root** | Todo: importar, gestionar usuarios, ver estadísticas |
| **profesor** | Importar sustantivos, ver progreso de estudiantes |
| **estudiante** | Solo consulta (no accede al admin web) |

---

## 📊 Flujo de importación Excel

```
1. Admin inicia sesión (root)
2. Selecciona "Importar Excel"
3. Sube archivo .xlsx
4. El sistema valida:
   - Columnas: español, artículo, alemán, plural, nivel
   - Artículos válidos: der/die/das
   - Niveles válidos: A1/A2/B1/B2
   - Sin duplicados
5. Muestra vista previa de lo que se importará
6. Confirma → escribe en lingo_nouns.db
7. Muestra resumen: X importados, Y duplicados, Z errores
```

---

## 🚀 Instalación y uso

```bash
# 1. Clonar/crear el proyecto
mkdir lingo_admin && cd lingo_admin
pip install flask flask-login flask-sqlalchemy openpyxl pandas

# 2. Copiar la BD de la app Flutter
cp /ruta/a/lingo_app/lingo_nouns.db .

# 3. Iniciar el servidor
python app.py
# → Abrir navegador en http://localhost:5000
```

---

## 📈 Plan de implementación (fases)

| Fase | Duración | Tareas |
|---|---|---|
| **Fase 1** | 2 días | Flask base + login + lectura de BD existente |
| **Fase 2** | 2 días | Importación Excel + validación |
| **Fase 3** | 1 día | CRUD de usuarios (solo root) |
| **Fase 4** | 1 día | Dashboard con estadísticas por nivel |
| **Fase 5** | 1 día | API REST para sincronizar con app Flutter |

---

## ❓ ¿Por qué no otras opciones?

- **PHP**: Funcionaría pero requiere más código boilerplate para admin panel. Flask-Admin da un panel funcional en ~20 líneas.
- **Java + Spring**: Sobredimensionado para este alcance. El JAR sería >50MB vs ~5MB de Flask.
- **Node.js**: También viable, pero Python tiene mejor soporte para Excel (openpyxl, pandas).

---

## ✅ Recomendación final

**Python + Flask** es la opción óptima:
- Desarrollo rápido (~1 semana)
- Misma BD SQLite que la app
- Arranca con un comando
- Admin panel con Flask-Admin en minutos
- Escalable a API REST cuando se necesite

¿Procedo con el desarrollo del módulo web?
