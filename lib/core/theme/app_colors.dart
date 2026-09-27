import 'package:flutter/material.dart';

/// Palette « bleu ciel » du prototype (Modern Layered Premium UI).
abstract final class AppColors {
  static const bg = Color(0xFFEAF5FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFEAF6FF);
  static const ink = Color(0xFF132436);
  static const inkSoft = Color(0xFF5E7690);
  static const inkFaint = Color(0xFF95AAC0);
  static const line = Color(0xFFDCEEFA);

  static const primary1 = Color(0xFF159BDE);
  static const primary2 = Color(0xFF5CC9F5);
  static const primary3 = Color(0xFF0B5E8C);

  static const sun1 = Color(0xFFFFB238);
  static const sun2 = Color(0xFFFF7A45);
  static const rain1 = Color(0xFF2FA7E0);
  static const rain2 = Color(0xFF175FCB);
  static const wind1 = Color(0xFF17C6A6);
  static const wind2 = Color(0xFF0C9A88);
  static const airGood = Color(0xFF33CC7A);
  static const airModerate = Color(0xFFF2C230);
  static const airPoor = Color(0xFFFF8F3E);
  static const airBad = Color(0xFFFF5C63);
  static const alert1 = Color(0xFFFF5C63);
  static const alert2 = Color(0xFFC81E3A);
  static const night1 = Color(0xFF1B3B6F);
  static const night2 = Color(0xFF0A1F3D);
  static const gold = Color(0xFFFFD37A);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary1, primary2],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment(-0.8, -1),
    end: Alignment(0.8, 1),
    colors: [primary1, primary2, Color(0xFFBEEBFF)],
    stops: [0, 0.6, 1],
  );

  static LinearGradient gradient(Color from, Color to) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [from, to],
  );

  static const shadowSm = [
    BoxShadow(
      color: Color(0x290B5E8C),
      blurRadius: 14,
      spreadRadius: -6,
      offset: Offset(0, 6),
    ),
  ];
  static const shadowMd = [
    BoxShadow(
      color: Color(0x330B5E8C),
      blurRadius: 28,
      spreadRadius: -10,
      offset: Offset(0, 14),
    ),
  ];
  static const shadowLg = [
    BoxShadow(
      color: Color(0x4D0B5E8C),
      blurRadius: 46,
      spreadRadius: -14,
      offset: Offset(0, 26),
    ),
  ];
}

abstract final class AppFonts {
  static const display = 'Sora';
  static const body = 'Inter';
}
