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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
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
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_controller.value);
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
