import 'dart:ui';

import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = Colors.white.withOpacity(0.8);
    final blur = 10.0;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          color: bg,
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
    return onTap != null
        ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14), child: card)
        : card;
  }
}
