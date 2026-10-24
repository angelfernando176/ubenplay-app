import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/usuario.dart';
import '../services/evento_usuario_service.dart';
import '../services/usuario_service.dart';

class VerificacionScreen extends StatefulWidget {
  const VerificacionScreen({super.key, required this.usuario, required this.onVerificado});
  final Usuario usuario;
  final void Function(Usuario) onVerificado;

  @override
  State<VerificacionScreen> createState() => _VerificacionScreenState();
}

class _VerificacionScreenState extends State<VerificacionScreen> {
  final _codigo = TextEditingController();
  bool _verificando = false;
  bool _reenviando = false;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _verificar() async {
    final codigo = _codigo.text.trim();
    if (codigo.length != 6) {
      _snack('El código tiene 6 caracteres.');
      return;
    }
    setState(() => _verificando = true);
    final res = await UsuarioService.verificar(correo: widget.usuario.correo, codigo: codigo);
    if (!mounted) return;
    setState(() => _verificando = false);

    if (res['success'] == true) {
      final u = widget.usuario.copyWith(estado: 1, lopdp: res['lopdp'] ?? widget.usuario.lopdp, nivelAcceso: res['nivel_acceso'] ?? widget.usuario.nivelAcceso);
      await UsuarioService.saveSession(u);
      EventoUsuarioService.registrar('login', idUsuario: u.idUsuario);
      widget.onVerificado(u);
    } else {
      _snack(res['error']?.toString() ?? 'Código incorrecto.');
    }
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    final res = await UsuarioService.reenviarCodigo(correo: widget.usuario.correo);
    if (!mounted) return;
    setState(() => _reenviando = false);
    if (res['success'] == true) {
      _snack(res['mensaje']?.toString() ?? 'Se reenvió el código.');
    } else {
      _snack(res['error']?.toString() ?? 'No se pudo reenviar el código.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text('✉️', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Verifica tu correo', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Pronto recibirás un correo con un código de 6 dígitos.\nEnviado a: ${widget.usuario.correo}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _codigo,
                textAlign: TextAlign.center,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 32, letterSpacing: 12, fontWeight: FontWeight.w800),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                decoration: const InputDecoration(
                  labelText: 'Código',
                  hintText: '······',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _verificar(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _verificando ? null : _verificar,
                child: _verificando
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Verificar'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _reenviando ? null : _reenviar,
                child: _reenviando ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Text('¿No recibiste el código? Reenviar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
