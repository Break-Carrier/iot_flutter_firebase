import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/threshold_event.dart';
import '../services/sensor_service.dart';

class ThresholdEventsWidget extends StatefulWidget {
  const ThresholdEventsWidget({super.key});

  @override
  State<ThresholdEventsWidget> createState() => _ThresholdEventsWidgetState();
}

class _ThresholdEventsWidgetState extends State<ThresholdEventsWidget> {
  static const int _eventsPerPage = 5;
  int _currentPage = 0;

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
            const Text(
              'Événements de dépassement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ThresholdEvent>>(
              stream: sensorService.getThresholdEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return _buildLoadingIndicator();
                }

                if (snapshot.hasError) {
                  return _buildErrorDisplay(snapshot.error.toString());
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return _buildNoDataDisplay();
                }

                // Calculer le nombre total de pages
                final int totalPages = (events.length / _eventsPerPage).ceil();

                // S'assurer que la page actuelle est valide
                if (_currentPage >= totalPages) {
                  _currentPage = totalPages - 1;
                }

                // Calculer les indices de début et fin pour la page actuelle
                final int startIndex = _currentPage * _eventsPerPage;
                final int endIndex =
                    (startIndex + _eventsPerPage < events.length)
                        ? startIndex + _eventsPerPage
                        : events.length;

                // Obtenir les événements pour la page actuelle
                final List<ThresholdEvent> pageEvents =
                    events.sublist(startIndex, endIndex);

                return Column(
                  children: [
                    // Liste des événements
                    ...pageEvents.map((event) => _buildEventItem(event)),

                    // Pagination
                    if (totalPages > 1) _buildPagination(totalPages),
                  ],
                );
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
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Chargement des événements...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withAlpha(50)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: Colors.amber,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun événement de dépassement',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les événements apparaîtront ici lorsque la température dépassera les seuils définis',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(ThresholdEvent event) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final dateFormatted = dateFormatter.format(event.timestamp);

    Color eventColor;
    IconData eventIcon;

    if (event.isExceeded) {
      if (event.isHighTemperature) {
        eventColor = Colors.red;
        eventIcon = Icons.thermostat;
      } else if (event.isLowTemperature) {
        eventColor = Colors.blue;
        eventIcon = Icons.ac_unit;
      } else {
        eventColor = Colors.amber;
        eventIcon = Icons.warning_rounded;
      }
    } else {
      eventColor = Colors.green;
      eventIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: eventColor.withAlpha(50),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {}, // Pour l'effet de ripple
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: eventColor.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      eventIcon,
                      color: eventColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              color: Colors.blue,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${event.humidity.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              color: Colors.grey[600],
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormatted,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            splashRadius: 20,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
            onPressed:
                _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            style: IconButton.styleFrom(
              foregroundColor: Colors.grey[700],
              disabledForegroundColor: Colors.grey[400],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1} / $totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            splashRadius: 20,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            style: IconButton.styleFrom(
              foregroundColor: Colors.grey[700],
              disabledForegroundColor: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
