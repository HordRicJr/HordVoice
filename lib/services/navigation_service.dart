import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../localization/language_resolver.dart';
import 'dart:convert';
import 'environment_config.dart';

class NavigationService {
  bool _isInitialized = false;
  Position? _lastKnownPosition;
  final EnvironmentConfig _envConfig = EnvironmentConfig();

  // Étape 8: Cache pour éviter quota & latence
  Map<String, dynamic>? _lastSearchResult;
  DateTime? _lastSearchTime;
  final Duration _cacheTimeout = Duration(minutes: 5);

  Future<void> initialize() async {
    // Charger la configuration
    await _envConfig.loadConfig();

    _isInitialized = true;

    try {
      await _requestLocationPermission();
      _lastKnownPosition = await getCurrentLocation();
      debugPrint(
        'NavigationService initialisé avec position: $_lastKnownPosition',
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de NavigationService: $e');
    }
  }

  Future<bool> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Service de localisation désactivé - mode fallback');
        return false; // Au lieu de throw Exception
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Permission de localisation refusée - mode fallback');
          return false; // Au lieu de throw Exception
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          'Permission de localisation refusée définitivement - mode fallback',
        );
        return false; // Au lieu de throw Exception
      }

      return true;
    } catch (e) {
      debugPrint('Erreur permission géolocalisation: $e - mode fallback');
      return false; // Mode de fallback
    }
  }

  Future<Position> getCurrentLocation() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      // Vérifier d'abord les permissions sans crash
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        debugPrint(
          'Pas de permission géolocalisation - utilisation position par défaut',
        );
        // Position par défaut (Paris) si pas de permission
        return Position(
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 100.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la position: $e');
      if (_lastKnownPosition != null) {
        return _lastKnownPosition!;
      }

      // Position par défaut si tout échoue
      debugPrint('Utilisation position par défaut (Paris)');
      return Position(
        latitude: 48.8566,
        longitude: 2.3522,
        timestamp: DateTime.now(),
        accuracy: 100.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }
  }

  Future<String> getCurrentAddress() async {
    try {
      Position position = await getCurrentLocation();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      return 'Adresse inconnue';
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'adresse: $e');
      return 'Impossible de déterminer l\'adresse';
    }
  }

  Future<List<Location>> searchLocation(String address) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      List<Location> locations = await locationFromAddress(address);
      return locations;
    } catch (e) {
      debugPrint('Erreur lors de la recherche d\'adresse: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getDirections(String destination) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      Position currentPosition = await getCurrentLocation();

      // Utiliser Azure Maps API au lieu de Google Maps
      final lang = LanguageResolver.toBcp47(
        (await LanguageResolver.getSavedLanguageCode()),
      );
      final url = Uri.parse(
        'https://atlas.microsoft.com/route/directions/json'
        '?api-version=1.0'
        '&subscription-key=${_envConfig.googleMapsApiKey ?? ""}'
        '&query=${currentPosition.latitude},${currentPosition.longitude}:${Uri.encodeComponent(destination)}'
        '&language=$lang',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final summary = route['summary'];

          return {
            'distance':
                '${(summary['lengthInMeters'] / 1000).toStringAsFixed(1)} km',
            'duration': '${(summary['travelTimeInSeconds'] / 60).round()} min',
            'start_address': 'Position actuelle',
            'end_address': destination,
            'steps': _extractAzureSteps(route['legs']),
            'overview_polyline': 'azure_route_data',
          };
        } else {
          throw Exception('Aucune route trouvée');
        }
      } else {
        throw Exception('Erreur API Azure Maps: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des directions: $e');
      return _getFallbackDirections(destination);
    }
  }

  List<Map<String, String>> _extractAzureSteps(List<dynamic>? legs) {
    if (legs == null || legs.isEmpty) return [];

    final instructions = legs[0]['points'] ?? [];

    return instructions.map<Map<String, String>>((point) {
      return {
        'instruction':
            'Continuer vers ${point['latitude']}, ${point['longitude']}',
        'distance': '500 m',
        'duration': '1 min',
      };
    }).toList();
  }

  Map<String, dynamic> _getFallbackDirections(String destination) {
    return {
      'distance': 'Distance inconnue',
      'duration': 'Durée inconnue',
      'start_address': 'Position actuelle',
      'end_address': destination,
      'steps': [
        {
          'instruction':
              'Directions indisponibles. Utilisez votre application de navigation préférée.',
          'distance': '-',
          'duration': '-',
        },
      ],
      'overview_polyline': '',
    };
  }

  Future<void> openInGoogleMaps(String destination) async {
    try {
      Position currentPosition = await getCurrentLocation();

      final url = Uri.parse(
        'https://www.google.com/maps/dir/'
        '${currentPosition.latitude},${currentPosition.longitude}/'
        '${Uri.encodeComponent(destination)}',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir Google Maps');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture de Google Maps: $e');
      throw Exception('Impossible d\'ouvrir la navigation: $e');
    }
  }

  Future<void> openInWaze(String destination) async {
    try {
      final wazeUrl = Uri.parse(
        'https://waze.com/ul?q=${Uri.encodeComponent(destination)}',
      );

      if (await canLaunchUrl(wazeUrl)) {
        await launchUrl(wazeUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Waze n\'est pas installé');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture de Waze: $e');
      throw Exception('Impossible d\'ouvrir Waze: $e');
    }
  }

  Future<List<Map<String, dynamic>>> findNearbyPlaces(
    String type, {
    int radius = 5000,
  }) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      Position currentPosition = await getCurrentLocation();

      // Utiliser Azure Maps Search API
      final lang = LanguageResolver.toBcp47(
        (await LanguageResolver.getSavedLanguageCode()),
      );
      final url = Uri.parse(
        'https://atlas.microsoft.com/search/nearby/json'
        '?api-version=1.0'
        '&subscription-key=${_envConfig.googleMapsApiKey ?? ""}'
        '&lat=${currentPosition.latitude}'
        '&lon=${currentPosition.longitude}'
        '&radius=$radius'
        '&categorySet=${_mapPlaceTypeToAzure(type)}'
        '&language=$lang',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null) {
          return (data['results'] as List).map<Map<String, dynamic>>((place) {
            final position = place['position'];
            return {
              'name': place['poi']?['name'] ?? 'Lieu sans nom',
              'address':
                  place['address']?['freeformAddress'] ??
                  'Adresse non disponible',
              'rating': 4.0, // Azure Maps ne fournit pas de notation
              'price_level': 2,
              'latitude': position['lat'],
              'longitude': position['lon'],
              'place_id': place['id'],
              'types': [type],
              'distance': _calculateDistance(
                currentPosition.latitude,
                currentPosition.longitude,
                position['lat'],
                position['lon'],
              ),
            };
          }).toList();
        }
      }

      return _getFallbackNearbyPlaces(type);
    } catch (e) {
      debugPrint('Erreur lors de la recherche de lieux: $e');
      return _getFallbackNearbyPlaces(type);
    }
  }

  String _mapPlaceTypeToAzure(String googleType) {
    const typeMapping = {
      'restaurant': '7315',
      'hospital': '7321',
      'pharmacy': '7326',
      'gas_station': '7311',
      'bank': '7328',
      'school': '7372',
      'police': '7367',
      'mosque': '7377',
      'church': '7377',
    };

    return typeMapping[googleType] ?? '7315'; // Restaurant par défaut
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  List<Map<String, dynamic>> _getFallbackNearbyPlaces(String type) {
    return [
      {
        'name': 'Lieu $type proche',
        'address': 'Adresse non disponible',
        'rating': 4.0,
        'price_level': 2,
        'latitude': 0.0,
        'longitude': 0.0,
        'place_id': 'fallback_id',
        'types': [type],
        'distance': 1000.0,
      },
    ];
  }

  Future<String> getTrafficInfo(String destination) async {
    try {
      final directions = await getDirections(destination);
      return 'Temps de trajet: ${directions['duration']}, Distance: ${directions['distance']}';
    } catch (e) {
      debugPrint('Erreur lors de la récupération des infos trafic: $e');
      return 'Informations de trafic indisponibles';
    }
  }

  Future<bool> isLocationAvailable() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      return serviceEnabled &&
          (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse);
    } catch (e) {
      return false;
    }
  }

  Position? get lastKnownPosition => _lastKnownPosition;
  bool get isInitialized => _isInitialized;

  /// Étape 8: Recherche POI voice-only avec cache
  Future<Map<String, dynamic>> searchPOIVoiceOnly(String query) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    // Vérifier le cache
    if (_lastSearchResult != null &&
        _lastSearchTime != null &&
        DateTime.now().difference(_lastSearchTime!) < _cacheTimeout) {
      debugPrint('Utilisation du cache POI');
      return _lastSearchResult!;
    }

    try {
      Position currentPosition = await getCurrentLocation();

      // Appel Azure Maps Search
      final url = Uri.parse(
        'https://atlas.microsoft.com/search/poi/json'
        '?api-version=1.0'
        '&subscription-key=${_envConfig.googleMapsApiKey ?? ""}'
        '&query=${Uri.encodeComponent(query)}'
        '&lat=${currentPosition.latitude}'
        '&lon=${currentPosition.longitude}'
        '&radius=5000'
        '&language=fr-FR'
        '&limit=3',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null && data['results'].isNotEmpty) {
          final results = (data['results'] as List).take(2).map((result) {
            final poi = result['poi'];
            final address = result['address'];
            final distance = result['dist'];

            return {
              'name': poi['name'] ?? 'Lieu inconnu',
              'address': address['freeformAddress'] ?? 'Adresse inconnue',
              'distance': '${(distance / 1000).toStringAsFixed(1)} km',
              'categories': poi['categories'] ?? [],
              'position': result['position'],
            };
          }).toList();

          final searchResult = {
            'query': query,
            'results': results,
            'timestamp': DateTime.now().toIso8601String(),
            'location': 'près de vous',
          };

          // Mettre en cache
          _lastSearchResult = searchResult;
          _lastSearchTime = DateTime.now();

          return searchResult;
        } else {
          return {
            'query': query,
            'results': [],
            'error': 'Aucun résultat trouvé',
            'timestamp': DateTime.now().toIso8601String(),
          };
        }
      } else {
        throw Exception('Erreur API Azure Maps: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur recherche POI: $e');
      return {
        'query': query,
        'results': [],
        'error': 'Erreur de recherche: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Étape 8: Générer réponse vocale pour POI
  String generateVoiceResponseForPOI(Map<String, dynamic> searchResult) {
    final query = searchResult['query'] ?? '';
    final results = searchResult['results'] as List? ?? [];

    if (results.isEmpty) {
      return 'Désolé, je n\'ai trouvé aucun $query près de vous.';
    }

    if (results.length == 1) {
      final poi = results[0];
      return 'J\'ai trouvé ${poi['name']} à ${poi['distance']}. Voulez-vous l\'itinéraire ?';
    }

    final first = results[0];
    final second = results[1];
    return 'J\'ai trouvé ${first['name']} à ${first['distance']} et ${second['name']} à ${second['distance']}. Lequel vous intéresse ?';
  }

  /// Étape 8: Demander permission location vocalement
  Future<String> requestLocationPermissionVoiceOnly() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Le service de localisation est désactivé. Veuillez l\'activer dans les paramètres.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Permission de localisation refusée. Je ne peux pas vous guider sans votre position.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Permission de localisation bloquée. Veuillez l\'autoriser dans les paramètres de l\'application.';
      }

      return 'Permission de localisation accordée. Je peux maintenant vous guider.';
    } catch (e) {
      return 'Erreur lors de la demande de permission: $e';
    }
  }

  void dispose() {
    _isInitialized = false;
    _lastKnownPosition = null;
    _lastSearchResult = null;
    _lastSearchTime = null;
  }
}
