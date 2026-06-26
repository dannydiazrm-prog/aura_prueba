import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasService {
  static int motorParaRubro(String rubro) {
    const grupo1 = ['Barbería', 'Salón de belleza', 'Veterinaria', 'Clínica', 'Otros'];
    const grupo2 = ['Bodega', 'Comercio', 'Ferretería'];
    const grupo3 = ['Sublimación', 'Taller'];
    if (grupo1.contains(rubro)) return 1;
    if (grupo2.contains(rubro)) return 2;
    if (grupo3.contains(rubro)) return 3;
    return 1;
  }

  static Future<String> getRubro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('rubro') ?? 'Veterinaria';
  }

  static Future<int> getMotor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('motor') ?? 1;
  }

  static Map<String, String> getMascaras(String rubro) {
    switch (rubro) {
      case 'Barbería':
        return {'profesional': 'Barbero', 'cliente': 'Cliente'};
      case 'Salón de belleza':
        return {'profesional': 'Estilista', 'cliente': 'Cliente'};
      case 'Veterinaria':
        return {'profesional': 'Veterinario', 'cliente': 'Mascota'};
      case 'Clínica':
        return {'profesional': 'Doctor', 'cliente': 'Paciente'};
      default:
        return {'profesional': 'Profesional', 'cliente': 'Cliente'};
    }
  }
}