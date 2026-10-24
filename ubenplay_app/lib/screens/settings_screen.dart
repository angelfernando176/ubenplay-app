import 'package:flutter/material.dart';
import '../services/evento_usuario_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import 'game_settings_screen.dart';

/// S001: Pantalla de configuración con 3 opciones
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Usuario
          _SettingsCard(
            icon: Icons.person,
            title: 'Usuario',
            subtitle: 'Información básica del usuario',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          const SizedBox(height: 12),
          // Cuenta
          _SettingsCard(
            icon: Icons.card_membership,
            title: 'Cuenta',
            subtitle: 'Tipo de suscripción',
            onTap: () => _showComingSoon(context, 'Cuenta - Tipo de suscripción\n\nPróximamente: planes gratuitos y premium.'),
          ),
          const SizedBox(height: 12),
          // Ajustes de juegos
          _SettingsCard(
            icon: Icons.tune,
            title: 'Ajustes',
            subtitle: 'Habilitar / deshabilitar juegos',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameSettingsScreen())),
          ),
          const SizedBox(height: 12),
          // Administración (root)
          _SettingsCard(
            icon: Icons.admin_panel_settings,
            title: 'Administración',
            subtitle: 'Gestionar sustantivos y base de datos',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
          ),
          const SizedBox(height: 24),
          // Cerrar sesión
          _SettingsCard(
            icon: Icons.logout,
            title: 'Cerrar sesión',
            subtitle: 'Salir de tu cuenta en este dispositivo',
            onTap: () => _cerrarSesion(context),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final u = await UsuarioService.loadSession();
    if (u?.idUsuario != null) {
      await EventoUsuarioService.registrar('logout', idUsuario: u!.idUsuario);
    }
    await UsuarioService.clearSession();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  void _showComingSoon(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🚧 En desarrollo'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  const _SettingsCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: AppTheme.primaryGreen, size: 32),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
