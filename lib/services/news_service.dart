import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NewsService {
  late http.Client _client;
  bool _isInitialized = false;

  Future<void> initialize() async {
    _client = http.Client();
    _isInitialized = true;
    debugPrint('NewsService initialisé');
  }

  Future<List<Map<String, dynamic>>> getLatestNews({
    String category = 'general',
    String country = 'tg',
    int pageSize = 10,
  }) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final simulatedNews = _getSimulatedNews(category);
      return simulatedNews.take(pageSize).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des actualités: $e');
      return _getFallbackNews();
    }
  }

  Future<List<Map<String, dynamic>>> getNewsByCategoryAsync(
    String category,
  ) async {
    return getLatestNews(category: category);
  }

  Future<List<Map<String, dynamic>>> searchNews(String query) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final allNews = _getSimulatedNews('general');
      return allNews
          .where(
            (news) =>
                news['title'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                news['description'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la recherche d\'actualités: $e');
      return _getFallbackNews();
    }
  }

  Future<List<Map<String, dynamic>>> getAfricanNews() async {
    return _getSimulatedAfricanNews();
  }

  Future<List<Map<String, dynamic>>> getSportsNews() async {
    return _getSimulatedSportsNews();
  }

  Future<List<Map<String, dynamic>>> getTechNews() async {
    return _getSimulatedTechNews();
  }

  List<Map<String, dynamic>> _getSimulatedNews(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return _getSimulatedSportsNews();
      case 'technology':
      case 'tech':
        return _getSimulatedTechNews();
      case 'business':
        return _getSimulatedBusinessNews();
      case 'africa':
        return _getSimulatedAfricanNews();
      default:
        return _getSimulatedGeneralNews();
    }
  }

  List<Map<String, dynamic>> _getSimulatedGeneralNews() {
    return [
      {
        'title': 'Développement économique en Afrique de l\'Ouest',
        'description':
            'Les pays de la CEDEAO renforcent leur coopération économique avec de nouveaux accords commerciaux.',
        'url': 'https://example.com/news1',
        'image_url': 'https://example.com/image1.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'source': 'Actualités Afrique',
        'category': 'économie',
        'country': 'Afrique de l\'Ouest',
      },
      {
        'title': 'Innovation technologique au Togo',
        'description':
            'Lomé accueille le premier hub technologique régional dédié à l\'intelligence artificielle.',
        'url': 'https://example.com/news2',
        'image_url': 'https://example.com/image2.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 4))
            .toIso8601String(),
        'source': 'Tech Togo',
        'category': 'technologie',
        'country': 'Togo',
      },
      {
        'title': 'Éducation numérique en expansion',
        'description':
            'Lancement d\'un programme national de formation aux métiers du numérique.',
        'url': 'https://example.com/news3',
        'image_url': 'https://example.com/image3.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 6))
            .toIso8601String(),
        'source': 'Éducation Plus',
        'category': 'éducation',
        'country': 'Togo',
      },
    ];
  }

  List<Map<String, dynamic>> _getSimulatedSportsNews() {
    return [
      {
        'title': 'Victoire historique des Éperviers',
        'description':
            'L\'équipe nationale de football du Togo remporte son match de qualification.',
        'url': 'https://example.com/sports1',
        'image_url': 'https://example.com/sports1.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        'source': 'Sport Togo',
        'category': 'football',
        'country': 'Togo',
      },
      {
        'title': 'Championnat d\'Afrique de basketball',
        'description':
            'Ouverture du championnat continental avec la participation de 16 pays.',
        'url': 'https://example.com/sports2',
        'image_url': 'https://example.com/sports2.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        'source': 'Basketball Africa',
        'category': 'basketball',
        'country': 'Afrique',
      },
      {
        'title': 'Nouveau centre sportif à Lomé',
        'description':
            'Inauguration d\'un complexe sportif moderne dans la capitale togolaise.',
        'url': 'https://example.com/sports3',
        'image_url': 'https://example.com/sports3.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
        'source': 'Infrastructures Sport',
        'category': 'infrastructures',
        'country': 'Togo',
      },
    ];
  }

  List<Map<String, dynamic>> _getSimulatedTechNews() {
    return [
      {
        'title': 'IA générative : nouvelle révolution en cours',
        'description':
            'Les assistants virtuels transforment la façon dont nous interagissons avec la technologie.',
        'url': 'https://example.com/tech1',
        'image_url': 'https://example.com/tech1.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(minutes: 30))
            .toIso8601String(),
        'source': 'Tech Mondiale',
        'category': 'intelligence artificielle',
        'country': 'Mondial',
      },
      {
        'title': 'Fibre optique : couverture étendue en Afrique',
        'description':
            'Nouveau câble sous-marin pour améliorer la connectivité internet du continent.',
        'url': 'https://example.com/tech2',
        'image_url': 'https://example.com/tech2.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'source': 'Connectivité Afrique',
        'category': 'infrastructure',
        'country': 'Afrique',
      },
      {
        'title': 'Applications mobiles : boom du développement local',
        'description':
            'Les développeurs africains créent des solutions innovantes pour les défis locaux.',
        'url': 'https://example.com/tech3',
        'image_url': 'https://example.com/tech3.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 4))
            .toIso8601String(),
        'source': 'DevApp Africa',
        'category': 'développement',
        'country': 'Afrique',
      },
    ];
  }

  List<Map<String, dynamic>> _getSimulatedBusinessNews() {
    return [
      {
        'title': 'Croissance du secteur bancaire mobile',
        'description':
            'Les services financiers numériques connaissent une expansion remarquable en Afrique.',
        'url': 'https://example.com/business1',
        'image_url': 'https://example.com/business1.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        'source': 'Finance Afrique',
        'category': 'fintech',
        'country': 'Afrique',
      },
      {
        'title': 'Investissements dans les énergies renouvelables',
        'description':
            'Nouveaux projets solaires et éoliens pour l\'indépendance énergétique.',
        'url': 'https://example.com/business2',
        'image_url': 'https://example.com/business2.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        'source': 'Énergie Verte',
        'category': 'énergie',
        'country': 'Afrique de l\'Ouest',
      },
    ];
  }

  List<Map<String, dynamic>> _getSimulatedAfricanNews() {
    return [
      {
        'title': 'Sommet de l\'Union Africaine',
        'description':
            'Les dirigeants africains se réunissent pour discuter de l\'intégration continentale.',
        'url': 'https://example.com/africa1',
        'image_url': 'https://example.com/africa1.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'source': 'Union Africaine',
        'category': 'politique',
        'country': 'Afrique',
      },
      {
        'title': 'Festival culturel panafricain',
        'description':
            'Célébration de la diversité culturelle africaine avec des artistes de tout le continent.',
        'url': 'https://example.com/africa2',
        'image_url': 'https://example.com/africa2.jpg',
        'published_at': DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
        'source': 'Culture Afrique',
        'category': 'culture',
        'country': 'Afrique',
      },
    ];
  }

  List<Map<String, dynamic>> _getFallbackNews() {
    return [
      {
        'title': 'Actualités du jour',
        'description':
            'Découvrez les dernières informations importantes de votre région.',
        'url': 'https://example.com/fallback',
        'image_url': 'https://example.com/fallback.jpg',
        'published_at': DateTime.now().toIso8601String(),
        'source': 'HordVoice News',
        'category': 'général',
        'country': 'Local',
      },
    ];
  }

  String summarizeNews(List<Map<String, dynamic>> newsList) {
    if (newsList.isEmpty) {
      return 'Aucune actualité disponible pour le moment.';
    }

    final topNews = newsList.take(3).toList();
    final summary = topNews.map((news) => '• ${news['title']}').join('\n');

    return 'Voici les principales actualités:\n$summary';
  }

  Map<String, int> getCategoryDistribution(
    List<Map<String, dynamic>> newsList,
  ) {
    final categoryCounts = <String, int>{};

    for (final news in newsList) {
      final category = news['category'] ?? 'autre';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    return categoryCounts;
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    _client.close();
  }
}
