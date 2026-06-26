import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../services/db_service.dart';
import '../services/preferencias_service.dart';
import '../utils/formato.dart';

class AgendaScreen extends StatefulWidget {
  final String rubro;
  final int motor;
  const AgendaScreen({super.key, required this.rubro, required this.motor});
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  String _filtroEstado = 'pendiente';
  List<Map<String, dynamic>> _agendamientos = [];
  late Map<String, String> _mascaras;

  @override
  void initState() {
    super.initState();
    _mascaras = PreferenciasService.getMascaras(widget.rubro);
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await DbService.instance.getAgendamientos(estado: _filtroEstado);
    setState(() => _agendamientos = data);
  }

  Future<void> _cambiarEstado(Map<String, dynamic> item, String nuevoEstado) async {
    await DbService.instance.updateAgendamiento(item['id'], {'estado': nuevoEstado});
    _cargar();
  }

  Future<void> _eliminar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            child: const Text('ELIMINAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DbService.instance.deleteAgendamiento(id);
      _cargar();
    }
  }

  String _formatFecha(String fecha) {
    try {
      final d = DateTime.parse(fecha);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) { return fecha; }
  }

  String _mensajeWhatsApp(Map<String, dynamic> a) {
    final cliente = a['cliente'] ?? '';
    final buffer = StringBuffer();
    buffer.write('Hola $cliente, tu turno fue agendado para el ${_formatFecha(a['fecha'] ?? '')}');
    if (widget.motor == 1 && a['hora'] != null && (a['hora'] as String).isNotEmpty) {
      buffer.write(' a las ${a['hora']}');
      if (a['profesional'] != null && (a['profesional'] as String).isNotEmpty) {
        buffer.write(' con ${a['profesional']}');
      }
    }
    buffer.write('.\n\nResponde:\n1. Confirmar\n2. Cancelar\n3. Cambiar fecha/hora');
    return buffer.toString();
  }

  Future<void> _contactarCliente(Map<String, dynamic> a) async {
    await Share.share(_mensajeWhatsApp(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Agenda', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['pendiente', 'completado', 'cancelado'].map((estado) {
                  final selec = _filtroEstado == estado;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      label: Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: selec ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: selec,
                      selectedColor: primaryColor,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: selec ? primaryColor : const Color(0xFFE9ECEF)),
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _filtroEstado = estado);
                        _cargar();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _agendamientos.isEmpty
                ? const Center(
                    child: Text(
                      'Sin registros',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _agendamientos.length,
                    itemBuilder: (_, i) {
                      final a = _agendamientos[i];
                      final esPendiente = a['estado'] == 'pendiente';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      a['cliente'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 14,
                                          color: Color(0xFF212529)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatFecha(a['fecha'] ?? ''),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              if (a['profesional'] != null && (a['profesional'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${_mascaras['profesional']}: ${a['profesional']}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF495057)),
                                  ),
                                ),
                              if (a['hora'] != null && (a['hora'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Hora: ${a['hora']}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF495057)),
                                  ),
                                ),
                              if (a['descripcion'] != null && (a['descripcion'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    a['descripcion'],
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                ),
                              if (widget.motor == 3 && (a['monto_total'] ?? 0) > 0) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _chipMonto('TOTAL', a['monto_total'], Colors.blue),
                                    _chipMonto('SEÑA', a['senha'], Colors.green),
                                    _chipMonto('SALDO', a['saldo'], Colors.orange),
                                  ],
                                ),
                              ],
                              if (a['notes'] != null && (a['notas'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '📝 ${a['notas']}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chat, color: Colors.green, size: 20),
                                    onPressed: () => _contactarCliente(a),
                                  ),
                                  if (esPendiente) ...[
                                    TextButton(
                                      onPressed: () => _cambiarEstado(a, 'completado'),
                                      child: const Text('COMPLETAR',
                                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _cambiarEstado(a, 'cancelado'),
                                      child: const Text('CANCELAR',
                                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                                    ),
                                  ],
                                  if (!esPendiente)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _eliminar(a['id']),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chipMonto(String label, dynamic valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: ${Formato.miles(valor ?? 0)}',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, letterSpacing: 0.3),
      ),
    );
  }
}