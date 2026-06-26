import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/db_service.dart';
import '../utils/domis_widgets.dart';
import '../utils/formato.dart';
import 'ventas_screen.dart';
import 'agendamiento_screen.dart';
import 'negocio_screen.dart';
import 'perfil_screen.dart';
import 'notas_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _ventasSemana = [];
  List<Map<String, dynamic>> _agendamientos = [];
  List<Map<String, dynamic>> _notas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
    appStateNotifier.addListener(_cargar);
  }

  @override
  void dispose() {
    appStateNotifier.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final ventas = await DbService.instance.getVentasUltimos7Dias();
    final agendamientos = await DbService.instance.getProximosAgendamientos();
    final notas = await DbService.instance.getNotas();
    if (!mounted) return;
    setState(() {
      _ventasSemana = ventas;
      _agendamientos = agendamientos;
      _notas = notas.take(3).toList();
    });
  }

  String _formatFecha(String fecha) {
    try {
      final d = DateTime.parse(fecha);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }

  double get _totalSemana =>
      _ventasSemana.fold<double>(0, (s, v) => s + (v['total'] as double));

  int get _indiceMayorVenta {
    if (_ventasSemana.isEmpty) return -1;
    var idx = 0;
    var max = _ventasSemana[0]['total'] as double;
    for (var i = 1; i < _ventasSemana.length; i++) {
      final v = _ventasSemana[i]['total'] as double;
      if (v > max) {
        max = v;
        idx = i;
      }
    }
    return max > 0 ? idx : -1;
  }

  Future<void> _abrirWhatsApp() async {
    final uri = Uri.parse('https://wa.me/595983069263');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          backgroundImage: AssetImage('assets/logo.png'),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bienvenido',
                                style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(nombreNegocio,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3)),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _abrirWhatsApp,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Comprar Aura',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    DomisNavButton(
                      icon: Icons.point_of_sale_outlined,
                      label: 'Ventas',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => VentasScreen())),
                    ),
                    DomisNavButton(
                      icon: Icons.calendar_month_outlined,
                      label: 'Agendamiento',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AgendamientoScreen())),
                    ),
                    DomisNavButton(
                      icon: Icons.store_outlined,
                      label: 'Mi negocio',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NegocioScreen())),
                    ),
                    DomisNavButton(
                      icon: Icons.person_outline,
                      label: 'Mi perfil',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PerfilScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Text('VENTAS ÚLTIMOS 7 DÍAS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Text(Formato.miles(_totalSemana),
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 24, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: Builder(
                    builder: (context) {
                      final ventasActivas = _ventasSemana
                          .where((e) => (e['total'] as double) > 0)
                          .toList();

                      if (ventasActivas.isEmpty) {
                        return const SizedBox(
                          height: 180,
                          child: Center(
                            child: Text('Sin ventas en este periodo',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final bool esPantallaGrande = constraints.maxWidth > 500;
                          final double anchoGraficos = esPantallaGrande
                              ? (constraints.maxWidth / 2) - 20
                              : constraints.maxWidth;

                          final List<Color> coloresAnillo = [
                            const Color(0xFF4DD0E1),
                            const Color(0xFFFFE082),
                            const Color(0xFFA573FF),
                            const Color(0xFF4A89F3),
                            const Color(0xFFFFB74D),
                            const Color(0xFFF06292),
                            const Color(0xFF81C784),
                          ];

                          final widgetAnillo = SizedBox(
                            height: 200,
                            width: anchoGraficos,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: ventasActivas.asMap().entries.map((e) {
                                  final double total = e.value['total'] as double;
                                  final double porcentaje = _totalSemana > 0
                                      ? (total / _totalSemana) * 100
                                      : 0;
                                  return PieChartSectionData(
                                    color: coloresAnillo[e.key % coloresAnillo.length],
                                    value: total,
                                    title: '${e.value['dia']}\n${porcentaje.toStringAsFixed(0)}%',
                                    radius: 25,
                                    titlePositionPercentageOffset: 1.8,
                                    titleStyle: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54),
                                  );
                                }).toList(),
                              ),
                            ),
                          );

                          double maxYBarras = _ventasSemana.fold(
                              0.0,
                              (max, e) => (e['total'] as double) > max
                                  ? (e['total'] as double)
                                  : max);
                          maxYBarras = maxYBarras == 0 ? 100 : maxYBarras * 1.15;

                          final widgetBarras = SizedBox(
                            height: 160,
                            width: anchoGraficos,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: maxYBarras,
                                barTouchData: BarTouchData(
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) => const Color(0xFF1A1A1A),
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        Formato.miles(rod.toY),
                                        const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 24,
                                      getTitlesWidget: (v, _) {
                                        final idx = v.toInt();
                                        if (idx < 0 || idx >= _ventasSemana.length) return const SizedBox();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(_ventasSemana[idx]['dia'],
                                              style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (_) =>
                                      FlLine(color: Colors.grey[100]!, strokeWidth: 1),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: _ventasSemana.asMap().entries.map((e) {
                                  return BarChartGroupData(
                                    x: e.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: e.value['total'] as double,
                                        color: primaryColor,
                                        width: esPantallaGrande ? 20 : 16,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );

                          return Column(
                            children: [
                              Flex(
                                direction: esPantallaGrande ? Axis.horizontal : Axis.vertical,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  widgetAnillo,
                                  if (!esPantallaGrande) const SizedBox(height: 32),
                                  widgetBarras,
                                ],
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('INGRESOS REGISTRADOS EN LA SEMANA',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54)),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PRÓXIMOS TURNOS',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AgendamientoScreen())),
                      child: Text('VER TODOS',
                          style: TextStyle(
                              fontSize: 10,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _agendamientos.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_available, color: Colors.grey[300], size: 24),
                            const SizedBox(width: 12),
                            const Text('Sin turnos próximos',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
                          ],
                        ),
                      )
                    : Column(
                        children: _agendamientos.map((a) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: const Color(0xFFE9ECEF)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: Icon(Icons.calendar_today, color: primaryColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a['cliente'] ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF212529))),
                                        const SizedBox(height: 2),
                                        Text(
                                          a['hora'] != null && (a['hora'] as String).isNotEmpty
                                              ? '${_formatFecha(a['fecha'])} • ${a['hora']}'
                                              : _formatFecha(a['fecha']),
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.zero,
                                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: const Text('PENDIENTE',
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('NOTAS RECIENTES',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NotasScreen())),
                      child: Text('VER TODAS',
                          style: TextStyle(
                              fontSize: 10,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _notas.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.sticky_note_2_outlined, color: Colors.grey[300], size: 24),
                            const SizedBox(width: 12),
                            const Text('Sin notas',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
                          ],
                        ),
                      )
                    : Column(
                        children: _notas.map((n) {
                          final titulo = (n['titulo'] as String).isNotEmpty
                              ? n['titulo'] as String
                              : (n['texto'] as String).length > 30
                                  ? '${(n['texto'] as String).substring(0, 30)}...'
                                  : n['texto'] as String;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: const Color(0xFFE9ECEF)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: const Icon(Icons.sticky_note_2_outlined,
                                        color: Colors.amber, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(titulo,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF212529))),
                                        if ((n['titulo'] as String).isNotEmpty)
                                          Text(
                                            n['texto'],
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}