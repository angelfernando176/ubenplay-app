import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/user_progress.dart';
import '../services/evento_usuario_service.dart';
import '../services/lecciones_service.dart';
import '../services/progress_service.dart';
import '../services/usuario_service.dart';
import 'home_screen.dart';
import 'registro_screen.dart';
import 'verificacion_screen.dart';

/// Puerta de entrada: decide qué pantalla mostrar según la sesión local.
///  - sin usuario → Registro
///  - usuario inactivo (estado 0) → Verificación de código
///  - usuario activo (estado 1) → Home
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Usuario? _usuario;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    var u = await UsuarioService.loadSession();
    if (!mounted) return;
    // Registrar apertura (app abierta por un usuario conocido)
    if (u != null && u.idUsuario != null) {
      EventoUsuarioService.registrar('apertura', idUsuario: u.idUsuario);
      // Re-verificar contra el backend: Supabase es fuente de verdad, y lopdp
      // puede haber cambiado vía la Edge Function (link LOPDP).
      if (u.activo) {
        final res = await UsuarioService.estado(correo: u.correo);
        if (res['existe'] == true) {
          u = u.copyWith(
            estado: res['estado'] ?? u.estado,
            lopdp: res['lopdp'] ?? u.lopdp,
            nivelAcceso: res['nivel_acceso'] ?? u.nivelAcceso,
          );
          await UsuarioService.saveSession(u);
        } else if (res.containsKey('existe') && res['existe'] == false) {
          // El backend respondió y el usuario ya no existe → cerrar sesión local
          await UsuarioService.clearSession();
          u = null;
        }
        // Si hubo error de red (sin clave 'existe'), se mantiene la sesión local.
      }
    }
    if (!mounted) return;
    setState(() {
      _usuario = u;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final u = _usuario;
    if (u == null) {
      return RegistroScreen(onRegistrado: (nuevo) => setState(() => _usuario = nuevo));
    }
    if (u.estado == 0) {
      return VerificacionScreen(usuario: u, onVerificado: (activo) => setState(() => _usuario = activo));
    }
    return _HomeAutenticado(usuario: u);
  }
}

class _HomeAutenticado extends StatefulWidget {
  const _HomeAutenticado({required this.usuario});
  final Usuario usuario;

  @override
  State<_HomeAutenticado> createState() => _HomeAutenticadoState();
}

class _HomeAutenticadoState extends State<_HomeAutenticado> {
  late Future<UserProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    // Bug corregido: cargar lecciones ANTES de construir HomeScreen. Antes
    // `loadFromSupabase()` se llamaba dentro de _saludar() (post-diálogo),
    // y HomeScreen ya se había renderizado con la lista vacía sin refrescar.
    _progressFuture = _cargarInicial();
    WidgetsBinding.instance.addPostFrameCallback((_) => _saludar());
  }

  Future<UserProgress> _cargarInicial() async {
    await LeccionesService.loadFromSupabase();
    return ProgressService.loadProgress();
  }

  Future<void> _saludar() async {
    final u = widget.usuario;
    final correos = u.esMenor
        ? '${u.correo} y ${u.correoRepresentante ?? ''}'
        : u.correo;
    final recordatorio = u.autorizadoLopdp
        ? ''
        : '\n\n⚠️ Aún no has autorizado el uso de tus datos personales. '
            'Solo debes dar clic en el enlace enviado al correo $correos.';

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¡Bienvenido, ${u.nombre}!'),
        content: Text('Es bueno tenerte de regreso.$recordatorio'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    // Fase 4: avisar novedades/cambios (lecciones ya se cargaron en _cargarInicial).
    if (u.activo) {
      try {
        final novedad = await LeccionesService.detectarNovedades();
        if (!mounted || novedad == null) return;
        final msg = novedad == 'nuevos'
            ? 'Existen nuevos retos para ti'
            : 'Existen cambios en tus retos';
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🎉 Novedades'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProgress>(
      future: _progressFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }
        return HomeScreen(progress: snapshot.data ?? UserProgress());
      },
    );
  }
}
