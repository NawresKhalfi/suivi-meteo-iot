import 'package:flutter/material.dart';
import 'alerts_page.dart';
import 'iot_sensors_page.dart';

void main() {
  runApp(const SuiviMeteoApp());
}

class SuiviMeteoApp extends StatelessWidget {
  const SuiviMeteoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Station Météo IoT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF3F8CFF), Color(0xFF60EFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.cloud,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Station Météo IoT',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Surveillance environnementale en temps réel',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F6EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.circle,
                      color: Color(0xFF27AE60),
                      size: 10,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Connecté',
                      style: TextStyle(
                        color: Color(0xFF27AE60),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Tableau de bord'),
              Tab(text: 'Capteurs IoT'),
              Tab(text: 'Alertes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DashboardTab(),
            IotSensorsPage(),
            AlertsPage(),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: const [
        WeatherCard(
          title: 'Température',
          value: '21.8',
          unit: '°C',
          color: Color(0xFFFF6A3D),
          icon: Icons.device_thermostat,
          progress: 0.6,
        ),
        WeatherCard(
          title: 'Humidité',
          value: '66.5',
          unit: '%',
          color: Color(0xFF2D9CDB),
          icon: Icons.water_drop,
          progress: 0.7,
        ),
        WeatherCard(
          title: 'Pression',
          value: '1012.8',
          unit: 'hPa',
          color: Color(0xFF9B51E0),
          icon: Icons.speed,
          progress: 0.5,
        ),
        WeatherCard(
          title: 'Qualité de l\'air',
          value: '42',
          unit: 'AQI',
          color: Color(0xFF27AE60),
          icon: Icons.cloud_outlined,
          progress: 0.4,
          status: 'Bon',
        ),
        WeatherCard(
          title: 'Vitesse du vent',
          value: '13.7',
          unit: 'km/h',
          color: Color(0xFF2D9CDB),
          icon: Icons.air,
          progress: 0.6,
        ),
        WeatherCard(
          title: 'Index UV',
          value: '5.0',
          unit: '',
          color: Color(0xFFFFA726),
          icon: Icons.wb_sunny_outlined,
          progress: 0.5,
        ),
        SizedBox(height: 8),
        ChartCard(
          title: 'Température et Humidité (48h)',
          subtitle: 'Évolution récente des mesures',
        ),
      ],
    );
  }
}

class WeatherCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final double progress;
  final String? status;

  const WeatherCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    required this.progress,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.95),
                        color.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Colors.black26,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: 4),
              Text(
                status!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF27AE60),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF5F7FB),
                border: Border.all(
                  color: Colors.grey,
                ),
              ),
              child: const Center(
                child: Text(
                  'Graphique (48h) à implémenter',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

