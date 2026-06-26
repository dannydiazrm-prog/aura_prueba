import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/db_service.dart';
import '../utils/formato.dart';

class VenderScreen extends StatefulWidget {
  const VenderScreen({super.key});

  @override
  State<VenderScreen> createState() => _VenderScreenState();
}

class _VenderScreenState extends State<VenderScreen> {
  final _busquedaController = TextEditingController();
  final _clienteController = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];
  List<Map<String, dynamic>> _carrito = [];
  List<TextEditingController> _cantidadControllers = [];
  bool _buscando = false;

  String get _fechaHoy {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  double get _total => _carrito.fold(0.0, (s, i) => s + (i['subtotal'] as double));

  @override
  void dispose() {
    for (final c in _cantidadControllers) c.dispose();
    _busquedaController.dispose();
    _clienteController.dispose();
    super.dispose();
  }

  Future<void> _buscar(String q) async {
    if (q.isEmpty) { setState(() => _resultados = []); return; }
    setState(() => _buscando = true);
    final r = await DbService.instance.buscarProductosVenta(q);
    setState(() { _resultados = r; _buscando = false; });
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    final idx = _carrito.indexWhere((i) => i['producto_id'] == producto['id']);
    if (idx >= 0) {
      final item = _carrito[idx];
      final cantActual = item['cantidad'] as int;
      final esProducto = producto['tipo'] == 'producto';
      final stockDisp = esProducto ? (producto['stock'] as int) : 999999;
      if (esProducto && cantActual >= stockDisp) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Stock insuficiente. Disponible: ${Formato.miles(stockDisp)}'),
          backgroundColor: Colors.red,
        ));
        return;
      }
      final nueva = cantActual + 1;
      setState(() {
        _carrito[idx]['cantidad'] = nueva;
        _carrito[idx]['subtotal'] = nueva * (producto['precio_venta'] as double);
        _cantidadControllers[idx].text = '$nueva';
      });
    } else {
      final ctrl = TextEditingController(text: '1');
      setState(() {
        _carrito.add({
          'producto_id': producto['id'],
          'nombre_producto': producto['nombre'],
          'tipo': producto['tipo'],
          'cantidad': 1,
          'precio_unitario': (producto['precio_venta'] as num).toDouble(),
          'subtotal': (producto['precio_venta'] as num).toDouble(),
          'stock_disponible': producto['tipo'] == 'producto' ? producto['stock'] : 999999,
        });
        _cantidadControllers.add(ctrl);
      });
    }
    _busquedaController.clear();
    setState(() => _resultados = []);
  }

  void _cambiarCantidad(int idx, int nueva) {
    final item = _carrito[idx];
    final esProducto = item['tipo'] == 'producto';
    final stockDisp = item['stock_disponible'] as int;
    if (nueva <= 0) {
      setState(() {
        _carrito.removeAt(idx);
        _cantidadControllers[idx].dispose();
        _cantidadControllers.removeAt(idx);
      });
      return;
    }
    if (esProducto && nueva > stockDisp) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Stock insuficiente. Disponible: ${Formato.miles(stockDisp)}'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() {
      _carrito[idx]['cantidad'] = nueva;
      _carrito[idx]['subtotal'] = nueva * (item['precio_unitario'] as double);
      _cantidadControllers[idx].text = '$nueva';
    });
  }

  void _cambiarCantidadDesdeTexto(int idx, String valor) {
    final nueva = int.tryParse(valor);
    if (nueva == null || nueva <= 0) return;
    final item = _carrito[idx];
    final esProducto = item['tipo'] == 'producto';
    final stockDisp = item['stock_disponible'] as int;
    if (esProducto && nueva > stockDisp) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Stock insuficiente. Disponible: ${Formato.miles(stockDisp)}'),
        backgroundColor: Colors.red,
      ));
      setState(() => _cantidadControllers[idx].text = '${item['cantidad']}');
      return;
    }
    setState(() {
      _carrito[idx]['cantidad'] = nueva;
      _carrito[idx]['subtotal'] = nueva * (item['precio_unitario'] as double);
    });
  }

  Future<void> _guardarVenta() async {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agrega al menos un producto')));
      return;
    }

    final limite = await DbService.instance.limiteAlcanzado('ventas');
    if (limite) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Versión de prueba: límite alcanzado'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final cliente = _clienteController.text.trim().isEmpty
        ? 'Cliente ocasional'
        : _clienteController.text.trim();
    final now = DateTime.now();
    final fecha =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final ventaId = await DbService.instance.insertVenta(
        cliente, fecha, _total, _carrito);
    if (!mounted) return;
    _mostrarTicket(ventaId, cliente);
  }

  void _mostrarTicket(int ventaId, String cliente) {
    final carritoSnapshot = List<Map<String, dynamic>>.from(_carrito);
    final totalSnapshot = _total;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.storefront, color: primaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(nombreNegocio,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(_fechaHoy,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(cliente,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ]),
              const SizedBox(height: 12),
              const Divider(),
              ...carritoSnapshot.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(
                                '${item['nombre_producto']} x${item['cantidad']}',
                                style: const TextStyle(fontSize: 13))),
                        Text(Formato.miles(item['subtotal']),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(Formato.miles(totalSnapshot),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryColor)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _carrito.clear();
                for (final c in _cantidadControllers) c.dispose();
                _cantidadControllers.clear();
                _clienteController.clear();
              });
            },
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vender'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(_fechaHoy,
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _clienteController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del cliente (opcional)',
                    prefixIcon: Icon(Icons.person_outline),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _busquedaController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar producto o código',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: _buscar,
                ),
                if (_buscando) const LinearProgressIndicator(),
                if (_resultados.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _resultados.length,
                      itemBuilder: (_, i) {
                        final p = _resultados[i];
                        final esProducto = p['tipo'] == 'producto';
                        final stock = esProducto ? p['stock'] as int : null;
                        return ListTile(
                          dense: true,
                          title: Text(p['nombre'],
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                              esProducto
                                  ? 'Stock: ${Formato.miles(stock!)}'
                                  : 'Servicio',
                              style: const TextStyle(fontSize: 11)),
                          trailing: Text(Formato.miles(p['precio_venta']),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          onTap: () => _agregarAlCarrito(p),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _carrito.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text('Agrega productos al carrito',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _carrito.length,
                    itemBuilder: (_, i) {
                      final item = _carrito[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nombre_producto'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(Formato.miles(item['precio_unitario']),
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  _cambiarCantidad(i, item['cantidad'] - 1),
                            ),
                            SizedBox(
                              width: 44,
                              child: TextField(
                                controller: _cantidadControllers[i],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 6),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) =>
                                    _cambiarCantidadDesdeTexto(i, v),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  _cambiarCantidad(i, item['cantidad'] + 1),
                            ),
                            const SizedBox(width: 8),
                            Text(Formato.miles(item['subtotal']),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: primaryColor)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(Formato.miles(_total),
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _guardarVenta,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Guardar venta'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}