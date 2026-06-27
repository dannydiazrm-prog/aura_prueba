import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DbService {
  static final DbService instance = DbService._();
  DbService._();

  Database? _db;

  Future<void> init() async {
    if (kIsWeb) return;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'aura_prueba.db');
    _db = await openDatabase(path, version: 1);
    await _crearTablas(_db!, 1);
    await _sembrarDatosIniciales();
	await marcarFinSiembra();
  }

  Future<void> cerrar() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Database get db {
    if (_db == null) throw Exception('Base de datos no inicializada');
    return _db!;
  }

  Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS productos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE,
        nombre TEXT UNIQUE,
        tipo TEXT,
        precio_compra REAL,
        precio_venta REAL,
        stock INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS retiros(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monto REAL,
        motivo TEXT,
        fecha TEXT,
        tipo TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente TEXT,
        fecha TEXT,
        total REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS venta_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER,
        producto_id INTEGER,
        nombre_producto TEXT,
        cantidad INTEGER,
        precio_unitario REAL,
        precio_costo_unitario REAL,
        FOREIGN KEY (venta_id) REFERENCES ventas(id),
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS agendamientos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rubro TEXT,
        motor INTEGER,
        profesional TEXT,
        cliente TEXT,
        descripcion TEXT,
        notas TEXT,
        fecha TEXT,
        hora TEXT,
        estado TEXT,
        monto_total REAL,
        senha REAL,
        saldo REAL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        texto TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS egresos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        concepto TEXT,
        monto REAL,
        fecha TEXT,
        tipo TEXT,
        producto_id INTEGER,
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS perdidas_stock(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER,
        cantidad INTEGER,
        motivo TEXT,
        fecha TEXT,
        FOREIGN KEY (producto_id) REFERENCES productos(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS demo_meta(
        clave TEXT PRIMARY KEY,
        valor TEXT
      )
    ''');
  }

  Future<void> _sembrarDatosIniciales() async {
    final check = await db.query('demo_meta',
        where: 'clave = ?', whereArgs: ['sembrado']);
    if (check.isNotEmpty) return;

    final now = DateTime.now();

    final productos = [
      {'codigo': 'MED001', 'nombre': 'Amoxicilina 500mg', 'tipo': 'producto', 'precio_compra': 8000.0, 'precio_venta': 15000.0, 'stock': 45},
      {'codigo': 'MED002', 'nombre': 'Ivermectina 1%', 'tipo': 'producto', 'precio_compra': 12000.0, 'precio_venta': 22000.0, 'stock': 30},
      {'codigo': 'MED003', 'nombre': 'Frontline Spray', 'tipo': 'producto', 'precio_compra': 35000.0, 'precio_venta': 58000.0, 'stock': 18},
      {'codigo': 'ALI001', 'nombre': 'Royal Canin Adulto 3kg', 'tipo': 'producto', 'precio_compra': 85000.0, 'precio_venta': 130000.0, 'stock': 22},
      {'codigo': 'ALI002', 'nombre': 'Pedigree Cachorro 1kg', 'tipo': 'producto', 'precio_compra': 28000.0, 'precio_venta': 45000.0, 'stock': 35},
      {'codigo': 'ACC001', 'nombre': 'Collar antipulgas', 'tipo': 'producto', 'precio_compra': 15000.0, 'precio_venta': 28000.0, 'stock': 25},
      {'codigo': 'ACC002', 'nombre': 'Shampoo medicado 250ml', 'tipo': 'producto', 'precio_compra': 18000.0, 'precio_venta': 32000.0, 'stock': 20},
      {'codigo': 'SRV001', 'nombre': 'Consulta general', 'tipo': 'servicio', 'precio_compra': 0.0, 'precio_venta': 80000.0, 'stock': 0},
      {'codigo': 'SRV002', 'nombre': 'Baño y corte canino', 'tipo': 'servicio', 'precio_compra': 0.0, 'precio_venta': 65000.0, 'stock': 0},
      {'codigo': 'SRV003', 'nombre': 'Vacuna antirrábica', 'tipo': 'servicio', 'precio_compra': 0.0, 'precio_venta': 95000.0, 'stock': 0},
      {'codigo': 'SRV004', 'nombre': 'Castración canina', 'tipo': 'servicio', 'precio_compra': 0.0, 'precio_venta': 450000.0, 'stock': 0},
      {'codigo': 'SRV005', 'nombre': 'Desparasitación interna', 'tipo': 'servicio', 'precio_compra': 0.0, 'precio_venta': 55000.0, 'stock': 0},
    ];

    final idsProductos = <String, int>{};
    for (final p in productos) {
      final id = await db.insert('productos', p);
      idsProductos[p['codigo'] as String] = id;
    }

    final clientes = ['López, María', 'González, Juan', 'Rodríguez, Ana', 'Martínez, Carlos', 'Pérez, Laura', 'Díaz, Roberto', 'García, Sofía', 'Romero, Diego'];

    final ventasSemilla = [
      {'dias': 175, 'cliente': clientes[0], 'items': [{'codigo': 'SRV001', 'cantidad': 1}, {'codigo': 'MED001', 'cantidad': 2}]},
      {'dias': 170, 'cliente': clientes[1], 'items': [{'codigo': 'ALI001', 'cantidad': 1}, {'codigo': 'ACC001', 'cantidad': 1}]},
      {'dias': 165, 'cliente': clientes[2], 'items': [{'codigo': 'SRV003', 'cantidad': 1}]},
      {'dias': 160, 'cliente': clientes[3], 'items': [{'codigo': 'SRV002', 'cantidad': 1}, {'codigo': 'ACC002', 'cantidad': 1}]},
      {'dias': 155, 'cliente': clientes[4], 'items': [{'codigo': 'MED002', 'cantidad': 1}, {'codigo': 'MED003', 'cantidad': 1}]},
      {'dias': 148, 'cliente': clientes[5], 'items': [{'codigo': 'SRV004', 'cantidad': 1}]},
      {'dias': 143, 'cliente': clientes[0], 'items': [{'codigo': 'ALI002', 'cantidad': 2}]},
      {'dias': 138, 'cliente': clientes[6], 'items': [{'codigo': 'SRV001', 'cantidad': 1}, {'codigo': 'SRV005', 'cantidad': 1}]},
      {'dias': 132, 'cliente': clientes[1], 'items': [{'codigo': 'MED001', 'cantidad': 3}, {'codigo': 'ACC001', 'cantidad': 1}]},
      {'dias': 125, 'cliente': clientes[7], 'items': [{'codigo': 'SRV002', 'cantidad': 1}]},
      {'dias': 120, 'cliente': clientes[2], 'items': [{'codigo': 'ALI001', 'cantidad': 2}]},
      {'dias': 115, 'cliente': clientes[3], 'items': [{'codigo': 'SRV003', 'cantidad': 1}, {'codigo': 'MED002', 'cantidad': 1}]},
      {'dias': 110, 'cliente': clientes[4], 'items': [{'codigo': 'SRV001', 'cantidad': 1}]},
      {'dias': 105, 'cliente': clientes[5], 'items': [{'codigo': 'ACC002', 'cantidad': 2}, {'codigo': 'ALI002', 'cantidad': 1}]},
      {'dias': 98,  'cliente': clientes[6], 'items': [{'codigo': 'SRV004', 'cantidad': 1}]},
      {'dias': 92,  'cliente': clientes[0], 'items': [{'codigo': 'SRV005', 'cantidad': 1}, {'codigo': 'MED001', 'cantidad': 1}]},
      {'dias': 85,  'cliente': clientes[7], 'items': [{'codigo': 'SRV001', 'cantidad': 1}, {'codigo': 'ALI001', 'cantidad': 1}]},
      {'dias': 78,  'cliente': clientes[1], 'items': [{'codigo': 'MED003', 'cantidad': 1}]},
      {'dias': 72,  'cliente': clientes[2], 'items': [{'codigo': 'SRV002', 'cantidad': 1}, {'codigo': 'ACC001', 'cantidad': 1}]},
      {'dias': 65,  'cliente': clientes[3], 'items': [{'codigo': 'SRV003', 'cantidad': 1}]},
      {'dias': 58,  'cliente': clientes[4], 'items': [{'codigo': 'ALI002', 'cantidad': 3}]},
      {'dias': 52,  'cliente': clientes[5], 'items': [{'codigo': 'SRV001', 'cantidad': 1}, {'codigo': 'MED002', 'cantidad': 2}]},
      {'dias': 45,  'cliente': clientes[6], 'items': [{'codigo': 'SRV004', 'cantidad': 1}]},
      {'dias': 38,  'cliente': clientes[7], 'items': [{'codigo': 'ACC002', 'cantidad': 1}, {'codigo': 'ALI001', 'cantidad': 1}]},
      {'dias': 32,  'cliente': clientes[0], 'items': [{'codigo': 'SRV005', 'cantidad': 1}, {'codigo': 'MED001', 'cantidad': 2}]},
      {'dias': 25,  'cliente': clientes[1], 'items': [{'codigo': 'SRV002', 'cantidad': 1}]},
      {'dias': 18,  'cliente': clientes[2], 'items': [{'codigo': 'SRV001', 'cantidad': 1}, {'codigo': 'SRV003', 'cantidad': 1}]},
      {'dias': 12,  'cliente': clientes[3], 'items': [{'codigo': 'ALI001', 'cantidad': 1}, {'codigo': 'ALI002', 'cantidad': 2}]},
      {'dias': 6,   'cliente': clientes[4], 'items': [{'codigo': 'SRV001', 'cantidad': 1}, {'codigo': 'MED003', 'cantidad': 1}]},
      {'dias': 2,   'cliente': clientes[5], 'items': [{'codigo': 'SRV004', 'cantidad': 1}]},
    ];

    for (final venta in ventasSemilla) {
      final fecha = now.subtract(Duration(days: venta['dias'] as int));
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      double total = 0;
      final itemsInsert = <Map<String, dynamic>>[];

      for (final item in venta['items'] as List) {
        final codigo = item['codigo'] as String;
        final cantidad = item['cantidad'] as int;
        final prod = productos.firstWhere((p) => p['codigo'] == codigo, orElse: () => {});
        if (prod.isEmpty) continue;
        final precio = prod['precio_venta'] as double;
        final costo = prod['precio_compra'] as double;
        total += precio * cantidad;
        itemsInsert.add({
          'producto_id': idsProductos[codigo],
          'nombre_producto': prod['nombre'],
          'cantidad': cantidad,
          'precio_unitario': precio,
          'precio_costo_unitario': costo,
          'tipo': prod['tipo'],
        });
      }

      await insertVenta(venta['cliente'] as String, fechaStr, total, itemsInsert);
    }

    final egresos = [
      {'dias': 172, 'concepto': 'Compra medicamentos varios', 'monto': 120000.0},
      {'dias': 145, 'concepto': 'Reposición alimentos balanceados', 'monto': 280000.0},
      {'dias': 118, 'concepto': 'Materiales de cirugía', 'monto': 95000.0},
      {'dias': 90,  'concepto': 'Compra accesorios y collares', 'monto': 75000.0},
      {'dias': 62,  'concepto': 'Reposición medicamentos', 'monto': 180000.0},
      {'dias': 35,  'concepto': 'Compra shampoos y productos de higiene', 'monto': 88000.0},
      {'dias': 10,  'concepto': 'Reposición alimentos premium', 'monto': 210000.0},
    ];

    for (final e in egresos) {
      final fecha = now.subtract(Duration(days: e['dias'] as int));
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      await db.insert('egresos', {
        'concepto': e['concepto'],
        'monto': e['monto'],
        'fecha': fechaStr,
        'tipo': 'compra_stock',
        'producto_id': null,
      });
    }

    final agendamientos = [
      {'dias': -3, 'cliente': clientes[0], 'descripcion': 'Baño y corte', 'profesional': 'Dr. Méndez', 'estado': 'pendiente', 'monto': 65000.0, 'hora': '09:00'},
      {'dias': -1, 'cliente': clientes[1], 'descripcion': 'Consulta general', 'profesional': 'Dra. Vega', 'estado': 'pendiente', 'monto': 80000.0, 'hora': '10:30'},
      {'dias': -1, 'cliente': clientes[2], 'descripcion': 'Vacuna antirrábica', 'profesional': 'Dr. Méndez', 'estado': 'pendiente', 'monto': 95000.0, 'hora': '14:00'},
      {'dias': 5,  'cliente': clientes[3], 'descripcion': 'Castración canina', 'profesional': 'Dra. Vega', 'estado': 'pendiente', 'monto': 450000.0, 'hora': '08:00'},
      {'dias': 30, 'cliente': clientes[4], 'descripcion': 'Desparasitación', 'profesional': 'Dr. Méndez', 'estado': 'pendiente', 'monto': 55000.0, 'hora': '11:00'},
      {'dias': 60, 'cliente': clientes[5], 'descripcion': 'Control posoperatorio', 'profesional': 'Dra. Vega', 'estado': 'pendiente', 'monto': 80000.0, 'hora': '15:30'},
      {'dias': 20, 'cliente': clientes[6], 'descripcion': 'Baño medicado', 'profesional': 'Dr. Méndez', 'estado': 'completado', 'monto': 65000.0, 'hora': '09:00'},
      {'dias': 50, 'cliente': clientes[7], 'descripcion': 'Consulta urgencia', 'profesional': 'Dra. Vega', 'estado': 'completado', 'monto': 80000.0, 'hora': '16:00'},
    ];

    for (final a in agendamientos) {
      final fecha = now.subtract(Duration(days: -(a['dias'] as int)));
      final fechaStr = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      await db.insert('agendamientos', {
        'rubro': 'Veterinaria',
        'motor': 1,
        'profesional': a['profesional'],
        'cliente': a['cliente'],
        'descripcion': a['descripcion'],
        'notas': '',
        'fecha': fechaStr,
        'hora': a['hora'],
        'estado': a['estado'],
        'monto_total': a['monto'],
        'senha': 0.0,
        'saldo': a['monto'],
      });
    }

    final notas = [
      {'titulo': 'Recordatorio vacunas febrero', 'texto': 'Llamar a clientes con vacunas vencidas este mes. Revisar lista de López y González.'},
      {'titulo': 'Proveedor medicamentos', 'texto': 'Contactar a Farmavet para renovar contrato. Descuento del 10% por volumen si se supera Gs. 500.000 mensual.'},
      {'titulo': 'Horario especial semana santa', 'texto': 'Lunes y martes normales. Miércoles hasta las 13hs. Jueves y viernes cerrado. Guardia de urgencias disponible.'},
    ];

    for (final n in notas) {
      await db.insert('notas', n);
    }

    await db.insert('retiros', {
      'monto': 200000.0,
      'motivo': 'Retiro personal',
      'fecha': now.subtract(const Duration(days: 90)).toIso8601String().substring(0, 10),
      'tipo': 'retiro',
    });
    await db.insert('retiros', {
      'monto': 150000.0,
      'motivo': 'Retiro personal',
      'fecha': now.subtract(const Duration(days: 45)).toIso8601String().substring(0, 10),
      'tipo': 'retiro',
    });

    await db.insert('demo_meta', {'clave': 'sembrado', 'valor': '1'});
  }

  Future<int> contarNuevos(String tabla) async {
    final meta = await db.query('demo_meta',
        where: 'clave = ?', whereArgs: ['max_id_$tabla']);
    final maxId = meta.isEmpty ? 0 : int.tryParse(meta.first['valor'] as String) ?? 0;
    final result = await db.rawQuery(
        'SELECT COUNT(*) FROM $tabla WHERE id > ?', [maxId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> limiteAlcanzado(String tabla) async {
    final count = await contarNuevos(tabla);
    return count >= 3;
  }

  Future<void> _guardarMaxIdSemilla(String tabla) async {
    final result = await db.rawQuery('SELECT MAX(id) FROM $tabla');
    final maxId = Sqflite.firstIntValue(result) ?? 0;
    await db.insert('demo_meta', {'clave': 'max_id_$tabla', 'valor': maxId.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> marcarFinSiembra() async {
    for (final tabla in ['productos', 'ventas', 'agendamientos', 'notas']) {
      await _guardarMaxIdSemilla(tabla);
    }
  }

  Future<int> insertProducto(Map<String, dynamic> p) async =>
      await db.insert('productos', p);

  Future<List<Map<String, dynamic>>> getProductos() async =>
      await db.query('productos', orderBy: 'nombre ASC');

  Future<List<Map<String, dynamic>>> getProductosPaginados(
      {int limit = 10, int offset = 0, String? tipo, String? busqueda, String? stockFiltro}) async {
    String where = '1=1';
    List<dynamic> args = [];
    if (tipo != null) { where += ' AND tipo = ?'; args.add(tipo); }
    if (busqueda != null && busqueda.isNotEmpty) {
      where += ' AND (UPPER(nombre) LIKE ? OR UPPER(codigo) LIKE ?)';
      args.addAll(['%${busqueda.toUpperCase()}%', '%${busqueda.toUpperCase()}%']);
    }
    if (stockFiltro == 'con_stock') { where += ' AND (tipo = "servicio" OR stock > 0)'; }
    if (stockFiltro == 'sin_stock') { where += ' AND tipo = "producto" AND stock = 0'; }
    return await db.query('productos', where: where, whereArgs: args,
        orderBy: 'nombre ASC', limit: limit, offset: offset);
  }

  Future<int> countProductosFiltrados({String? tipo, String? busqueda, String? stockFiltro}) async {
    String where = '1=1';
    List<dynamic> args = [];
    if (tipo != null) { where += ' AND tipo = ?'; args.add(tipo); }
    if (busqueda != null && busqueda.isNotEmpty) {
      where += ' AND (UPPER(nombre) LIKE ? OR UPPER(codigo) LIKE ?)';
      args.addAll(['%${busqueda.toUpperCase()}%', '%${busqueda.toUpperCase()}%']);
    }
    if (stockFiltro == 'con_stock') { where += ' AND (tipo = "servicio" OR stock > 0)'; }
    if (stockFiltro == 'sin_stock') { where += ' AND tipo = "producto" AND stock = 0'; }
    final result = await db.rawQuery('SELECT COUNT(*) FROM productos WHERE $where', args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> existeNombreProducto(String nombre, {int? excludeId}) async {
    String where = 'UPPER(nombre) = ?';
    List<dynamic> args = [nombre.toUpperCase()];
    if (excludeId != null) { where += ' AND id != ?'; args.add(excludeId); }
    final r = await db.query('productos', where: where, whereArgs: args);
    return r.isNotEmpty;
  }

  Future<bool> existeCodigoProducto(String codigo, {int? excludeId}) async {
    String where = 'UPPER(codigo) = ?';
    List<dynamic> args = [codigo.toUpperCase()];
    if (excludeId != null) { where += ' AND id != ?'; args.add(excludeId); }
    final r = await db.query('productos', where: where, whereArgs: args);
    return r.isNotEmpty;
  }

  Future<int> updateProducto(int id, Map<String, dynamic> p) async =>
      await db.update('productos', p, where: 'id = ?', whereArgs: [id]);

  Future<bool> tieneVentas(int productoId) async {
    final r = await db.query('venta_items', where: 'producto_id = ?', whereArgs: [productoId]);
    return r.isNotEmpty;
  }

  Future<int> deleteProducto(int id) async =>
      await db.delete('productos', where: 'id = ?', whereArgs: [id]);

  Future<List<Map<String, dynamic>>> buscarProductosVenta(String query) async {
    return await db.query('productos',
        where: 'UPPER(nombre) LIKE ? OR UPPER(codigo) LIKE ?',
        whereArgs: ['%${query.toUpperCase()}%', '%${query.toUpperCase()}%'],
        orderBy: 'nombre ASC');
  }

  Future<void> actualizarStock(int productoId, int cantidad) async {
    await db.rawUpdate(
        'UPDATE productos SET stock = stock - ? WHERE id = ? AND tipo = "producto"',
        [cantidad, productoId]);
  }

  Future<void> restaurarStock(int ventaId) async {
    final items = await db.query('venta_items', where: 'venta_id = ?', whereArgs: [ventaId]);
    for (final item in items) {
      final pid = item['producto_id'] as int;
      final cantidad = item['cantidad'] as int;
      await db.rawUpdate(
          'UPDATE productos SET stock = stock + ? WHERE id = ? AND tipo = "producto"',
          [cantidad, pid]);
    }
  }

  Future<int> insertVenta(String cliente, String fecha, double total,
      List<Map<String, dynamic>> items) async {
    int ventaId = 0;
    await db.transaction((txn) async {
      ventaId = await txn.insert('ventas', {
        'cliente': cliente,
        'fecha': fecha,
        'total': total,
      });
      for (final item in items) {
        final tipo = item['tipo'];
        double precioCosto = 0;
        if (tipo == 'producto') {
          final prod = await txn.query('productos',
              columns: ['precio_compra'],
              where: 'id = ?',
              whereArgs: [item['producto_id']]);
          if (prod.isNotEmpty) {
            precioCosto = (prod.first['precio_compra'] as num).toDouble();
          }
        }
        await txn.insert('venta_items', {
          'venta_id': ventaId,
          'producto_id': item['producto_id'],
          'nombre_producto': item['nombre_producto'],
          'cantidad': item['cantidad'],
          'precio_unitario': item['precio_unitario'],
          'precio_costo_unitario': precioCosto,
        });
        if (tipo == 'producto') {
          await txn.rawUpdate(
              'UPDATE productos SET stock = stock - ? WHERE id = ?',
              [item['cantidad'], item['producto_id']]);
        }
      }
    });
    return ventaId;
  }

  Future<List<Map<String, dynamic>>> getVentas({String? cliente, String? fecha, int limit = 50}) async {
    String where = '1=1';
    List<dynamic> args = [];
    if (cliente != null && cliente.isNotEmpty) {
      where += ' AND UPPER(cliente) LIKE ?';
      args.add('%${cliente.toUpperCase()}%');
    }
    if (fecha != null && fecha.isNotEmpty) {
      where += ' AND fecha LIKE ?';
      args.add('$fecha%');
    }
    return await db.query('ventas', where: where, whereArgs: args,
        orderBy: 'id DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getItemsVenta(int ventaId) async =>
      await db.query('venta_items', where: 'venta_id = ?', whereArgs: [ventaId]);

  Future<void> deleteVenta(int ventaId) async {
    await db.transaction((txn) async {
      final items = await txn.query('venta_items', where: 'venta_id = ?', whereArgs: [ventaId]);
      for (final item in items) {
        final pid = item['producto_id'] as int;
        final cantidad = item['cantidad'] as int;
        final prod = await txn.query('productos', columns: ['tipo'], where: 'id = ?', whereArgs: [pid]);
        if (prod.isNotEmpty && prod.first['tipo'] == 'producto') {
          await txn.rawUpdate(
              'UPDATE productos SET stock = stock + ? WHERE id = ?',
              [cantidad, pid]);
        }
      }
      await txn.delete('venta_items', where: 'venta_id = ?', whereArgs: [ventaId]);
      await txn.delete('ventas', where: 'id = ?', whereArgs: [ventaId]);
    });
  }

  Future<void> insertRetiro(double monto, String motivo, {String tipo = 'retiro'}) async {
    final now = DateTime.now();
    await db.insert('retiros', {
      'monto': monto,
      'motivo': motivo,
      'fecha': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'tipo': tipo,
    });
  }

  Future<int> insertEgreso(double monto, String concepto, {int? productoId}) async {
    return await db.insert('egresos', {
      'concepto': concepto,
      'monto': monto,
      'fecha': DateTime.now().toIso8601String(),
      'tipo': 'compra_stock',
      'producto_id': productoId,
    });
  }

  Future<void> corregirStockInicial({required int productoId, required int nuevaCantidad}) async {
    final res = await db.query('productos', where: 'id = ?', whereArgs: [productoId]);
    if (res.isEmpty) return;
    final producto = res.first;
    final double precioCompra = (producto['precio_compra'] as num).toDouble();
    final egresoExistente = await db.query('egresos',
        where: 'producto_id = ? AND tipo = ?',
        whereArgs: [productoId, 'compra_stock'],
        orderBy: 'id ASC', limit: 1);
    final double nuevoMonto = precioCompra * nuevaCantidad;
    await db.transaction((txn) async {
      await txn.update('productos', {'stock': nuevaCantidad},
          where: 'id = ?', whereArgs: [productoId]);
      if (egresoExistente.isNotEmpty) {
        await txn.update('egresos', {'monto': nuevoMonto},
            where: 'id = ?', whereArgs: [egresoExistente.first['id']]);
      } else {
        await txn.insert('egresos', {
          'concepto': 'STOCK INICIAL: ${producto['nombre']}',
          'monto': nuevoMonto,
          'fecha': DateTime.now().toIso8601String(),
          'tipo': 'compra_stock',
          'producto_id': productoId,
        });
      }
    });
  }

  Future<void> registrarPerdidaStock({
    required int productoId,
    required int cantidad,
    required String motivo,
  }) async {
    final res = await db.query('productos', where: 'id = ?', whereArgs: [productoId]);
    if (res.isEmpty) return;
    final stockActual = res.first['stock'] as int;
    final nuevoStock = (stockActual - cantidad).clamp(0, stockActual);
    await db.transaction((txn) async {
      await txn.update('productos', {'stock': nuevoStock},
          where: 'id = ?', whereArgs: [productoId]);
      await txn.insert('perdidas_stock', {
        'producto_id': productoId,
        'cantidad': cantidad,
        'motivo': motivo,
        'fecha': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<double> getSaludFinanciera() async {
    final ingresos = await db.rawQuery('SELECT COALESCE(SUM(total), 0) AS total FROM ventas');
    final egresos = await db.rawQuery('SELECT COALESCE(SUM(monto), 0) AS total FROM egresos');
    final retiros = await db.rawQuery('SELECT COALESCE(SUM(monto), 0) AS total FROM retiros WHERE tipo = "retiro"');
    final ingresosCapital = await db.rawQuery('SELECT COALESCE(SUM(monto), 0) AS total FROM retiros WHERE tipo = "ingreso_capital"');
    final i = (ingresos.first['total'] as num).toDouble();
    final e = (egresos.first['total'] as num).toDouble();
    final r = (retiros.first['total'] as num).toDouble();
    final ic = (ingresosCapital.first['total'] as num).toDouble();
    return i + ic - e - r;
  }

  Future<Map<String, dynamic>> getDatosNegocio({DateTime? desde, DateTime? hasta}) async {
    String whereVentas = '1=1';
    List<dynamic> args = [];
    if (desde != null) {
      whereVentas += ' AND v.fecha >= ?';
      args.add(desde.toIso8601String().substring(0, 10));
    }
    if (hasta != null) {
      whereVentas += ' AND v.fecha <= ?';
      args.add(hasta.toIso8601String().substring(0, 10));
    }

    final ingresosProductos = await db.rawQuery('''
      SELECT COALESCE(SUM(vi.cantidad * vi.precio_unitario), 0) AS total
      FROM venta_items vi JOIN ventas v ON vi.venta_id = v.id
      JOIN productos p ON vi.producto_id = p.id
      WHERE p.tipo = "producto" AND $whereVentas
    ''', args);

    final costoMercaderiaVendida = await db.rawQuery('''
      SELECT COALESCE(SUM(vi.cantidad * vi.precio_costo_unitario), 0) AS total
      FROM venta_items vi JOIN ventas v ON vi.venta_id = v.id
      JOIN productos p ON vi.producto_id = p.id
      WHERE p.tipo = "producto" AND $whereVentas
    ''', args);

    String whereEgresos = '1=1';
    List<dynamic> argsEgresos = [];
    if (desde != null) { whereEgresos += ' AND fecha >= ?'; argsEgresos.add(desde.toIso8601String().substring(0, 10)); }
    if (hasta != null) { whereEgresos += ' AND fecha <= ?'; argsEgresos.add(hasta.toIso8601String().substring(0, 10)); }

    final egresosProductos = await db.rawQuery('''
      SELECT COALESCE(SUM(monto), 0) AS total FROM egresos WHERE $whereEgresos
    ''', argsEgresos);

    final ingresosServicios = await db.rawQuery('''
      SELECT COALESCE(SUM(vi.cantidad * vi.precio_unitario), 0) AS total
      FROM venta_items vi JOIN ventas v ON vi.venta_id = v.id
      JOIN productos p ON vi.producto_id = p.id
      WHERE p.tipo = "servicio" AND $whereVentas
    ''', args);

    final topProductos = await db.rawQuery('''
      SELECT p.nombre, SUM(vi.cantidad * vi.precio_unitario) AS total_ingresos
      FROM venta_items vi JOIN ventas v ON vi.venta_id = v.id
      JOIN productos p ON vi.producto_id = p.id
      WHERE p.tipo = "producto" AND $whereVentas
      GROUP BY p.id ORDER BY total_ingresos DESC LIMIT 5
    ''', args);

    final topServicios = await db.rawQuery('''
      SELECT p.nombre, SUM(vi.cantidad * vi.precio_unitario) AS total_ingresos
      FROM venta_items vi JOIN ventas v ON vi.venta_id = v.id
      JOIN productos p ON vi.producto_id = p.id
      WHERE p.tipo = "servicio" AND $whereVentas
      GROUP BY p.id ORDER BY total_ingresos DESC LIMIT 5
    ''', args);

    final ip = (ingresosProductos.first['total'] as num).toDouble();
    final ep = (egresosProductos.first['total'] as num).toDouble();
    final is_ = (ingresosServicios.first['total'] as num).toDouble();
    final cmv = (costoMercaderiaVendida.first['total'] as num).toDouble();

    String agrupador;
    String agrupadorEgresos;
    if (desde != null && hasta != null) {
      final dias = hasta.difference(desde).inDays;
      if (dias > 60) {
        agrupador = "strftime('%Y-%m', v.fecha)";
        agrupadorEgresos = "strftime('%Y-%m', fecha)";
      } else if (dias > 14) {
        agrupador = "strftime('%Y-%W', v.fecha)";
        agrupadorEgresos = "strftime('%Y-%W', fecha)";
      } else {
        agrupador = 'v.fecha';
        agrupadorEgresos = 'fecha';
      }
    } else {
      agrupador = 'v.fecha';
      agrupadorEgresos = 'fecha';
    }

    final ventasPorDia = await db.rawQuery('''
      SELECT $agrupador AS periodo, MIN(v.fecha) AS fecha_ref, SUM(v.total) AS ingresos
      FROM ventas v WHERE $whereVentas
      GROUP BY periodo ORDER BY periodo ASC
    ''', args);

    final egresosPorPeriodo = await db.rawQuery('''
      SELECT $agrupadorEgresos AS periodo, MIN(fecha) AS fecha_ref, SUM(monto) AS egresos
      FROM egresos WHERE $whereEgresos
      GROUP BY periodo ORDER BY periodo ASC
    ''', argsEgresos);

    final mapaEgresos = <String, double>{};
    for (final row in egresosPorPeriodo) {
      mapaEgresos[row['periodo'] as String] = (row['egresos'] as num).toDouble();
    }

    final spots_i = <Map<String, double>>[];
    final spots_e = <Map<String, double>>[];
    final labels = <String>[];
    for (int i = 0; i < ventasPorDia.length; i++) {
      final row = ventasPorDia[i];
      final periodo = row['periodo'] as String;
      spots_i.add({'x': i.toDouble(), 'y': (row['ingresos'] as num).toDouble()});
      spots_e.add({'x': i.toDouble(), 'y': mapaEgresos[periodo] ?? 0.0});
      final fechaRef = row['fecha_ref'] as String;
      labels.add('${fechaRef.substring(8)}/${fechaRef.substring(5, 7)}');
    }

    String whereRetiros = '1=1';
    List<dynamic> argsR = [];
    if (desde != null) { whereRetiros += ' AND fecha >= ?'; argsR.add(desde.toIso8601String().substring(0, 10)); }
    if (hasta != null) { whereRetiros += ' AND fecha <= ?'; argsR.add(hasta.toIso8601String().substring(0, 10)); }

    final retiros = await db.rawQuery(
        'SELECT monto, motivo AS descripcion, fecha, "retiro" AS tipo FROM retiros WHERE tipo = "retiro" AND $whereRetiros ORDER BY fecha DESC', argsR);
    final ingresosCapitalHist = await db.rawQuery(
        'SELECT monto, motivo AS descripcion, fecha, "ingreso_capital" AS tipo FROM retiros WHERE tipo = "ingreso_capital" AND $whereRetiros ORDER BY fecha DESC', argsR);
    final ventasHist = await db.rawQuery('''
      SELECT v.total AS monto, "Venta #"||v.id AS descripcion, v.fecha, "ingreso" AS tipo
      FROM ventas v WHERE $whereVentas ORDER BY v.fecha DESC
    ''', args);
    final egresosHist = await db.rawQuery('''
      SELECT monto, concepto AS descripcion, fecha, "egreso" AS tipo
      FROM egresos WHERE $whereEgresos ORDER BY fecha DESC
    ''', argsEgresos);

    final historial = [...retiros, ...ingresosCapitalHist, ...ventasHist, ...egresosHist];
    historial.sort((a, b) => (b['fecha'] as String).compareTo(a['fecha'] as String));

    final totalRetiros = retiros.fold<double>(0, (s, r) => s + (r['monto'] as num).toDouble());
    final totalIngresosCapital = ingresosCapitalHist.fold<double>(0, (s, r) => s + (r['monto'] as num).toDouble());

    return {
      'ingreso_productos': ip,
      'egreso_productos': ep,
      'ingreso_servicios': is_,
      'costo_mercaderia_vendida': cmv,
      'total_ingresos': ip + is_,
      'total_egresos': ep,
      'total_retiros': totalRetiros,
      'total_ingresos_capital': totalIngresosCapital,
      'top_productos': topProductos.map((e) => Map<String, dynamic>.from(e)).toList(),
      'top_servicios': topServicios.map((e) => Map<String, dynamic>.from(e)).toList(),
      'historial': historial.map((e) => Map<String, dynamic>.from(e)).toList(),
      'spots_ingresos': spots_i,
      'spots_egresos': spots_e,
      'labels_grafico': labels,
    };
  }

  Future<int> insertAgendamiento(Map<String, dynamic> a) async =>
      await db.insert('agendamientos', a);

  Future<List<Map<String, dynamic>>> getAgendamientos({String? estado}) async {
    if (estado != null) {
      return await db.query('agendamientos',
          where: 'estado = ?', whereArgs: [estado],
          orderBy: 'fecha ASC, hora ASC');
    }
    return await db.query('agendamientos', orderBy: 'fecha ASC, hora ASC');
  }

  Future<int> updateAgendamiento(int id, Map<String, dynamic> data) async =>
      await db.update('agendamientos', data, where: 'id = ?', whereArgs: [id]);

  Future<int> deleteAgendamiento(int id) async =>
      await db.delete('agendamientos', where: 'id = ?', whereArgs: [id]);

  Future<int> insertNota(Map<String, dynamic> n) async =>
      await db.insert('notas', n);

  Future<List<Map<String, dynamic>>> getNotas() async =>
      await db.query('notas', orderBy: 'id DESC');

  Future<int> updateNota(int id, Map<String, dynamic> data) async =>
      await db.update('notas', data, where: 'id = ?', whereArgs: [id]);

  Future<int> deleteNota(int id) async =>
      await db.delete('notas', where: 'id = ?', whereArgs: [id]);

  Future<void> restablecerDatos() async {
    await db.delete('venta_items');
    await db.delete('ventas');
    await db.delete('retiros');
    await db.delete('productos');
    await db.delete('agendamientos');
    await db.delete('notas');
    await db.delete('egresos');
    await db.delete('perdidas_stock');
    await db.delete('demo_meta');
  }

  Future<List<Map<String, dynamic>>> getVentasUltimos7Dias() async {
    final List<Map<String, dynamic>> resultado = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final dia = now.subtract(Duration(days: i));
      final fecha = '${dia.year}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';
      final r = await db.rawQuery(
          'SELECT COALESCE(SUM(total), 0) AS total FROM ventas WHERE fecha = ?', [fecha]);
      resultado.add({
        'fecha': fecha,
        'dia': '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}',
        'total': (r.first['total'] as num).toDouble(),
      });
    }
    return resultado;
  }

  Future<List<Map<String, dynamic>>> getProximosAgendamientos({int limite = 3}) async {
    final now = DateTime.now();
    final hoy = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return await db.query('agendamientos',
        where: 'estado = ? AND fecha >= ?',
        whereArgs: ['pendiente', hoy],
        orderBy: 'fecha ASC, hora ASC',
        limit: limite);
  }

  Future<void> incrementarStockAutomatico({required int productoId, required int cantidadASumar}) async {
    final List<Map<String, dynamic>> res = await db.query('productos', where: 'id = ?', whereArgs: [productoId]);
    if (res.isNotEmpty) {
      final producto = res.first;
      final double precioCompra = (producto['precio_compra'] as num).toDouble();
      final int stockActual = producto['stock'] as int;
      final double costoTotalEgreso = precioCompra * cantidadASumar;
      await db.transaction((txn) async {
        await txn.update('productos', {'stock': stockActual + cantidadASumar},
            where: 'id = ?', whereArgs: [productoId]);
        await txn.insert('egresos', {
          'concepto': 'Reposición de stock: ${producto['nombre']}',
          'monto': costoTotalEgreso,
          'fecha': DateTime.now().toIso8601String(),
          'tipo': 'compra_stock',
          'producto_id': productoId,
        });
      });
    }
  }
}