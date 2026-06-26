import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/db_service.dart';
import '../utils/formato.dart';

class NuevoProductoScreen extends StatefulWidget {
  const NuevoProductoScreen({super.key});
  @override
  State<NuevoProductoScreen> createState() => _NuevoProductoScreenState();
}

class _NuevoProductoScreenState extends State<NuevoProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _precioCompraCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  String _tipo = 'producto';
  bool _guardando = false;
  bool _registrarEgreso = false;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final limite = await DbService.instance.limiteAlcanzado('productos');
    if (limite) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Versión de prueba: límite alcanzado'),
        backgroundColor: Colors.red,
      ));
      setState(() => _guardando = false);
      return;
    }

    final existeNombre = await DbService.instance.existeNombreProducto(nombre);
    if (!mounted) return;
    if (existeNombre) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe un producto con ese nombre')));
      setState(() => _guardando = false);
      return;
    }

    if (codigo.isNotEmpty) {
      final existeCodigo = await DbService.instance.existeCodigoProducto(codigo);
      if (!mounted) return;
      if (existeCodigo) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya existe un producto con ese código')));
        setState(() => _guardando = false);
        return;
      }
    }

    final productoId = await DbService.instance.insertProducto({
      'codigo': codigo.isEmpty ? null : codigo,
      'nombre': nombre,
      'tipo': _tipo,
      'precio_compra': precioCompra,
      'precio_venta': precioVenta,
      'stock': stock,
    });

    if (_tipo == 'producto' && stock > 0 && precioCompra > 0 && _registrarEgreso) {
      final inversionInicial = precioCompra * stock;
      await DbService.instance.insertEgreso(
        inversionInicial,
        'STOCK INICIAL: $nombre',
        productoId: productoId,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Producto guardado'),
        backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo producto'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Producto', style: TextStyle(fontSize: 14)),
                        value: 'producto',
                        groupValue: _tipo,
                        activeColor: primaryColor,
                        onChanged: (v) => setState(() => _tipo = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Servicio', style: TextStyle(fontSize: 14)),
                        value: 'servicio',
                        groupValue: _tipo,
                        activeColor: primaryColor,
                        onChanged: (v) => setState(() => _tipo = v!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoCtrl,
                maxLength: 15,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código (opcional)',
                  prefixIcon: Icon(Icons.qr_code, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreCtrl,
                maxLength: 20,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.label_outline, size: 18),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 8),
              if (_tipo == 'producto') ...[
                TextFormField(
                  controller: _precioCompraCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MilesInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Precio de compra',
                    prefixIcon: Icon(Icons.arrow_downward, size: 18, color: Colors.red),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa precio de compra';
                    final compra = Formato.parseMiles(v);
                    final venta = Formato.parseMiles(_precioVentaCtrl.text);
                    if (venta > 0 && compra > venta) {
                      return 'No puede ser mayor al precio de venta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _precioVentaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [MilesInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Precio de venta',
                  prefixIcon: Icon(Icons.arrow_upward, size: 18, color: Colors.green),
                ),
                onChanged: (v) {
                  if (_tipo == 'producto' && _precioCompraCtrl.text.isNotEmpty) {
                    _formKey.currentState!.validate();
                  }
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingresa precio de venta' : null,
              ),
              if (_tipo == 'producto') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _stockCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Stock inicial',
                    prefixIcon: Icon(Icons.inventory_2_outlined, size: 18),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa el stock' : null,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _registrarEgreso
                        ? Colors.orange.withOpacity(0.08)
                        : Colors.grey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _registrarEgreso
                          ? Colors.orange.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Registrar como gasto en caja',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              _registrarEgreso
                                  ? 'El stock inicial se registrará como inversión en tu historial financiero.'
                                  : 'Activá esto si compraste este stock ahora. Desactivado si ya lo tenías.',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _registrarEgreso,
                        activeColor: Colors.orange,
                        onChanged: (v) => setState(() => _registrarEgreso = v),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
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
                      : const Text('Guardar producto',
                          style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}