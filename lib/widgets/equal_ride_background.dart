import 'package:flutter/material.dart';

class EqualRideBackground extends StatelessWidget {
  const EqualRideBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071D36),
            Color(0xFF10365E),
            Color(0xFF071D36),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _Glow(
              color: const Color(0xFF31D1C6).withOpacity(0.20),
              size: 270,
            ),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: _Glow(
              color: const Color(0xFF4879E8).withOpacity(0.22),
              size: 300,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 45,
          ),
        ],
      ),
    );
  }
}