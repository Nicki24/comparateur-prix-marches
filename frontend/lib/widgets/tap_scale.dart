import 'package:flutter/material.dart';

/// Léger retrait d'échelle au toucher : feedback tactile animé pour les cartes.
class TapScale extends StatefulWidget {
  const TapScale({super.key, required this.child, this.facteur = 0.98});

  final Widget child;
  final double facteur;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _enfonce = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _enfonce ? widget.facteur : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Listener(
        onPointerDown: (_) => setState(() => _enfonce = true),
        onPointerUp: (_) => setState(() => _enfonce = false),
        onPointerCancel: (_) => setState(() => _enfonce = false),
        child: widget.child,
      ),
    );
  }
}