import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/current_state_widget.dart';
import '../widgets/sensor_readings_chart.dart';
import '../widgets/threshold_events_widget.dart';
import '../services/sensor_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _timeoutExpired = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Définir un timeout de 10 secondes pour l'initialisation
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _timeoutExpired = true;
      });
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensorService = Provider.of<SensorService>(context);

    // Si le timeout a expiré et services toujours pas initialisés
    if (_timeoutExpired && !sensorService.isInitialized) {
      return _buildErrorScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring IoT'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: !sensorService.isInitialized
          ? _buildLoadingScreen()
          : RefreshIndicator(
              onRefresh: () async {
                // Rafraîchir toutes les données lors d'un swipe vers le bas
                await Provider.of<SensorService>(context, listen: false)
                    .refreshAllData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    CurrentStateWidget(),
                    SensorReadingsChart(),
                    ThresholdEventsWidget(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Initialisation des services...',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Connexion à Firebase...',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring IoT - Erreur'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Erreur de connexion',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Impossible de se connecter à Firebase après plusieurs tentatives. Vérifiez votre connexion internet et vos identifiants Firebase.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _timeoutExpired = false;
                  });
                  _timeoutTimer?.cancel();
                  _timeoutTimer = Timer(const Duration(seconds: 10), () {
                    setState(() {
                      _timeoutExpired = true;
                    });
                  });
                  // Force rebuild to retry connection
                  Provider.of<SensorService>(context, listen: false)
                      .refreshAllData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
