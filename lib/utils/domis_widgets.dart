import 'package:flutter/material.dart';
import '../main.dart';

// CARD CON DEGRADADO
class DomisGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final List<Color>? colors;

  const DomisGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? [primaryColor, primaryColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// CARD BLANCA CON SOMBRA SUAVE
class DomisCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const DomisCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// BOTÓN DE NAVEGACIÓN DEL DASHBOARD
class DomisNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const DomisNavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SECCIÓN CON TÍTULO
class DomisSeccion extends StatelessWidget {
  final String titulo;
  final Widget child;

  const DomisSeccion({super.key, required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.8)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// SNACKBAR DE ÉXITO
void mostrarExito(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Text(mensaje),
    ]),
    backgroundColor: const Color(0xFF2E7D32),
    duration: const Duration(seconds: 2),
  ));
}

// SNACKBAR DE ERROR
void mostrarError(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.error_outline, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(mensaje)),
    ]),
    backgroundColor: const Color(0xFFC62828),
    duration: const Duration(seconds: 3),
  ));
}

// SNACKBAR DE ADVERTENCIA
void mostrarAdvertencia(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(mensaje)),
    ]),
    backgroundColor: const Color(0xFFE65100),
    duration: const Duration(seconds: 3),
  ));
}

// DIALOG DE CONFIRMACIÓN
Future<bool> mostrarConfirmacion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String botonConfirmar = 'Confirmar',
  Color colorConfirmar = const Color(0xFF1565C0),
  bool peligroso = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(
        children: [
          Icon(
            peligroso ? Icons.warning_amber_rounded : Icons.help_outline,
            color: peligroso ? Colors.red : Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(titulo),
        ],
      ),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: peligroso ? Colors.red : colorConfirmar,
            foregroundColor: Colors.white,
          ),
          child: Text(botonConfirmar),
        ),
      ],
    ),
  );
  return result ?? false;
}