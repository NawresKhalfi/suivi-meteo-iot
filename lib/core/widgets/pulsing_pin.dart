import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Repère de position avec halo pulsé (carte).
class PulsingPin extends StatefulWidget {
  const PulsingPin({this.pulse = true, super.key});

  final bool pulse;

  @override
  State<PulsingPin> createState() => _PulsingPinState();
}

class _PulsingPinState extends State<PulsingPin>
    with SingleTickerProviderStateMixin {
  // Créé à la demande : l'instancier dans dispose() (via `late`) déclencherait
  // une recherche d'ancêtre sur un élément désactivé.
  AnimationController? _controller;

  AnimationController get _pulseController =>
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _pulseController.repeat();
  }

  @override
  void didUpdateWidget(covariant PulsingPin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse == oldWidget.pulse) return;
    if (widget.pulse) {
      _pulseController.repeat();
    } else {
      _controller?.stop();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.pulse)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_pulseController.value);
                return Container(
                  width: 18 + 30 * t,
                  height: 18 + 30 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7 * (1 - t)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
          Container(
            width: 16,
            height: 16,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary1,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
