import 'package:flutter/material.dart';
import '../main.dart';
import '../services/db_service.dart';
import '../utils/formato.dart';
import 'vender_screen.dart';
import 'nuevo_producto_screen.dart';
import 'stock_screen.dart';
import 'historial_screen.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final botones = [
      {'icon': Icons.shopping_cart, 'label': 'Vender', 'screen': const VenderScreen()},
      {'icon': Icons.add_box, 'label': 'Nuevo producto', 'screen': const NuevoProductoScreen()},
      {'icon': Icons.inventory, 'label': 'Stock', 'screen': const StockScreen()},
      {'icon': Icons.history, 'label': 'Historial', 'screen': const HistorialScreen()},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: botones.map((b) {
            return InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => b['screen'] as Widget)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(b['icon'] as IconData, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(b['label'] as String,
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}