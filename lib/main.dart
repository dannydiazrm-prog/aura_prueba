import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  await _cargarPreferencias();
  await DbService.instance.init();

  runApp(const AuraPruebaApp());
}

Future<void> _cargarPreferencias() async {
  final prefs = await SharedPreferences.getInstance();
  final colorValue = prefs.getInt('primaryColor');
  if (colorValue != null) primaryColor = Color(colorValue);
  nombreNegocio = prefs.getString('nombreNegocio') ?? 'Aura Demo';
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
      home: const DashboardScreen(),
    );
  }
}