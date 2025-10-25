import 'package:flutter_test/flutter_test.dart';
import 'package:hordvoice/models/voice_models.dart';

void main() {
  group('VoiceOption.fromJson', () {
    test('parses new schema keys', () {
      final voice = VoiceOption.fromJson({
        'id': 'fr-FR-HenriNeural',
        'name': 'Henri',
        'language': 'fr-FR',
        'style': 'natural',
        'gender': 'male',
        'description': 'French male neural voice',
        'is_available': false,
        'is_premium': true,
      });

      expect(voice.id, 'fr-FR-HenriNeural');
      expect(voice.name, 'Henri');
      expect(voice.language, 'fr-FR');
      expect(voice.style, 'natural');
      expect(voice.gender, 'male');
      expect(voice.description, 'French male neural voice');
      expect(voice.isAvailable, isFalse);
      expect(voice.isPremium, isTrue);
    });

    test('parses legacy Supabase keys with fallbacks', () {
      final voice = VoiceOption.fromJson({
        'voice_id': 'en-US-AriaNeural',
        'voice_name': 'Aria',
        'language_code': 'en-US',
        'quality_level': 'expressive',
        'voice_gender': 'female',
        'voice_description': 'Legacy voice entry',
        'is_active': true,
      });

      expect(voice.id, 'en-US-AriaNeural');
      expect(voice.name, 'Aria');
      expect(voice.language, 'en-US');
      expect(voice.style, 'expressive');
      expect(voice.gender, 'female');
      expect(voice.description, 'Legacy voice entry');
      expect(voice.isAvailable, isTrue);
      expect(voice.isPremium, isFalse);
    });
  });

  group('VoiceOption.toJson', () {
    test('serializes to new schema while keeping legacy keys', () {
      const voice = VoiceOption(
        id: 'fr-FR-DeniseNeural',
        name: 'Denise',
        language: 'fr-FR',
        style: 'natural',
        gender: 'female',
        description: 'French neural voice',
        isAvailable: true,
        isPremium: false,
      );

      final json = voice.toJson();

      expect(json['id'], 'fr-FR-DeniseNeural');
      expect(json['voice_id'], 'fr-FR-DeniseNeural');
      expect(json['name'], 'Denise');
      expect(json['voice_name'], 'Denise');
      expect(json['language'], 'fr-FR');
      expect(json['language_code'], 'fr-FR');
      expect(json['style'], 'natural');
      expect(json['gender'], 'female');
      expect(json['description'], 'French neural voice');
      expect(json['is_available'], isTrue);
      expect(json['is_active'], isTrue);
      expect(json['is_premium'], isFalse);
    });
  });
}
