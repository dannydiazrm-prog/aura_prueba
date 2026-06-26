import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nombreCtrl = TextEditingController(text: nombreNegocio);
  File? _logoActual;
  bool _guardandoNombre = false;

  static const List<Color> _coloresDisponibles = [
    Color(0xFF29B6F6),
    Color(0xFF2196F3),
    Color(0xFF1565C0),
    Color(0xFF00ACC1),
    Color(0xFF26A69A),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFF9CCC65),
    Color(0xFFFBC02D),
    Color(0xFFFFA726),
    Color(0xFFFB8C00),
    Color(0xFFF4511E),
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFFEC407A),
    Color(0xFFAB47BC),
    Color(0xFF7E57C2),
    Color(0xFF5C6BC0),
    Color(0xFF8D6E63),
    Color(0xFF6D4C41),
    Color(0xFF78909C),
    Color(0xFF546E7A),
    Color(0xFF37474F),
    Color(0xFF263238),
  ];

  @override
  void initState() {
    super.initState();
    _cargarLogo();
  }

  Future<void> _cargarLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final logoPath = prefs.getString('logoPath');
    if (logoPath != null && File(logoPath).existsSync()) {
      setState(() => _logoActual = File(logoPath));
    }
  }

  Future<void> _cambiarLogo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Requisitos del logo'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Para que tu logo se vea bien en celular y PC:'),
            SizedBox(height: 12),
            Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text('Formato: PNG o JPG'),
            ]),
            SizedBox(height: 6),
            Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text('Tamaño: mínimo 300×300 px'),
            ]),
            SizedBox(height: 6),
            Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text('Tamaño: máximo 1024×1024 px'),
            ]),
            SizedBox(height: 6),
            Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Text('Peso máximo: 2MB'),
            ]),
            SizedBox(height: 6),
            Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Forma cuadrada para mejor resultado')),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seleccionar imagen',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La imagen supera el límite de 2MB'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destino = p.join(dir.path, 'logo_negocio_$timestamp.png');
    await File(picked.path).copy(destino);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logoPath', destino);
    setState(() => _logoActual = File(destino));
    if (mounted) AuraPruebaApp.reiniciar(context);
  }

  Future<void> _guardarNombre() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardandoNombre = true);
    nombreNegocio = nombre;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombreNegocio', nombre);
    if (mounted) {
      notificarCambio();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nombre actualizado'),
          backgroundColor: Colors.green));
    }
    setState(() => _guardandoNombre = false);
  }

  Future<void> _cambiarColor() async {
    Color colorSeleccionado = primaryColor;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Color de la app',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 4),
                  const Text('Elegí el color principal de tu negocio',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 6,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: _coloresDisponibles.map((color) {
                      final estaSeleccionado =
                          colorSeleccionado.value == color.value;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => colorSeleccionado = color);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: estaSeleccionado
                                ? Border.all(color: Colors.black87, width: 2.5)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: estaSeleccionado
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorSeleccionado,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        primaryColor = colorSeleccionado;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('primaryColor', primaryColor.value);
                        if (mounted) {
                          notificarCambio();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Aplicar',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _cambiarLogo,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryColor.withOpacity(0.15),
                      backgroundImage: _logoActual != null
                          ? FileImage(_logoActual!)
                          : null,
                      child: _logoActual == null
                          ? Icon(Icons.storefront, size: 48, color: primaryColor)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _cambiarLogo,
                    icon: const Icon(Icons.upload),
                    label: const Text('Cambiar logo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Nombre del negocio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreCtrl,
              maxLength: 20,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nombre del negocio',
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardandoNombre ? null : _guardarNombre,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white),
                child: _guardandoNombre
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar nombre'),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Colorimetría',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cambiarColor,
                icon: CircleAvatar(radius: 10, backgroundColor: primaryColor),
                label: const Text('Cambiar color de la app'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}