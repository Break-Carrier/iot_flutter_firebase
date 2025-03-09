import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/current_state.dart';
import '../services/sensor_service.dart';

class CurrentStateWidget extends StatelessWidget {
  const CurrentStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final sensorService = Provider.of<SensorService>(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'État Actuel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Actualiser'),
                  onPressed: () => sensorService.refreshAllData(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<CurrentState?>(
              stream: sensorService.getCurrentState(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    sensorService.lastKnownState == null) {
                  return _buildLoadingIndicator();
                }

                if (snapshot.hasError) {
                  return _buildErrorDisplay(snapshot.error.toString());
                }

                final currentState =
                    snapshot.data ?? sensorService.lastKnownState;

                if (currentState == null) {
                  return _buildNoDataDisplay();
                }

                return _buildStateDisplay(context, currentState);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Chargement des données...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              'Erreur: $error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataDisplay() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.amber, size: 48),
            SizedBox(height: 8),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Appuyez sur "Actualiser" pour récupérer les données',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateDisplay(BuildContext context, CurrentState state) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final lastUpdate = dateFormat.format(state.lastUpdate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMeasurementRow(
          context,
          icon: Icons.thermostat,
          label: 'Température',
          value: '${state.temperature.toStringAsFixed(1)}°C',
          color: _getTemperatureColor(state),
        ),
        const SizedBox(height: 12),
        _buildMeasurementRow(
          context,
          icon: Icons.water_drop,
          label: 'Humidité',
          value: '${state.humidity.toStringAsFixed(1)}%',
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildThresholdRow(context, state),
        const SizedBox(height: 12),
        Text(
          'Dernière mise à jour: $lastUpdate',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdRow(BuildContext context, CurrentState state) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (state.isHighTemperature) {
      statusText = 'Température élevée';
      statusColor = Colors.red;
      statusIcon = Icons.keyboard_arrow_up;
    } else if (state.isLowTemperature) {
      statusText = 'Température basse';
      statusColor = Colors.blue;
      statusIcon = Icons.keyboard_arrow_down;
    } else {
      statusText = 'Température normale';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Row(
      children: [
        const Text(
          'État: ',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Chip(
          avatar: Icon(statusIcon, color: Colors.white, size: 16),
          label: Text(
            statusText,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: statusColor,
        ),
        const Spacer(),
        Text(
          'Seuils: ${state.thresholdLow.toStringAsFixed(1)} - ${state.thresholdHigh.toStringAsFixed(1)}°C',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getTemperatureColor(CurrentState state) {
    if (state.isHighTemperature) {
      return Colors.red;
    } else if (state.isLowTemperature) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }
}
