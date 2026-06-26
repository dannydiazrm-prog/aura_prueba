import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/db_service.dart';
import '../utils/formato.dart';

class NegocioScreen extends StatefulWidget {
  const NegocioScreen({super.key});
  @override
  State<NegocioScreen> createState() => _NegocioScreenState();
}

class _NegocioScreenState extends State<NegocioScreen> {
  DateTime? _desde;
  DateTime? _hasta;
  String _periodo = 'mes';

  double _saludFinanciera = 0;
  double _totalIngresos = 0;
  double _totalEgresos = 0;
  double _ingresoProductos = 0;
  double _egresoProductos = 0;
  double _costoMercaderiaVendida = 0;
  double _ingresoServicios = 0;
  double _totalRetiros = 0;
  double _totalIngresosCapital = 0;
  List<Map<String, dynamic>> _topProductos = [];
  List<Map<String, dynamic>> _topServicios = [];
  List<Map<String, dynamic>> _historial = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aplicarPeriodo('mes');
    });
  }

  void _aplicarPeriodo(String periodo) {
    final now = DateTime.now();
    setState(() {
      _periodo = periodo;
      switch (periodo) {
        case 'hoy':
          _desde = DateTime(now.year, now.month, now.day);
          _hasta = now;
          break;
        case 'semana':
          _desde = now.subtract(const Duration(days: 7));
          _hasta = now;
          break;
        case 'mes':
          _desde = DateTime(now.year, now.month, 1);
          _hasta = now;
          break;
        case 'año':
          _desde = DateTime(now.year, 1, 1);
          _hasta = now;
          break;
      }
    });
    _cargar();
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esDesde ? (_desde ?? DateTime.now()) : (_hasta ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (esDesde) {
          _desde = picked;
        } else {
          _hasta = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
        _periodo = 'custom';
      });
      _cargar();
    }
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    DateTime? hastaParaDb = _hasta;
    if (hastaParaDb != null) {
      hastaParaDb = hastaParaDb.add(const Duration(days: 1));
    }

    final datos = await DbService.instance.getDatosNegocio(
      desde: _desde,
      hasta: hastaParaDb,
    );
    final salud = await DbService.instance.getSaludFinanciera();

    if (!mounted) return;

    setState(() {
      _cargando = false;
      _saludFinanciera = salud;
      _totalIngresos = (datos['total_ingresos'] as num?)?.toDouble() ?? 0;
      _totalEgresos = (datos['total_egresos'] as num?)?.toDouble() ?? 0;
      _ingresoProductos = (datos['ingreso_productos'] as num?)?.toDouble() ?? 0;
      _egresoProductos = (datos['egreso_productos'] as num?)?.toDouble() ?? 0;
      _costoMercaderiaVendida = (datos['costo_mercaderia_vendida'] as num?)?.toDouble() ?? 0;
      _ingresoServicios = (datos['ingreso_servicios'] as num?)?.toDouble() ?? 0;
      _totalRetiros = (datos['total_retiros'] as num?)?.toDouble() ?? 0;
      _totalIngresosCapital = (datos['total_ingresos_capital'] as num?)?.toDouble() ?? 0;
      _topProductos = List<Map<String, dynamic>>.from(datos['top_productos'] ?? []);
      _topServicios = List<Map<String, dynamic>>.from(datos['top_servicios'] ?? []);
      _historial = List<Map<String, dynamic>>.from(datos['historial'] ?? []);
    });
  }

  Future<void> _retirar() async {
    final montoCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirar dinero'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [MilesInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () async {
              final monto = Formato.parseMiles(montoCtrl.text).toDouble();
              if (monto <= 0) return;
              if (monto > _saludFinanciera) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('El retiro supera el saldo disponible'),
                    backgroundColor: Colors.red,
                  ));
                }
                return;
              }
              final motivo = motivoCtrl.text.trim().isEmpty
                  ? 'Sin motivo'
                  : motivoCtrl.text.trim();
              await DbService.instance.insertRetiro(monto, motivo, tipo: 'retiro');
              if (mounted) {
                Navigator.pop(context);
                _cargar();
              }
            },
            child: const Text('Retirar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _ingresarCapital() async {
    final montoCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ingresar dinero'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [MilesInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final monto = Formato.parseMiles(montoCtrl.text).toDouble();
              if (monto <= 0) return;
              final motivo = motivoCtrl.text.trim().isEmpty
                  ? 'Capital propio'
                  : motivoCtrl.text.trim();
              await DbService.instance.insertRetiro(monto, motivo, tipo: 'ingreso_capital');
              if (mounted) {
                Navigator.pop(context);
                _cargar();
              }
            },
            child: const Text('Ingresar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatFecha(String fecha) {
    try {
      final d = DateTime.parse(fecha);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    final saludColor = _saludFinanciera >= 0 ? Colors.green : Colors.red;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi negocio'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SALUD FINANCIERA
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.grey[200]!, blurRadius: 8)
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Salud financiera',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                            Text(
                              Formato.miles(_saludFinanciera.abs()),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: saludColor,
                              ),
                            ),
                            const Text('Caja actual — no varía con los filtros',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _saludFinanciera > 0 ? _retirar : null,
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              label: const Text('Retirar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _ingresarCapital,
                              icon: const Icon(Icons.arrow_downward, size: 18),
                              label: const Text('Ingresar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // FILTROS
                  const Text('Filtros',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['hoy', 'semana', 'mes', 'año'].map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                                p[0].toUpperCase() + p.substring(1)),
                            selected: _periodo == p,
                            selectedColor: primaryColor,
                            labelStyle: TextStyle(
                                color: _periodo == p
                                    ? Colors.white
                                    : Colors.black),
                            onSelected: (_) => _aplicarPeriodo(p),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _seleccionarFecha(true),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_desde != null
                              ? '${_desde!.day}/${_desde!.month}/${_desde!.year}'
                              : 'Desde'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _seleccionarFecha(false),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(_hasta != null
                              ? '${_hasta!.day}/${_hasta!.month}/${_hasta!.year}'
                              : 'Hasta'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
				  
				         // PRODUCTOS
                  _seccionTitulo('Productos'),
                  _filaMetrica('Ingresos por ventas', _ingresoProductos,
                      Colors.green),
                  _divisor(),
                  _filaMetrica('Costo de lo vendido', _costoMercaderiaVendida,
                      Colors.red),
                  _divisor(),
                  _filaMetrica(
                    'Ganancia bruta',
                    _ingresoProductos - _costoMercaderiaVendida,
                    (_ingresoProductos - _costoMercaderiaVendida) >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  _divisor(),
                  _filaMetrica('Compras de stock (caja)', _egresoProductos,
                      Colors.orange),
                  const SizedBox(height: 16),

                  _seccionTitulo('Servicios'),
                  _filaMetrica('Ingresos por servicios', _ingresoServicios,
                      Colors.green),
                  const SizedBox(height: 16),

                  _seccionTitulo('Balance total neto'),
                  _filaMetrica(
                      'Ingresos totales', _totalIngresos, Colors.green),
                  _divisor(),
                  _filaMetrica('Egresos totales', _totalEgresos, Colors.red),
                  _divisor(),
                  _filaMetrica('Retiros', _totalRetiros, Colors.orange),
                  _divisor(),
                  _filaMetrica('Ingresos de capital', _totalIngresosCapital, Colors.green),
                  _divisor(),
                  _filaMetrica(
                    'Flujo de caja del periodo',
                    _totalIngresos + _totalIngresosCapital - _totalEgresos - _totalRetiros,
                    (_totalIngresos + _totalIngresosCapital - _totalEgresos - _totalRetiros) >= 0
                        ? Colors.green
                        : Colors.red,
                    negrita: true,
                  ),

                  const SizedBox(height: 24),

                  // ANILLOS
                  _seccionTitulo('Ingresos vs Gastos'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Builder(
                      builder: (context) {
                        if ((_totalIngresos + _totalEgresos) <= 0) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('Sin movimientos en este periodo',
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                            ),
                          );
                        }
                        final total = _totalIngresos + _totalEgresos;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _anilloMetrica('Ingresos', _totalIngresos, _totalIngresos / total, Colors.green),
                            _anilloMetrica('Egresos', _totalEgresos, _totalEgresos / total, Colors.red),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TOP PRODUCTOS
                  if (_topProductos.isNotEmpty) ...[
                    _seccionTitulo('Productos más vendidos'),
                    const SizedBox(height: 8),
                    ..._topProductos.asMap().entries.map((e) =>
                        _filaTop(e.value, e.key, _ingresoProductos)),
                    const SizedBox(height: 16),
                  ],
                  if (_topServicios.isNotEmpty) ...[
                    _seccionTitulo('Servicios más vendidos'),
                    const SizedBox(height: 8),
                    ..._topServicios.asMap().entries.map((e) =>
                        _filaTop(e.value, e.key, _ingresoServicios)),
                    const SizedBox(height: 16),
                  ],

                  // HISTORIAL
                  _seccionTitulo('Historial'),
                  const SizedBox(height: 8),
                  _historial.isEmpty
                      ? const Text('Sin movimientos',
                          style: TextStyle(color: Colors.grey))
                      : Column(
                          children: _historial.map((h) {
                            final esRetiro = h['tipo'] == 'retiro';
                            final esEgreso = h['tipo'] == 'egreso';
                            final esIngresoCapital = h['tipo'] == 'ingreso_capital';
                            final color = esRetiro
                                ? Colors.orange
                                : esEgreso
                                    ? Colors.red
                                    : Colors.green;
                            final icono = esRetiro
                                ? Icons.arrow_upward
                                : esIngresoCapital
                                    ? Icons.add_circle_outline
                                    : Icons.arrow_downward;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(icono, color: color, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(h['descripcion'] ?? '',
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                            Text(
                                                _formatFecha(
                                                    h['fecha'] ?? ''),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${esRetiro || esEgreso ? '-' : '+'}${Formato.miles(h['monto'])}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                              ],
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Text(titulo,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));
  }

  Widget _divisor() => Divider(height: 1, color: Colors.grey[200]);

  Widget _filaMetrica(String label, double valor, Color color,
      {bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      negrita ? FontWeight.bold : FontWeight.normal)),
          Text(Formato.miles(valor.abs()),
              style: TextStyle(
                  color: color,
                  fontWeight:
                      negrita ? FontWeight.bold : FontWeight.w600,
                  fontSize: negrita ? 15 : 13)),
        ],
      ),
    );
  }

  Widget _filaTop(Map<String, dynamic> item, int idx, double totalCategoria) {
    final porcentaje = totalCategoria > 0
        ? ((item['total_ingresos'] as num).toDouble() / totalCategoria * 100)
        : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text('${idx + 1}',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 12)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['nombre'],
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: porcentaje / 100,
                      backgroundColor: Colors.grey[200],
                      color: primaryColor,
                      minHeight: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('${porcentaje.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              Text(Formato.miles(item['total_ingresos']),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  Widget _leyenda(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _anilloMetrica(String label, double monto, double porcentaje, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: porcentaje),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                  );
                },
              ),
              Text('${(porcentaje * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF495057))),
        const SizedBox(height: 2),
        Text(Formato.miles(monto),
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}