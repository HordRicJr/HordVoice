import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';

class SpotifyService {
  late http.Client _client;
  bool _isInitialized = false;
  String? _accessToken;
  DateTime? _tokenExpiry;

  static const String _clientId = 'your_spotify_client_id';
  static const String _clientSecret = 'your_spotify_client_secret';
  static const String _redirectUri = 'hordvoice://callback';
  static const String _baseUrl = 'https://api.spotify.com/v1';
  static const String _authUrl = 'https://accounts.spotify.com';

  Future<void> initialize() async {
    _client = http.Client();
    _isInitialized = true;
    debugPrint('SpotifyService initialisé');
  }

  Future<bool> authenticate() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final state = _generateRandomString(16);
      final codeChallenge = _generateCodeChallenge();

      final authUri = Uri.parse('$_authUrl/authorize').replace(
        queryParameters: {
          'client_id': _clientId,
          'response_type': 'code',
          'redirect_uri': _redirectUri,
          'state': state,
          'scope':
              'user-read-playback-state user-modify-playback-state user-read-currently-playing',
          'code_challenge_method': 'S256',
          'code_challenge': codeChallenge,
        },
      );

      if (await canLaunchUrl(authUri)) {
        await launchUrl(authUri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de l\'authentification Spotify: $e');
      return false;
    }
  }

  Future<void> playMusic(String command) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      if (_accessToken == null || _isTokenExpired()) {
        debugPrint('Token manquant ou expiré. Simulation de lecture...');
        await _simulatePlayback(command);
        return;
      }

      final response = await _client.put(
        Uri.parse('$_baseUrl/me/player/play'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        debugPrint('Lecture Spotify démarrée');
      } else {
        debugPrint('Erreur Spotify: ${response.statusCode}');
        await _simulatePlayback(command);
      }
    } catch (e) {
      debugPrint('Erreur lors de la lecture: $e');
      await _simulatePlayback(command);
    }
  }

  Future<void> searchAndPlay(String query) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      if (_accessToken == null || _isTokenExpired()) {
        debugPrint('Simulation de recherche et lecture: $query');
        await _simulateSearchAndPlay(query);
        return;
      }

      final searchResponse = await _client.get(
        Uri.parse(
          '$_baseUrl/search',
        ).replace(queryParameters: {'q': query, 'type': 'track', 'limit': '1'}),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (searchResponse.statusCode == 200) {
        final data = jsonDecode(searchResponse.body);
        final tracks = data['tracks']['items'] as List;

        if (tracks.isNotEmpty) {
          final trackUri = tracks.first['uri'];
          await _playTrack(trackUri);
        } else {
          debugPrint('Aucune musique trouvée pour: $query');
        }
      } else {
        await _simulateSearchAndPlay(query);
      }
    } catch (e) {
      debugPrint('Erreur lors de la recherche: $e');
      await _simulateSearchAndPlay(query);
    }
  }

  Future<void> pauseMusic() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      if (_accessToken == null || _isTokenExpired()) {
        debugPrint('Simulation: Musique mise en pause');
        return;
      }

      final response = await _client.put(
        Uri.parse('$_baseUrl/me/player/pause'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 204) {
        debugPrint('Musique mise en pause');
      }
    } catch (e) {
      debugPrint('Erreur lors de la pause: $e');
    }
  }

  Future<void> nextTrack() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      if (_accessToken == null || _isTokenExpired()) {
        debugPrint('Simulation: Piste suivante');
        return;
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/me/player/next'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 204) {
        debugPrint('Piste suivante');
      }
    } catch (e) {
      debugPrint('Erreur lors du passage à la piste suivante: $e');
    }
  }

  Future<void> previousTrack() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      if (_accessToken == null || _isTokenExpired()) {
        debugPrint('Simulation: Piste précédente');
        return;
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/me/player/previous'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 204) {
        debugPrint('Piste précédente');
      }
    } catch (e) {
      debugPrint('Erreur lors du retour à la piste précédente: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentTrack() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      if (_accessToken == null || _isTokenExpired()) {
        return _getSimulatedCurrentTrack();
      }

      final response = await _client.get(
        Uri.parse('$_baseUrl/me/player/currently-playing'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'name': data['item']['name'],
          'artist': data['item']['artists'][0]['name'],
          'album': data['item']['album']['name'],
          'is_playing': data['is_playing'],
          'progress_ms': data['progress_ms'],
          'duration_ms': data['item']['duration_ms'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la piste: $e');
      return _getSimulatedCurrentTrack();
    }
  }

  Future<void> _playTrack(String trackUri) async {
    final response = await _client.put(
      Uri.parse('$_baseUrl/me/player/play'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'uris': [trackUri],
      }),
    );

    if (response.statusCode == 204) {
      debugPrint('Lecture de la piste démarrée');
    }
  }

  Future<void> _simulatePlayback(String command) async {
    debugPrint('Simulation: Lecture de musique - $command');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _simulateSearchAndPlay(String query) async {
    debugPrint('Simulation: Recherche et lecture de "$query"');
    await Future.delayed(const Duration(seconds: 1));
  }

  Map<String, dynamic> _getSimulatedCurrentTrack() {
    return {
      'name': 'Titre Simulé',
      'artist': 'Artiste Simulé',
      'album': 'Album Simulé',
      'is_playing': true,
      'progress_ms': 45000,
      'duration_ms': 180000,
    };
  }

  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (index) => chars[DateTime.now().millisecond % chars.length],
    ).join();
  }

  String _generateCodeChallenge() {
    final codeVerifier = _generateRandomString(64);
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  bool _isTokenExpired() {
    return _tokenExpiry == null || DateTime.now().isAfter(_tokenExpiry!);
  }

  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _accessToken != null && !_isTokenExpired();

  void dispose() {
    _client.close();
  }
}
