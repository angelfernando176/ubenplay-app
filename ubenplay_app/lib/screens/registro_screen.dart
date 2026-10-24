import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/usuario_service.dart';

const _rangosEdad = [
  (1, 'Menor a 18 años'),
  (2, '18 a 35 años'),
  (3, '36 a 50 años'),
  (4, 'Mayores de 50 años'),
];

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key, required this.onRegistrado});
  final void Function(Usuario) onRegistrado;

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();
  final _pais = TextEditingController();
  final _correoRep = TextEditingController();
  int _rangoEdad = 2;
  bool _enviando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _correo.dispose();
    _pais.dispose();
    _correoRep.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    final res = await UsuarioService.registrar(
      nombre: _nombre.text.trim(),
      apellido: _apellido.text.trim(),
      correo: _correo.text.trim(),
      rangoEdad: _rangoEdad,
      pais: _pais.text.trim(),
      correoRepresentante: _rangoEdad == 1 ? _correoRep.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _enviando = false);

    if (res['success'] == true) {
      final u = Usuario(
        idUsuario: res['id_usuario'],
        nombre: _nombre.text.trim(),
        apellido: _apellido.text.trim(),
        correo: _correo.text.trim(),
        rangoEdad: _rangoEdad,
        pais: _pais.text.trim(),
        correoRepresentante: _rangoEdad == 1 ? _correoRep.text.trim() : null,
        estado: 0,
      );
      await UsuarioService.saveSession(u);
      widget.onRegistrado(u);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error']?.toString() ?? 'Error al registrar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esMenor = _rangoEdad == 1;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text('🦉', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Crea tu cuenta', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Regístrate para empezar a aprender alemán', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person)),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _apellido,
                  decoration: const InputDecoration(labelText: 'Apellido', prefixIcon: Icon(Icons.person_outline)),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu apellido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _correo,
                  decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Ingresa tu correo';
                    if (!s.contains('@') || !s.contains('.')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _rangoEdad,
                  decoration: const InputDecoration(labelText: 'Rango de edad', prefixIcon: Icon(Icons.cake)),
                  items: _rangosEdad.map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
                  onChanged: (v) => setState(() => _rangoEdad = v ?? 2),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pais,
                  decoration: const InputDecoration(labelText: 'País', prefixIcon: Icon(Icons.public)),
                  textCapitalization: TextCapitalization.words,
                ),
                if (esMenor) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _correoRep,
                    decoration: const InputDecoration(labelText: 'Correo del representante legal', prefixIcon: Icon(Icons.family_restroom)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Para menores de 18, el correo del representante es obligatorio';
                      if (!s.contains('@') || !s.contains('.')) return 'Correo no válido';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _enviando ? null : _guardar,
                  child: _enviando
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Guardar'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
