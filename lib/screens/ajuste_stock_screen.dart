import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/db_service.dart';
import '../utils/formato.dart';

class AjusteStockScreen extends StatefulWidget {
  final Map<String, dynamic> producto;

  const AjusteStockScreen({super.key, required this.producto});

  @override
  State<AjusteStockScreen> createState() => _AjusteStockScreenState();
}

class _AjusteStockScreenState extends State<AjusteStockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _cantidadCorrectaCtrl = TextEditingController();
  final _cantidadPerdidaCtrl = TextEditingController();
  final _motivoOtroCtrl = TextEditingController();
  String _motivoSeleccionado = 'Rotura';
  bool _guardandoCorreccion = false;
  bool _guardandoPerdida = false;


  final List<String> _motivos = ['Rotura', 'Vencimiento', 'Robo', 'Otro'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cantidadCorrectaCtrl.text = widget.producto['stock'].toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cantidadCorrectaCtrl.dispose();
    _cantidadPerdidaCtrl.dispose();
    _motivoOtroCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCorreccion() async {
    final nuevaCantidad = int.tryParse(_cantidadCorrectaCtrl.text.trim());
    if (nuevaCantidad == null || nuevaCantidad < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ingresa una cantidad válida'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _guardandoCorreccion = true);

    await DbService.instance.corregirStockInicial(
      productoId: widget.producto['id'],
      nuevaCantidad: nuevaCantidad,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cantidad corregida'),
        backgroundColor: Colors.green));
    Navigator.pop(context, true);
  }

  Future<void> _guardarPerdida() async {
    final cantidad = int.tryParse(_cantidadPerdidaCtrl.text.trim());
    final stockActual = widget.producto['stock'] as int;

    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ingresa una cantidad válida'),
          backgroundColor: Colors.red));
      return;
    }

    if (cantidad > stockActual) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No puede ser mayor al stock actual'),
          backgroundColor: Colors.red));
      return;
    }

    final motivoFinal = _motivoSeleccionado == 'Otro'
        ? _motivoOtroCtrl.text.trim()
        : _motivoSeleccionado;

    if (motivoFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ingresa un motivo'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _guardandoPerdida = true);

    await DbService.instance.registrarPerdidaStock(
      productoId: widget.producto['id'],
      cantidad: cantidad,
      motivo: motivoFinal,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Pérdida registrada'),
        backgroundColor: Colors.green));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustar: ${widget.producto['nombre']}'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Corregir cantidad'),
            Tab(text: 'Registrar pérdida'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCorreccionTab(),
          _buildPerdidaTab(),
        ],
      ),
    );
  }

  Widget _buildCorreccionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Usa esta opción si te equivocaste al escribir la cantidad inicial de stock. El egreso registrado en caja se ajustará automáticamente.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Stock actual: ${widget.producto['stock']}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cantidadCorrectaCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Cantidad correcta',
              prefixIcon: Icon(Icons.edit_outlined, size: 18),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardandoCorreccion ? null : _guardarCorreccion,
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _guardandoCorreccion
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Guardar corrección'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerdidaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    color: Colors.orange, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Usa esta opción si el producto se rompió, venció o se perdió. El dinero ya invertido no se modifica, solo se descuenta el stock.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Stock actual: ${widget.producto['stock']}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cantidadPerdidaCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Cantidad perdida',
              prefixIcon: Icon(Icons.remove_circle_outline, size: 18),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _motivoSeleccionado,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              border: OutlineInputBorder(),
            ),
            items: _motivos
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _motivoSeleccionado = v!),
          ),
          if (_motivoSeleccionado == 'Otro') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _motivoOtroCtrl,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Detalle el motivo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardandoPerdida ? null : _guardarPerdida,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _guardandoPerdida
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Registrar pérdida'),
            ),
          ),
        ],
      ),
    );
  }
}