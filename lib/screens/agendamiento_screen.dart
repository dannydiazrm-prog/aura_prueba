import 'package:flutter/material.dart';
import '../main.dart';
import '../services/preferencias_service.dart';
import 'agendar_screen.dart';
import 'agenda_screen.dart';
import 'notas_screen.dart';

class AgendamientoScreen extends StatefulWidget {
  const AgendamientoScreen({super.key});
  @override
  State<AgendamientoScreen> createState() => _AgendamientoScreenState();
}

class _AgendamientoScreenState extends State<AgendamientoScreen> {
  String _rubro = 'Otros';
  int _motor = 1;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final rubro = await PreferenciasService.getRubro();
    final motor = await PreferenciasService.getMotor();
    setState(() {
      _rubro = rubro;
      _motor = motor;
    });
  }

  String get _tituloAgendar {
    switch (_motor) {
      case 2: return 'Nuevo pedido';
      case 3: return 'Nuevo trabajo';
      default: return 'Agendar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final botones = [
      {
        'icon': Icons.add_circle_outline,
        'label': _tituloAgendar,
        'screen': AgendarScreen(rubro: _rubro, motor: _motor),
      },
      {
        'icon': Icons.sticky_note_2_outlined,
        'label': 'Notas',
        'screen': const NotasScreen(),
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Agenda',
        'screen': AgendaScreen(rubro: _rubro, motor: _motor),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Agendamiento — $_rubro'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            ...botones.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => b['screen'] as Widget)),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(b['icon'] as IconData, color: Colors.white, size: 28),
                      const SizedBox(width: 16),
                      Text(b['label'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}