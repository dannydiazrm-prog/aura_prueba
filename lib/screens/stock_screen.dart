import 'package:flutter/material.dart';
import '../main.dart';
import '../services/db_service.dart';
import '../utils/formato.dart';
import 'ajuste_stock_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _busquedaCtrl = TextEditingController();
  String? _tipoFiltro;
  String? _stockFiltro;
  int _pagina = 0;
  int _total = 0;
  List<Map<String, dynamic>> _productos = [];
  static const int _porPagina = 10;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final total = await DbService.instance.countProductosFiltrados(
        tipo: _tipoFiltro,
        busqueda: _busquedaCtrl.text,
        stockFiltro: _stockFiltro);
    final productos = await DbService.instance.getProductosPaginados(
        limit: _porPagina,
        offset: _pagina * _porPagina,
        tipo: _tipoFiltro,
        busqueda: _busquedaCtrl.text,
        stockFiltro: _stockFiltro);
    setState(() { _total = total; _productos = productos; });
  }

  Future<void> _agregarStock(Map<String, dynamic> p) async {
    final cantCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('Ingresar Stock: ${p['nombre']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se sumarán las unidades y se registrará un egreso automático en caja según su precio de compra.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: cantCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad a sumar',
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            onPressed: () async {
              final cant = int.tryParse(cantCtrl.text.trim()) ?? 0;
              if (cant <= 0) return;

              await DbService.instance.incrementarStockAutomatico(
                productoId: p['id'],
                cantidadASumar: cant,
              );

              if (mounted) {
                Navigator.pop(context);
                _cargar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stock actualizado (+${cant}) y egreso registrado'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('AGREGAR STOCK'),
          ),
        ],
      ),
    );
  }

  Future<void> _editar(Map<String, dynamic> p) async {
    final nombreCtrl = TextEditingController(text: p['nombre']);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Editar nombre'),
        content: TextFormField(
          controller: nombreCtrl,
          maxLength: 20,
          decoration: const InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            onPressed: () async {
              final nuevo = nombreCtrl.text.trim().toUpperCase();
              if (nuevo.isEmpty) return;
              if (nuevo == p['nombre']) { Navigator.pop(context); return; }
              if (await DbService.instance.existeNombreProducto(nuevo,
                  excludeId: p['id'])) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ese nombre ya existe'), backgroundColor: Colors.red));
                return;
              }
              await DbService.instance.updateProducto(p['id'], {'nombre': nuevo});
              if (mounted) { Navigator.pop(context); _cargar(); }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminar(Map<String, dynamic> p) async {
    final tieneVentas = await DbService.instance.tieneVentas(p['id']);
    if (tieneVentas) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se puede eliminar: tiene ventas registradas'), backgroundColor: Colors.red));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Eliminar producto'),
        content: Text('¿Estás seguro de eliminar ${p['nombre']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DbService.instance.deleteProducto(p['id']);
      _cargar();
    }
  }

  
    void _abrirOpciones(Map<String, dynamic> p) {
    final esProducto = p['tipo'] == 'producto';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  p['nombre'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              if (esProducto) ...[
                ListTile(
                  leading: const Icon(Icons.tune, color: Colors.blue),
                  title: const Text('Ajustar stock'),
                  subtitle: const Text('Corrige la cantidad o registra una perdida',
                      style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AjusteStockScreen(producto: p)),
                    );
                    if (result == true) _cargar();
                  },
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline, color: Colors.grey),
                title: const Text('Editar nombre'),
                onTap: () {
                  Navigator.pop(context);
                  _editar(p);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Eliminar producto'),
                onTap: () {
                  Navigator.pop(context);
                  _eliminar(p);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPaginas = (_total / _porPagina).ceil();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Stock ($_total)', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _busquedaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre o código',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  ),
                  onChanged: (_) { _pagina = 0; _cargar(); },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _tipoFiltro,
                        decoration: const InputDecoration(
                          labelText: 'Tipo', 
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: 'producto', child: Text('Productos')),
                          DropdownMenuItem(value: 'servicio', child: Text('Servicios')),
                        ],
                        onChanged: (v) {
                          setState(() => _tipoFiltro = v);
                          _pagina = 0;
                          _cargar();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _stockFiltro,
                        decoration: const InputDecoration(
                          labelText: 'Stock', 
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: 'con_stock', child: Text('Con stock')),
                          DropdownMenuItem(value: 'sin_stock', child: Text('Sin stock')),
                        ],
                        onChanged: (v) {
                          setState(() => _stockFiltro = v);
                          _pagina = 0;
                          _cargar();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _productos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text('Sin resultados',
                            style: TextStyle(
                                color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _productos.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = _productos[i];
                      final esProducto = p['tipo'] == 'producto';
                      final sinStock = esProducto && (p['stock'] as int) <= 0;
                      return InkWell(
                        onTap: () => _abrirOpciones(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(
                              color: sinStock ? Colors.red.withOpacity(0.4) : const Color(0xFFE9ECEF),
                              width: sinStock ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: esProducto
                                      ? primaryColor.withOpacity(0.1)
                                      : Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Icon(
                                  esProducto
                                      ? Icons.inventory_2_outlined
                                      : Icons.build_circle_outlined,
                                  size: 20,
                                  color: esProducto
                                      ? primaryColor
                                      : Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['nombre'],
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF212529))),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (esProducto) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: sinStock
                                                  ? Colors.red.withOpacity(0.1)
                                                  : Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.zero,
                                              border: Border.all(
                                                  color: sinStock ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              sinStock
                                                  ? 'SIN STOCK'
                                                  : 'STOCK: ${Formato.miles(p['stock'])}',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  letterSpacing: 0.5,
                                                  color: sinStock
                                                      ? Colors.red
                                                      : Colors.green,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ] else ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withOpacity(0.1),
                                              borderRadius: BorderRadius.zero,
                                              border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                            ),
                                            child: const Text('SERVICIO',
                                                style: TextStyle(
                                                    fontSize: 9,
                                                    letterSpacing: 0.5,
                                                    color: Colors.purple,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                        if (p['codigo'] != null &&
                                            (p['codigo'] as String).isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text('#${p['codigo']}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(Formato.miles(p['precio_venta']),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: primaryColor)),
                                  const SizedBox(height: 8),
                                  if (esProducto)
                                    GestureDetector(
                                      onTap: () => _agregarStock(p),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add_box, size: 14, color: Colors.green),
                                            SizedBox(width: 4),
                                            Text('STOCK',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green)),
                                          ],
                                        ),
                                      ),
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
          if (totalPaginas > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 24),
                    color: primaryColor,
                    onPressed: _pagina > 0
                        ? () { setState(() => _pagina--); _cargar(); }
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text('${_pagina + 1} / $totalPaginas',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 24),
                    color: primaryColor,
                    onPressed: _pagina < totalPaginas - 1
                        ? () { setState(() => _pagina++); _cargar(); }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}