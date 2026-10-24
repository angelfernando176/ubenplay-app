import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de perfil de usuario
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _ageRange = '18-26';
  bool _loading = true;

  static const _ageRanges = ['12-17', '18-26', '27-59', '60+'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfileService.loadProfile();
    _firstNameCtrl.text = profile.firstName;
    _lastNameCtrl.text = profile.lastName;
    _emailCtrl.text = profile.email;
    if (_ageRanges.contains(profile.ageRange)) {
      _ageRange = profile.ageRange;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = UserProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      ageRange: _ageRange,
      email: _emailCtrl.text.trim(),
      isComplete: true,
    );
    await UserProfileService.saveProfile(profile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Perfil guardado'), backgroundColor: AppTheme.primaryGreen),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('👤 Perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.account_circle, size: 80, color: AppTheme.primaryGreen),
                    const SizedBox(height: 16),
                    Text('Nombre', style: _labelStyle),
                    TextFormField(
                      controller: _firstNameCtrl,
                      decoration: _decoration('Tu nombre'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    Text('Apellido', style: _labelStyle),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: _decoration('Tu apellido'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    Text('Rango de edad', style: _labelStyle),
                    DropdownButtonFormField<String>(
                      initialValue: _ageRange,
                      decoration: _decoration(null),
                      items: _ageRanges.map((r) => DropdownMenuItem(value: r, child: Text('$r años'))).toList(),
                      onChanged: (v) => setState(() => _ageRange = v!),
                    ),
                    const SizedBox(height: 12),
                    Text('Correo electrónico', style: _labelStyle),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: _decoration('tu@email.com'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Guardar perfil', style: TextStyle(fontSize: 17)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  TextStyle get _labelStyle => const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark);
  InputDecoration _decoration(String? hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: AppTheme.cardWhite,
      );
}
