import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'environment_config.dart';

/// Service de météo utilisant OpenWeatherMap API
class WeatherService {
  final EnvironmentConfig _envConfig = EnvironmentConfig();
  bool _isInitialized = false;
  late String _apiKey;

  /// Initialise le service météo
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _envConfig.loadConfig();

      final apiKey = _envConfig.openWeatherMapApiKey;
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Clé API OpenWeatherMap manquante');
      }

      _apiKey = apiKey;
      _isInitialized = true;
      debugPrint('WeatherService initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur initialisation WeatherService: $e');
      rethrow;
    }
  }

  /// Obtient la météo actuelle par coordonnées
  Future<Map<String, dynamic>> getCurrentWeather(
    double latitude,
    double longitude,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&lang=fr',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _formatWeatherData(data);
      } else {
        throw Exception('Erreur API météo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur récupération météo: $e');
      return _getDefaultWeatherData();
    }
  }

  /// Obtient la météo par nom de ville
  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$_apiKey&units=metric&lang=fr',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _formatWeatherData(data);
      } else {
        throw Exception(
          'Ville non trouvée ou erreur API: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Erreur récupération météo par ville: $e');
      return _getDefaultWeatherData();
    }
  }

  /// Obtient les prévisions sur 5 jours
  Future<List<Map<String, dynamic>>> getForecast(
    double latitude,
    double longitude,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&lang=fr',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _formatForecastData(data);
      } else {
        throw Exception('Erreur API prévisions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur récupération prévisions: $e');
      return [];
    }
  }

  /// Obtient la météo pour la position actuelle
  Future<Map<String, dynamic>> getCurrentLocationWeather() async {
    try {
      // Vérifier les permissions de localisation
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }

      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );

      return await getCurrentWeather(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Erreur localisation pour météo: $e');
      // Fallback sur Paris
      return await getWeatherByCity('Paris');
    }
  }

  /// Formate les données météo de l'API
  Map<String, dynamic> _formatWeatherData(Map<String, dynamic> data) {
    try {
      return {
        'location': data['name'] ?? 'Inconnue',
        'country': data['sys']?['country'] ?? '',
        'temperature': (data['main']?['temp'] ?? 0).round(),
        'feels_like': (data['main']?['feels_like'] ?? 0).round(),
        'humidity': data['main']?['humidity'] ?? 0,
        'pressure': data['main']?['pressure'] ?? 0,
        'description': data['weather']?[0]?['description'] ?? 'Météo inconnue',
        'icon': data['weather']?[0]?['icon'] ?? '01d',
        'wind_speed': (data['wind']?['speed'] ?? 0).toDouble(),
        'wind_direction': data['wind']?['deg'] ?? 0,
        'visibility': (data['visibility'] ?? 0) / 1000, // en km
        'cloud_cover': data['clouds']?['all'] ?? 0,
        'sunrise': data['sys']?['sunrise'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000)
            : DateTime.now(),
        'sunset': data['sys']?['sunset'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000)
            : DateTime.now(),
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      debugPrint('Erreur formatage données météo: $e');
      return _getDefaultWeatherData();
    }
  }

  /// Formate les données de prévisions
  List<Map<String, dynamic>> _formatForecastData(Map<String, dynamic> data) {
    try {
      final List<dynamic> forecasts = data['list'] ?? [];
      return forecasts.take(8).map((forecast) {
        // 8 prévisions (2 jours)
        return {
          'datetime': DateTime.fromMillisecondsSinceEpoch(
            forecast['dt'] * 1000,
          ),
          'temperature': (forecast['main']?['temp'] ?? 0).round(),
          'description': forecast['weather']?[0]?['description'] ?? 'Inconnue',
          'icon': forecast['weather']?[0]?['icon'] ?? '01d',
          'humidity': forecast['main']?['humidity'] ?? 0,
          'wind_speed': (forecast['wind']?['speed'] ?? 0).toDouble(),
          'precipitation': forecast['rain']?['3h'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Erreur formatage prévisions: $e');
      return [];
    }
  }

  /// Données météo par défaut en cas d'erreur
  Map<String, dynamic> _getDefaultWeatherData() {
    return {
      'location': 'Inconnue',
      'country': '',
      'temperature': 20,
      'feels_like': 20,
      'humidity': 50,
      'pressure': 1013,
      'description': 'Météo indisponible',
      'icon': '01d',
      'wind_speed': 0.0,
      'wind_direction': 0,
      'visibility': 10.0,
      'cloud_cover': 0,
      'sunrise': DateTime.now(),
      'sunset': DateTime.now(),
      'timestamp': DateTime.now(),
    };
  }

  /// Convertit l'icône météo en emoji
  String getWeatherEmoji(String iconCode) {
    switch (iconCode) {
      case '01d':
      case '01n':
        return 'Ensoleillé';
      case '02d':
      case '02n':
        return 'Partiellement nuageux';
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return 'Nuageux';
      case '09d':
      case '09n':
        return 'Pluie';
      case '10d':
      case '10n':
        return 'Averse';
      case '11d':
      case '11n':
        return 'Orage';
      case '13d':
      case '13n':
        return 'Neige';
      case '50d':
      case '50n':
        return 'Brouillard';
      default:
        return 'Partiellement nuageux';
    }
  }

  /// Obtient une description météo lisible
  String getReadableDescription(Map<String, dynamic> weather) {
    final location = weather['location'];
    final temperature = weather['temperature'];
    final description = weather['description'];

    return 'À $location, il fait $temperature degrés avec $description.';
  }

  /// Vérifie si le service est initialisé
  bool get isInitialized => _isInitialized;

  /// Dispose le service
  void dispose() {
    _isInitialized = false;
  }
}
