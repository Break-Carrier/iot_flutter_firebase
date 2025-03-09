/// Utilitaires pour convertir les types de données
class MapConverter {
  /// Convertit un Map<Object?, Object?> en Map<String, dynamic>
  static Map<String, dynamic> convertToStringDynamicMap(
      Map<Object?, Object?> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (key != null) {
        if (value is Map) {
          // Conversion récursive pour les sous-maps
          result[key.toString()] =
              convertToStringDynamicMap(value as Map<Object?, Object?>);
        } else if (value is List) {
          // Conversion pour les listes
          result[key.toString()] = convertList(value);
        } else {
          // Valeurs simples
          result[key.toString()] = value;
        }
      }
    });
    return result;
  }

  /// Convertit les éléments d'une liste
  static List<dynamic> convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return convertToStringDynamicMap(item as Map<Object?, Object?>);
      } else if (item is List) {
        return convertList(item);
      } else {
        return item;
      }
    }).toList();
  }
}
