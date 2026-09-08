import 'package:flutter/material.dart';
import 'data/local_database.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _windController = TextEditingController();
  final _pressureController = TextEditingController();

  bool _loading = true;
  List<AlertItem> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = LocalDatabase.instance;
    await db.init();
    final thresholds = await db.getThresholds();

    _temperatureController.text =
        (thresholds['temperature_max'] ?? 25).toString();
    _humidityController.text =
        (thresholds['humidity_max'] ?? 80).toStringAsFixed(0);
    _windController.text = (thresholds['wind_max'] ?? 40).toString();
    _pressureController.text =
        (thresholds['pressure_min'] ?? 980).toStringAsFixed(0);

    final alerts = await db.getActiveAlerts();

    if (mounted) {
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    }
  }

  Future<void> _updateThresholds() async {
    final db = LocalDatabase.instance;

    double? parse(String text) =>
        double.tryParse(text.replaceAll(',', '.').trim());

    final temp = parse(_temperatureController.text);
    final hum = parse(_humidityController.text);
    final wind = parse(_windController.text);
    final pressure = parse(_pressureController.text);

    if (temp != null) {
      await db.updateThreshold('temperature_max', temp);
    }
    if (hum != null) {
      await db.updateThreshold('humidity_max', hum);
    }
    if (wind != null) {
      await db.updateThreshold('wind_max', wind);
    }
    if (pressure != null) {
      await db.updateThreshold('pressure_min', pressure);
    }

    await _loadData();
  }

  Future<void> _simulateMeasurements() async {
    final db = LocalDatabase.instance;
    final now = DateTime.now();

    // Exemple : on insère une nouvelle série de mesures
    await db.insertMeasurement(
      Measurement(type: 'temperature', value: 28.5, timestamp: now),
    );
    await db.insertMeasurement(
      Measurement(type: 'humidity', value: 82, timestamp: now),
    );
    await db.insertMeasurement(
      Measurement(type: 'wind', value: 42, timestamp: now),
    );
    await db.insertMeasurement(
      Measurement(type: 'pressure', value: 978, timestamp: now),
    );

    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nouvelles mesures simulées enregistrées'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _humidityController.dispose();
    _windController.dispose();
    _pressureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      children: [
        _AlertCenterHeader(alertCount: _alerts.length),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _simulateMeasurements,
          icon: const Icon(Icons.sensors),
          label: const Text('Capter / simuler une nouvelle mesure'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AlertThresholdsCard(
          temperatureController: _temperatureController,
          humidityController: _humidityController,
          windController: _windController,
          pressureController: _pressureController,
          onSave: _updateThresholds,
        ),
        const SizedBox(height: 16),
        _ActiveAlertsSection(alerts: _alerts),
      ],
    );
  }
}

class _AlertCenterHeader extends StatelessWidget {
  final int alertCount;

  const _AlertCenterHeader({required this.alertCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Centre d\'alertes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              alertCount == 0
                  ? 'Aucune alerte active'
                  : '$alertCount alerte${alertCount > 1 ? 's' : ''} active${alertCount > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const Spacer(),
        TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: const Color(0xFFE3F2FD),
            foregroundColor: const Color(0xFF1E88E5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_active_outlined,
            size: 18,
          ),
          label: const Text(
            'Notifications ON',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertThresholdsCard extends StatelessWidget {
  final TextEditingController temperatureController;
  final TextEditingController humidityController;
  final TextEditingController windController;
  final TextEditingController pressureController;
  final Future<void> Function() onSave;

  const _AlertThresholdsCard({
    required this.temperatureController,
    required this.humidityController,
    required this.windController,
    required this.pressureController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seuils d\'alerte',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _thresholdField(
              label: 'Température max (°C)',
              controller: temperatureController,
            ),
            const SizedBox(height: 8),
            _thresholdField(
              label: 'Humidité max (%)',
              controller: humidityController,
            ),
            const SizedBox(height: 8),
            _thresholdField(
              label: 'Vent max (km/h)',
              controller: windController,
            ),
            const SizedBox(height: 8),
            _thresholdField(
              label: 'Pression min (hPa)',
              controller: pressureController,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save, size: 18),
                label: const Text(
                  'Enregistrer',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thresholdField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveAlertsSection extends StatelessWidget {
  final List<AlertItem> alerts;

  const _ActiveAlertsSection({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertes actives',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (alerts.isEmpty)
          const Text(
            'Aucune alerte active.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          )
        else
          Column(
            children: alerts
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ActiveAlertCard(alert: a),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ActiveAlertCard extends StatelessWidget {
  final AlertItem alert;

  const _ActiveAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFF2C2),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFF0B2),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  color: Color(0xFFFB8C00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Alerte système',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Acquitter',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.close,
                size: 16,
                color: Colors.black38,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.message,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

