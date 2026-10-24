import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../data/lessons_data.dart';
import '../theme/app_theme.dart';

/// S011: Módulo de administración para gestionar sustantivos
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, int> _counts = {};
  bool _loading = true;
  String _status = '';
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final counts = await DatabaseService.getCategoryCounts();
      // Categorías disponibles (las definidas en el sistema)
      final allCats = LessonsData.getCategories();
      _categories = allCats.map((c) => c.id).toList();
      setState(() { _counts = counts; _loading = false; });
    } catch (e) {
      setState(() { _status = 'Error: $e'; _loading = false; });
    }
  }

  Future<void> _pickAndImportExcel() async {
    if (_selectedCategory == null) {
      setState(() => _status = '⚠️ Primero selecciona una categoría destino');
      return;
    }

    // Diálogo para ingresar la ruta del archivo
    final controller = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📂 Seleccionar archivo Excel'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Ingresa la ruta completa del archivo:', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '/storage/emulated/0/Download/archivo.xlsx',
              prefixIcon: Icon(Icons.file_present),
            ),
          ),
          const SizedBox(height: 8),
          const Text('💡 Usa tu gestor de archivos para copiar la ruta',
              style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Importar')),
        ],
      ),
    );

    if (path == null || path.isEmpty) return;

    try {
      setState(() => _status = '📂 Leyendo archivo...');
      final file = File(path);
      
      if (!await file.exists()) {
        setState(() => _status = '❌ El archivo no existe: $path');
        return;
      }
      
      final bytes = file.readAsBytesSync();
      setState(() => _status = '📊 Archivo leído: ${bytes.length} bytes. Parseando...');
      
      final excel = Excel.decodeBytes(bytes);
      final tableNames = excel.tables.keys.toList();
      setState(() => _status = '📋 Hojas encontradas: ${tableNames.length}. Leyendo datos...');

      final data = <Map<String, String>>[];
      for (final table in tableNames) {
        final sheet = excel.tables[table]!;
        final maxRows = sheet.rows.length;
        for (int i = 0; i < maxRows; i++) {
          final row = sheet.rows[i];
          final rowData = row.where((c) => c != null).map((c) => c!.value?.toString() ?? '').toList();
          if (rowData.every((c) => c.isEmpty)) continue;
          // Detectar si es encabezado (primera fila con "español" o "spanish")
          final firstCell = rowData.isNotEmpty ? rowData[0].toLowerCase() : '';
          if (i == 0 && (firstCell == 'español' || firstCell == 'spanish' || firstCell == 'es')) {
            continue; // saltar encabezado
          }
          data.add({
            'spanish': rowData.length > 0 ? rowData[0] : '',
            'article': rowData.length > 1 ? rowData[1] : 'der',
            'german': rowData.length > 2 ? rowData[2] : '',
            'plural': rowData.length > 3 ? rowData[3] : '',
            'level': rowData.length > 4 ? rowData[4] : 'A1',
          });
        }
      }

      setState(() => _status = '📊 ${data.length} filas leídas. Validando e importando...');

      if (data.isEmpty) {
        setState(() => _status = '⚠️ El archivo no contiene datos (${bytes.length} bytes leídos).\nVerifica que el Excel tenga datos en la primera hoja.');
        return;
      }

      setState(() => _status = '🔄 Importando ${data.length} palabras a "$_selectedCategory"...');

      final result2 = await DatabaseService.importFromExcel(data, _selectedCategory!);

      // Recargar datos en memoria para que aparezcan en los juegos
      await LessonsData.reloadFromDatabase();

      final imported = result2;
      final errors = <String>[];
      final duplicates = <String>[];

      String msg = '✅ $imported sustantivos importados a "$_selectedCategory"';
      if (duplicates.isNotEmpty) {
        msg += '\n\n⚠️ ${duplicates.length} duplicados omitidos:\n${duplicates.take(5).join('\n')}';
        if (duplicates.length > 5) msg += '\n...y ${duplicates.length - 5} más';
      }
      if (errors.isNotEmpty) {
        msg += '\n\n❌ ${errors.length} errores:\n${errors.take(5).join('\n')}';
        if (errors.length > 5) msg += '\n...y ${errors.length - 5} más';
      }

      setState(() => _status = msg);
      _loadData();
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    }
  }

  Future<void> _syncFromServer() async {
    setState(() => _status = '🔄 Conectando con el admin web...');
    try {
      final result = await SyncService.syncFromServer();
      if (result['success'] == true) {
        setState(() => _status = '✅ Sincronizado: ${result['imported']} palabras en ${result['categories']} categorías');
      } else {
        setState(() => _status = '❌ ${result['error']}');
      }
      _loadData();
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    }
  }

  Future<void> _configureServer() async {
    final controller = TextEditingController(text: SyncService.serverUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🌐 Servidor Admin Web'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('URL del servidor Flask:', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'http://192.168.1.100:5000',
              prefixIcon: Icon(Icons.dns),
            ),
          ),
          const SizedBox(height: 4),
          const Text('💡 Ambos dispositivos deben estar en la misma red WiFi',
              style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) {
      SyncService.setServerUrl(url);
      setState(() {});
    }
  }

  Future<void> _clearCategory() async {
    if (_selectedCategory == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Confirmar'),
        content: Text('¿Eliminar todos los sustantivos de "$_selectedCategory"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.deleteByCategory(_selectedCategory!);
      await LessonsData.reloadFromDatabase();
      setState(() => _status = '✅ Categoría "$_selectedCategory" vaciada');
      _loadData();
    }
  }

  Future<void> _createTestFile() async {
    try {
      // Usar directorio de la app (accesible sin permisos en Android 11+)
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/ubenplay_test.xlsx';
      
      final excel = Excel.createExcel();
      final sheet = excel['Hoja1'];
      
      sheet.appendRow([TextCellValue('español'), TextCellValue('artículo'), TextCellValue('alemán'), TextCellValue('plural'), TextCellValue('nivel')]);
      
      final testNouns = [
        ['perro', 'der', 'Hund', 'Hunde', 'A1'],
        ['gato', 'die', 'Katze', 'Katzen', 'A1'],
        ['hospital', 'das', 'Krankenhaus', 'Krankenhäuser', 'A1'],
        ['restaurante', 'das', 'Restaurant', 'Restaurants', 'A1'],
        ['tienda', 'der', 'Laden', 'Läden', 'A1'],
        ['banco', 'die', 'Bank', 'Banken', 'A1'],
        ['parque', 'der', 'Park', 'Parks', 'A1'],
        ['puente', 'die', 'Brücke', 'Brücken', 'A1'],
        ['calle', 'die', 'Straße', 'Straßen', 'A1'],
        ['iglesia', 'die', 'Kirche', 'Kirchen', 'A1'],
      ];
      
      for (final noun in testNouns) {
        sheet.appendRow(noun.map((c) => TextCellValue(c)).toList());
      }
      
      final file = File(filePath);
      final bytes = excel.encode()!;
      await file.writeAsBytes(bytes);
      
      setState(() => _status = '✅ Archivo de prueba creado en:\n$filePath\n\nCategoría sugerida: "city" o "city2"');
    } catch (e) {
      setState(() => _status = '❌ Error al crear archivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🛠️ Administración')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (_status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: Text(_status, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),

              // Selector de categoría
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Categoría destino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Selecciona una categoría'),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 12),

              // Botones
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    ElevatedButton.icon(
                      onPressed: _selectedCategory == null ? null : _pickAndImportExcel,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Importar desde Excel'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.xpBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _syncFromServer,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sincronizar desde Admin Web'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _selectedCategory == null ? null : _clearCategory,
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('Vaciar esta categoría', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _createTestFile,
                      icon: const Icon(Icons.description),
                      label: const Text('Crear Excel de prueba'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _configureServer,
                      icon: const Icon(Icons.dns, size: 16),
                      label: Text('Servidor: ${SyncService.serverUrl}', style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // Conteo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Sustantivos en base de datos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (_counts.isEmpty)
                      const Text('Sin datos. Importa un archivo Excel para comenzar.', style: TextStyle(color: AppTheme.textLight)),
                    ..._counts.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Expanded(child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                            Text('${e.value}', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w700, fontSize: 16)),
                          ]),
                        )),
                    const Divider(),
                    Row(children: [
                      const Expanded(child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                      Text('${_counts.values.fold<int>(0, (a, b) => a + b)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.xpBlue)),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // Formato
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('📋 Formato del Excel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _col('A', 'Sustantivo (español)', 'perro'),
                    _col('B', 'Artículo (der/die/das)', 'der'),
                    _col('C', 'Sustantivo (alemán)', 'Hund'),
                    _col('D', 'Plural (alemán)', 'Hunde'),
                    _col('E', 'Nivel (A1/A2/B1/B2)', 'A1'),
                    const SizedBox(height: 8),
                    const Text('⚠️ La primera fila debe contener los datos, no encabezados.',
                        style: TextStyle(fontSize: 11, color: AppTheme.incorrectRed)),
                  ]),
                ),
              ),
            ]),
    );
  }

  Widget _col(String letter, String desc, String ex) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Container(width: 28, height: 28, alignment: Alignment.center,
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withAlpha(30), borderRadius: BorderRadius.circular(4)),
              child: Text(letter, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
          const SizedBox(width: 8),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 13))),
          Text(ex, style: const TextStyle(fontSize: 12, color: AppTheme.textLight, fontStyle: FontStyle.italic)),
        ]),
      );
}
