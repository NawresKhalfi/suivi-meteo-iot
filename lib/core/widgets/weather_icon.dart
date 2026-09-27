import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum WeatherIconType {
  sun,
  sunCloud,
  cloud,
  cloudRain,
  cloudSnow,
  cloudBolt,
  fog,
  moon,
  moonCloud,
}

/// Icônes météo colorées reprises du prototype (SVG 24×24).
class WeatherIcon extends StatelessWidget {
  const WeatherIcon(this.type, {this.size = 24, super.key});

  final WeatherIconType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg[type]!,
      width: size,
      height: size,
      semanticsLabel: type.name,
    );
  }

  static const _svg = {
    WeatherIconType.sun:
        '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="6" fill="#FFB238"/><g stroke="#FFB238" stroke-width="2" stroke-linecap="round"><path d="M12 2v2M12 20v2M4 12H2M22 12h-2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4l1.4-1.4M17 7l1.4-1.4"/></g></svg>',
    WeatherIconType.sunCloud:
        '<svg viewBox="0 0 24 24"><circle cx="9" cy="9" r="5" fill="#FFB238"/><path d="M4 17.5A4.5 4.5 0 0 1 5 8.6 5.5 5.5 0 0 1 15.8 9.9 4 4 0 0 1 15 17.9H4Z" fill="#fff" stroke="#D9E9F5" stroke-width="1"/></svg>',
    WeatherIconType.cloud:
        '<svg viewBox="0 0 24 24"><path d="M5 17.5A4.5 4.5 0 1 1 6 8.6 5.5 5.5 0 0 1 17 10.5a4 4 0 0 1-1 7.9H5Z" fill="#A9C6E0"/></svg>',
    WeatherIconType.cloudRain:
        '<svg viewBox="0 0 24 24"><path d="M5 14.5A4.5 4.5 0 1 1 6 5.6 5.5 5.5 0 0 1 17 7.5a4 4 0 0 1-1 7.9H5Z" fill="#8FADD6"/><g stroke="#2FA7E0" stroke-width="1.8" stroke-linecap="round"><path d="M8 18v2.5M12 18v2.5M16 18v2.5"/></g></svg>',
    WeatherIconType.cloudSnow:
        '<svg viewBox="0 0 24 24"><path d="M5 14.5A4.5 4.5 0 1 1 6 5.6 5.5 5.5 0 0 1 17 7.5a4 4 0 0 1-1 7.9H5Z" fill="#BBD6EE"/><g fill="#7DA3D6"><circle cx="8" cy="19" r="1.3"/><circle cx="12" cy="20.5" r="1.3"/><circle cx="16" cy="19" r="1.3"/></g></svg>',
    WeatherIconType.cloudBolt:
        '<svg viewBox="0 0 24 24"><path d="M5 14.5A4.5 4.5 0 1 1 6 5.6 5.5 5.5 0 0 1 17 7.5a4 4 0 0 1-1 7.9H5Z" fill="#7F97C2"/><path d="M12.5 13 9.5 18h3l-1.5 4.5 4.5-6h-3l1.5-3.5Z" fill="#FFB238"/></svg>',
    WeatherIconType.fog:
        '<svg viewBox="0 0 24 24"><path d="M5 12.5A4.5 4.5 0 1 1 6 3.6 5.5 5.5 0 0 1 17 5.5a4 4 0 0 1-1 7.9H5Z" fill="#BCD0E3"/><g stroke="#95AAC0" stroke-width="1.8" stroke-linecap="round"><path d="M4 16.5h16M6 20h12"/></g></svg>',
    WeatherIconType.moon:
        '<svg viewBox="0 0 24 24"><path d="M20 14.5A8.5 8.5 0 1 1 9.5 4a7 7 0 0 0 10.5 10.5Z" fill="#2E6FB4"/></svg>',
    WeatherIconType.moonCloud:
        '<svg viewBox="0 0 24 24"><path d="M15 11a5.5 5.5 0 1 1-5-8 4.3 4.3 0 0 0 6.4 6.4A5.5 5.5 0 0 1 15 11Z" fill="#4F8FD9"/><path d="M5 19.5A3.5 3.5 0 0 1 5.8 12.7 4.3 4.3 0 0 1 14 13.9a3.2 3.2 0 0 1-.8 6.3H5Z" fill="#A9C6E0"/></svg>',
  };
}

/// Grande icône du bandeau d'accueil (soleil + nuage du prototype, déclinée).
class HeroWeatherIcon extends StatelessWidget {
  const HeroWeatherIcon(this.type, {this.size = 64, super.key});

  final WeatherIconType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (type == WeatherIconType.sunCloud) {
      return SvgPicture.string(
        '<svg viewBox="0 0 64 64"><circle cx="24" cy="28" r="12" fill="#FFB238"/><ellipse cx="38" cy="38" rx="20" ry="13" fill="#fff" opacity="0.92"/></svg>',
        width: size,
        height: size,
      );
    }
    return WeatherIcon(type, size: size);
  }
}
