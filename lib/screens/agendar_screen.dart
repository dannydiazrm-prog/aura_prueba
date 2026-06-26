import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import '../services/db_service.dart';
import '../services/preferencias_service.dart';
import '../utils/formato.dart';

class AgendarScreen extends StatefulWidget {
  final String rubro;
  final int motor;
  const AgendarScreen({super.key, required this.rubro, required this.motor});
  @override
  State<AgendarScreen> createState() => _AgendarScreenState();
}

class _AgendarScreenState extends State<AgendarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profesionalCtrl = TextEditingController();
  final _clienteCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  bool _guardando = false;
  late Map<String, String> _mascaras;

  @override
  void initState() {
    super.initState();
    _mascaras = PreferenciasService.getMascaras(widget.rubro);
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _seleccionarHora() async {
    if (widget.motor != 1) return;
    final picked = await showTimePicker(context: context, initialTime: _hora);
    if (picked != null) setState(() => _hora = picked);
  }

  String get _fechaFormateada =>
      '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}';

  String get _horaFormateada =>
      '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';

  String get _mensajeWhatsApp {
    final cliente = _clienteCtrl.text.trim();
    final buffer = StringBuffer();
    buffer.write('Hola $cliente, tu turno fue agendado para el $_fechaFormateada');
    if (widget.motor == 1) {
      buffer.write(' a las $_horaFormateada');
      if (_profesionalCtrl.text.trim().isNotEmpty) {
        buffer.write(' con ${_profesionalCtrl.text.trim()}');
      }
    }
    buffer.write('.\n\nRespondé:\n1. Confirmar\n2. Cancelar\n3. Cambiar fecha/hora');
    return buffer.toString();
  }

  Future<void> _contactarCliente() async {
    await Share.share(_mensajeWhatsApp);
  }
Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final limite = await DbService.instance.limiteAlcanzado('agendamientos');
    if (limite) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Versión de prueba: límite alcanzado'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _guardando = true);

    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    final senha = double.tryParse(_senhaCtrl.text) ?? 0;

    await DbService.instance.insertAgendamiento({
      'rubro': widget.rubro,
      'motor': widget.motor,
      'profesional': _profesionalCtrl.text.trim(),
      'cliente': _clienteCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text.trim(),
      'notas': _notasCtrl.text.trim(),
      'fecha': '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}',
      'hora': widget.motor == 1 ? _horaFormateada : '',
      'estado': 'pendiente',
      'monto_total': monto,
      'senha': senha,
      'saldo': monto - senha,
    });

    setState(() => _guardando = false);
    notificarCambio();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Agendado correctamente'),
        content: const Text('¿Querés enviarle la confirmación al cliente por WhatsApp?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('CERRAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await _contactarCliente();
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('CONTACTAR CLIENTE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.motor == 2
            ? 'Nuevo pedido'
            : widget.motor == 3
                ? 'Nuevo trabajo'
                : 'Agendar'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (widget.motor == 1) ...[
                TextFormField(
                  controller: _profesionalCtrl,
                  decoration: InputDecoration(
                    labelText: _mascaras['profesional'],
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa el ${_mascaras['profesional']}'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _clienteCtrl,
                decoration: InputDecoration(
                  labelText: _mascaras['cliente'],
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Ingresa el ${_mascaras['cliente']}'
                    : null,
              ),
              const SizedBox(height: 12),
              if (widget.motor == 3) ...[
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del trabajo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa una descripción'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _montoCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Monto total',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _senhaCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Seña',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_montoCtrl.text.isNotEmpty || _senhaCtrl.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Saldo pendiente',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          Formato.miles((double.tryParse(_montoCtrl.text) ?? 0) -
                              (double.tryParse(_senhaCtrl.text) ?? 0)),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              if (widget.motor == 2) ...[
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Detalle del pedido',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa el detalle'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarFecha,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_fechaFormateada),
                    ),
                  ),
                  if (widget.motor == 1) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarHora,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(_horaFormateada),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notasCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _guardando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}