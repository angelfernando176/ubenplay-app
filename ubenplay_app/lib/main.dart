import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate.dart';
import 'services/database_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_progreso_service.dart';
import 'data/lessons_data.dart';

// ═══ CONFIGURACIÓN SUPABASE ═══
// Reemplaza ANON_KEY con el valor de: Supabase Dashboard → Settings → API → anon/public
const SUPABASE_URL = 'https://jtrrqbnxhxxqjcpizjuy.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_snBSbyTIkIU8_qQdsw_SpQ_6p5UDuxS';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Directriz de persistencia: SQLite local SIEMPRE se abre (progreso del
  // estudiante vive ahí, independiente de si Supabase está disponible).
  await DatabaseService.database;

  bool useSupabase = false;

  // Intentar conectar a Supabase
  if (SUPABASE_URL.contains('TU_PROYECTO')) {
    print('[Ubenplay] Supabase no configurado. Usando SQLite local.');
  } else {
    try {
      await SupabaseService.init(url: SUPABASE_URL, publishableKey: SUPABASE_ANON_KEY);
      final connected = await SupabaseService.testConnection();
      if (connected) {
        useSupabase = true;
        print('[Ubenplay] ✅ Conectado a Supabase');
        // Cargar datos desde Supabase
        await LessonsData.reloadFromSupabase();
        // Cola de sync: sube progreso/avance pendiente (sincronizado=0) en
        // background, sin bloquear el arranque.
        SyncProgresoService.sync();
      }
    } catch (e) {
      print('[Ubenplay] ⚠️ Supabase no disponible: $e');
    }
  }

  // Fallback a SQLite local (seed de palabras; la BD de progreso ya está abierta)
  if (!useSupabase) {
    await DatabaseService.clearAll();
    await LessonsData.migrateToDatabase();
    // No llamar reloadFromDatabase — usar datos hardcoded directamente
    // await LessonsData.reloadFromDatabase(); ← QUITAR
  }

  runApp(const UbenplayApp());
}

class UbenplayApp extends StatelessWidget {
  const UbenplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ubenplay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AuthGate(),
    );
  }
}

