import 'package:flutter/material.dart';
import '../main.dart';
import '../services/db_service.dart';

class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});
  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  List<Map<String, dynamic>> _notas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final notas = await DbService.instance.getNotas();
    setState(() => _notas = notas);
  }

  Future<void> _abrirFormulario({Map<String, dynamic>? nota}) async {
    final tituloCtrl = TextEditingController(text: nota?['titulo'] ?? '');
    final textoCtrl = TextEditingController(text: nota?['texto'] ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloCtrl,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Título (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textoCtrl,
              maxLength: 200,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Nota',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  if (textoCtrl.text.trim().isEmpty) return;
                  if (nota == null) {
                    final limite = await DbService.instance.limiteAlcanzado('notas');
                    if (limite) {
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Versión de prueba: límite alcanzado'),
                          backgroundColor: Colors.red,
                        ));
                      }
                      return;
                    }
                    await DbService.instance.insertNota({
                      'titulo': tituloCtrl.text.trim(),
                      'texto': textoCtrl.text.trim(),
                    });
                  } else {
                    await DbService.instance.updateNota(nota['id'], {
                      'titulo': tituloCtrl.text.trim(),
                      'texto': textoCtrl.text.trim(),
                    });
                  }
                  notificarCambio();
                  if (mounted) Navigator.pop(context);
                  _cargar();
                },
                child: Text(nota != null ? 'Actualizar' : 'Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminar(int id) async {
    await DbService.instance.deleteNota(id);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _notas.isEmpty
          ? const Center(child: Text('Sin notas. Toca + para agregar.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notas.length,
              itemBuilder: (_, i) {
                final n = _notas[i];
                final titulo = (n['titulo'] as String).isNotEmpty
                    ? n['titulo']
                    : (n['texto'] as String).length > 30
                        ? '${(n['texto'] as String).substring(0, 30)}...'
                        : n['texto'];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(titulo,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: (n['titulo'] as String).isNotEmpty
                        ? Text(n['texto'],
                            maxLines: 2, overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _abrirFormulario(nota: n),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminar(n['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}