import 'package:flutter/material.dart';
import '../main.dart';
import '../services/db_service.dart';
import '../utils/formato.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});
  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _clienteCtrl = TextEditingController();
  String _fechaFiltro = '';
  List<Map<String, dynamic>> _ventas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final ventas = await DbService.instance.getVentas(
        cliente: _clienteCtrl.text, fecha: _fechaFiltro);
    
    // Escudo de seguridad por si el usuario sale de la pantalla mientras lee la DB
    if (!mounted) return;
    setState(() => _ventas = ventas);
  }

  // Método auxiliar para que las fechas ISO de la DB se vean amigables (DD/MM/YYYY)
  String _formatFecha(String fecha) {
    try {
      final d = DateTime.parse(fecha);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return fecha; // Si no es parseable, devuelve el texto original sin romper la app
    }
  }

  Future<void> _verTicket(Map<String, dynamic> venta) async {
    final items = await DbService.instance.getItemsVenta(venta['id']);
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Column(
          children: [
            const Icon(Icons.storefront, size: 36),
            Text(nombreNegocio, style: const TextStyle(fontWeight: FontWeight.bold)),
            // Formateamos la fecha del ticket para que no salga el texto ISO bruto
            Text(_formatFecha(venta['fecha']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${venta['cliente']}'),
              const Divider(),
              ...items.map((item) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item['nombre_producto']} x${item['cantidad']}')),
                      Text(Formato.miles(item['cantidad'] * item['precio_unitario'])),
                    ],
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(Formato.miles(venta['total']),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _eliminar(Map<String, dynamic> venta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: const Text('El stock será restaurado. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await DbService.instance.deleteVenta(venta['id']);
      if (!mounted) return; // Escudo por si cerró la pantalla durante el borrado
      _cargar();
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // Mantiene el formato YYYY-MM-DD requerido por tu consulta LIKE de la DB
      setState(() => _fechaFiltro =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _clienteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por cliente',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    isDense: true,
                  ),
                  onChanged: (_) => _cargar(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _seleccionarFecha,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_fechaFiltro.isEmpty ? 'Filtrar por fecha' : _fechaFiltro),
                      ),
                    ),
                    if (_fechaFiltro.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { 
                          setState(() => _fechaFiltro = ''); 
                          _cargar(); 
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _ventas.isEmpty
                ? const Center(child: Text('Sin ventas registradas'))
                : ListView.builder(
                    itemCount: _ventas.length,
                    itemBuilder: (_, i) {
                      final v = _ventas[i];
                      return ListTile(
                        title: Text(v['cliente']),
                        // Formateamos la fecha en la lista principal para una mejor visualización limpia
                        subtitle: Text(_formatFecha(v['fecha'])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(Formato.miles(v['total']),
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(Icons.receipt, color: primaryColor),
                              onPressed: () => _verTicket(v),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminar(v),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
