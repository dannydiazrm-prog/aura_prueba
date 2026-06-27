import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens/dashboard_screen.dart';
import 'services/db_service.dart';
import 'app_theme.dart';

const Color kDefaultColor = Color(0xFF29B6F6);

Color primaryColor = kDefaultColor;
String nombreNegocio = 'Aura Demo';

final appStateNotifier = ValueNotifier<int>(0);
void notificarCambio() => appStateNotifier.value++;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  if (!Platform.isAndroid) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await _cargarPreferencias();
  await DbService.instance.init();

  runApp(const AuraPruebaApp());
}

Future<void> _cargarPreferencias() async {
  final prefs = await SharedPreferences.getInstance();
  final colorValue = prefs.getInt('primaryColor');
  if (colorValue != null) primaryColor = Color(colorValue);
  nombreNegocio = prefs.getString('nombreNegocio') ?? 'Aura Demo';

  final primeraVez = prefs.getString('primera_instalacion');
  if (primeraVez == null) {
    await prefs.setString(
        'primera_instalacion', DateTime.now().toIso8601String());
  }
}

Future<bool> _pruebaExpirada() async {
  final prefs = await SharedPreferences.getInstance();
  final fechaStr = prefs.getString('primera_instalacion');
  if (fechaStr == null) return false;
  final fecha = DateTime.tryParse(fechaStr);
  if (fecha == null) return false;
  return DateTime.now().difference(fecha).inHours >= 3;
}

class AuraPruebaApp extends StatefulWidget {
  const AuraPruebaApp({super.key});

  static void reiniciar(BuildContext context) {
    context.findAncestorStateOfType<_AuraPruebaAppState>()?.reiniciar();
  }

  @override
  State<AuraPruebaApp> createState() => _AuraPruebaAppState();
}

class _AuraPruebaAppState extends State<AuraPruebaApp> {
  void reiniciar() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: nombreNegocio,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(primaryColor).copyWith(
        appBarTheme: buildTheme(primaryColor).appBarTheme.copyWith(
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
            ),
      ),
      home: FutureBuilder<bool>(
        future: _pruebaExpirada(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data!) {
            return const _PantallaExpirada();
          }
          return const DashboardScreen();
        },
      ),
    );
  }
}

class _PantallaExpirada extends StatelessWidget {
  const _PantallaExpirada();

  Future<void> _abrirWhatsApp() async {
    final uri = Uri.parse('https://wa.me/595983069263');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_clock, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 32),
              const Text(
                'Tu período de prueba ha finalizado',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212529)),
              ),
              const SizedBox(height: 16),
              Text(
                'Contacta al desarrollador para adquirir la versión completa de Aura Estándar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _abrirWhatsApp,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('Comprar Aura Estándar',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}