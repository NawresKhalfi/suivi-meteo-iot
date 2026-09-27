import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ouvre une « bottom sheet » au style du prototype (coins 28, poignée).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    barrierColor: const Color(0x73091E30),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: builder,
  );
}

class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.children,
    this.title,
    this.showClose = false,
    super.key,
  });

  final String? title;
  final bool showClose;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.fromLTRB(0, 6, 0, 16),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                if (showClose)
                  Positioned(
                    right: -8,
                    top: 0,
                    child: IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.inkFaint,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

enum AppButtonStyle { primary, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final decoration = switch (style) {
      AppButtonStyle.primary => const BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: AppColors.shadowMd,
      ),
      AppButtonStyle.danger => const BoxDecoration(color: AppColors.alert1),
      AppButtonStyle.ghost => const BoxDecoration(color: AppColors.surfaceSoft),
    };
    final foreground = style == AppButtonStyle.ghost
        ? AppColors.inkSoft
        : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: decoration.copyWith(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
