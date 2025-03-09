# IoT Monitoring App

1. Introduction/Présentation du projet
2. Fonctionnalités principales
3. Architecture technique
4. Installation et configuration
5. Structure du projet
6. Utilisation
7. Modèles de données
8. Services
9. Widgets principaux
10. Contribution
11. Licence

## Présentation

Cette application Flutter permet de surveiller et configurer un système IoT connecté (DHT11) en temps réel. Elle se connecte à une base de données Firebase Realtime Database pour afficher les données de température et d'humidité, visualiser leur évolution sur le temps, et configurer des seuils d'alerte avec hystérésis.

## Fonctionnalités principales

- **Visualisation de l'état actuel** : Température et humidité en temps réel
- **Graphique d'évolution** : Visualisation des données de capteurs sur différentes périodes
- **Configuration des seuils** : Paramétrage des limites de température avec hystérésis
- **Historique des alertes** : Liste des événements de dépassement de seuil avec pagination
- **Mode hors ligne** : Persistance des données grâce à Firebase
- **Actualisation automatique** : Mise à jour des données en temps réel

## Architecture technique

L'application est construite sur l'architecture suivante :

- **Frontend** : Flutter (Material Design 3)
- **Backend** : Firebase Realtime Database
- **État** : Gestion avec Provider
- **Graphiques** : fl_chart pour la visualisation des données
- **Modèle de données** : Modèles spécifiques pour chaque type de données

## Installation

### Prérequis

- Flutter SDK (^3.6.0)
- Compte Firebase
- Android Studio / VS Code

### Configuration

1. **Clonez le dépôt**

   ```bash
   git clone https://github.com/username/IoT_Flutter_Firebase.git
   cd IoT_Flutter_Firebase
   ```

2. **Installez les dépendances**

   ```bash
   flutter pub get
   ```

3. **Configurez Firebase**

   Ajoutez votre fichier `firebase_options.dart` à la racine du projet avec les informations suivantes :
   - apiKey
   - databaseURL
   - Les autres informations requises par FirebaseOptions

4. **Lancez l'application**

   ```bash
   flutter run
   ```

## Structure du projet

```
lib/
  ├── main.dart              # Point d'entrée de l'application
  ├── firebase_options.dart  # Configuration Firebase
  ├── models/                # Modèles de données
  │    ├── current_state.dart
  │    ├── sensor_reading.dart
  │    ├── threshold_event.dart
  │    └── time_filter.dart
  ├── services/              # Services pour la logique métier
  │    ├── firebase_service.dart
  │    ├── sensor_service.dart
  │    ├── current_state_service.dart
  │    ├── sensor_reading_service.dart
  │    └── threshold_event_service.dart
  ├── utils/                 # Utilitaires
  │    └── map_converter.dart
  ├── screens/               # Écrans principaux
  │    └── home_screen.dart
  └── widgets/               # Widgets réutilisables
       ├── current_state_widget.dart
       ├── sensor_readings_chart.dart
       ├── threshold_events_widget.dart
       └── threshold_config_widget.dart
```

## Utilisation

### Écran principal

L'application affiche un écran principal avec plusieurs sections :

1. **État actuel** : Affiche la température et l'humidité actuelles avec des codes couleur selon les seuils
2. **Configuration des seuils** : Permet d'ajuster les seuils d'alerte de température
3. **Graphique d'évolution** : Visualise l'évolution des données avec plusieurs filtres temporels
4. **Liste des événements** : Affiche l'historique des dépassements de seuil

### Configuration des seuils

La fonctionnalité de configuration des seuils permet de définir une température cible avec hystérésis :

- Activez le mode édition avec le switch
- Utilisez le curseur pour régler la température cible
- Les seuils haut (+1°C) et bas (-1°C) sont calculés automatiquement
- Validez les modifications avec le bouton "Enregistrer"

## Modèles de données

### CurrentState

Représente l'état actuel des capteurs :

- `temperature` : Température actuelle (°C)
- `humidity` : Humidité actuelle (%)
- `thresholdLow` : Seuil bas de température
- `thresholdHigh` : Seuil haut de température
- `lastUpdate` : Date de dernière mise à jour
- `isOverThreshold` : Indique si la température dépasse les seuils

### SensorReading

Représente une lecture de capteur historique :

- `temperature` : Température relevée (°C)
- `humidity` : Humidité relevée (%)
- `timestamp` : Date et heure de la mesure

### ThresholdEvent

Représente un événement de dépassement de seuil :

- `temperature` : Température lors de l'événement (°C)
- `humidity` : Humidité lors de l'événement (%)
- `timestamp` : Date et heure de l'événement
- `eventType` : Type d'événement (dépassement, retour à la normale)
- `thresholdHigh` : Seuil haut au moment de l'événement
- `thresholdLow` : Seuil bas au moment de l'événement

## Services

### FirebaseService

Service de base pour la communication avec Firebase Realtime Database :

- Initialisation de la connexion
- Méthodes CRUD pour les données
- Gestion des streams de données
- Vérification de connectivité
- Conversion sécurisée des types de données

### SensorService

Service principal qui coordonne tous les services de capteurs :

- Initialisation des services spécialisés
- Gestion de l'état de l'application
- Interface unifiée pour l'accès aux données
- Méthodes pour la mise à jour des seuils et la création d'événements

### CurrentStateService

Gère l'état actuel des capteurs :

- Récupération et mise à jour de l'état
- Configuration des seuils de température
- Surveillance des dépassements de seuil

### SensorReadingService

Gère les lectures de capteurs historiques :

- Récupération des données selon différents filtres temporels
- Traitement et filtrage des lectures

### ThresholdEventService

Gère les événements de dépassement de seuil :

- Création et récupération des événements
- Notification de nouveaux événements

## Gestion de l'hystérésis

Le système utilise un mécanisme d'hystérésis pour éviter les oscillations rapides entre les états :

1. L'utilisateur définit une température cible (par exemple 23°C)
2. Le système applique automatiquement une marge d'hystérésis (±1°C)
3. Le seuil haut est fixé à 24°C et le seuil bas à 22°C
4. Un événement de dépassement est créé uniquement lorsque :
   - La température passe au-dessus du seuil haut (>24°C)
   - La température passe en-dessous du seuil bas (<22°C)
5. Le statut revient à la normale uniquement lorsque la température revient dans la plage acceptable

Cette approche évite les faux positifs et les alertes intempestives lors de petites fluctuations de température.

## Optimisations et robustesse

L'application intègre plusieurs optimisations :

- Conversion sécurisée des types de données Firebase
- Gestion des erreurs et de la connectivité
- Cache des données pour le mode hors ligne
- Rafraîchissement intelligent des données
- Logs détaillés pour le débogage

## Améliorations possibles

- Ajout d'authentification utilisateur
- Notifications push pour les dépassements de seuil
- Support d'autres types de capteurs
- Exportation des données historiques
- Interface d'administration avancée

## Licence

Ce projet est distribué sous licence MIT. Voir le fichier LICENSE pour plus d'informations.

---

Développé avec ❤️ par Yunaluman THERESE

