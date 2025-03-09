
/// Énumération des filtres temporels disponibles
enum TimeFilter {
  /// 30 dernières minutes
  thirtyMinutes,

  /// Dernière heure
  oneHour,

  /// 3 dernières heures
  threeHours,

  /// 6 dernières heures
  sixHours,

  /// 12 dernières heures
  twelveHours,

  /// Dernier jour
  oneDay,

  /// Dernière semaine
  oneWeek,

  /// Dernier mois
  oneMonth,
}

/// Extension pour ajouter des fonctionnalités aux filtres temporels
extension TimeFilterExtension on TimeFilter {
  /// Obtenir la durée correspondante au filtre
  Duration get duration {
    switch (this) {
      case TimeFilter.thirtyMinutes:
        return const Duration(minutes: 30);
      case TimeFilter.oneHour:
        return const Duration(hours: 1);
      case TimeFilter.threeHours:
        return const Duration(hours: 3);
      case TimeFilter.sixHours:
        return const Duration(hours: 6);
      case TimeFilter.twelveHours:
        return const Duration(hours: 12);
      case TimeFilter.oneDay:
        return const Duration(days: 1);
      case TimeFilter.oneWeek:
        return const Duration(days: 7);
      case TimeFilter.oneMonth:
        return const Duration(days: 30);
    }
  }

  /// Obtenir le nom d'affichage du filtre
  String get displayName {
    switch (this) {
      case TimeFilter.thirtyMinutes:
        return "30 min";
      case TimeFilter.oneHour:
        return "1 heure";
      case TimeFilter.threeHours:
        return "3 heures";
      case TimeFilter.sixHours:
        return "6 heures";
      case TimeFilter.twelveHours:
        return "12 heures";
      case TimeFilter.oneDay:
        return "1 jour";
      case TimeFilter.oneWeek:
        return "1 semaine";
      case TimeFilter.oneMonth:
        return "1 mois";
    }
  }

  /// Calcule la date de début selon le filtre
  DateTime getStartDate() {
    return DateTime.now().subtract(duration);
  }
}
