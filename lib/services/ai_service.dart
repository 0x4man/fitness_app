import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

/// Wraps calls to Google's Gemini API (free tier) to power the
/// in-app "AI Coach" chat. Uses gemini-2.5-flash — fast, high
/// quality, and free with no credit card required.
class AiService {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Sends the full conversation (for context) plus the user's
  /// profile (for personalization) and returns Gemini's reply text.
  Future<String> sendMessage({
    required List<ChatMessage> history,
    UserProfile? profile,
  }) async {
    if (ApiKeys.geminiApiKey == 'PASTE_YOUR_GEMINI_API_KEY_HERE') {
      throw Exception(
        'No Gemini API key set. Add your free key in lib/config/api_keys.dart '
        '(get one at https://aistudio.google.com/apikey).',
      );
    }

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _buildSystemPrompt(profile)}
        ]
      },
      'contents': history
          .map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'model',
                'parts': [
                  {'text': m.content}
                ],
              })
          .toList(),
      'generationConfig': {
        'temperature': 0.8,
        'maxOutputTokens': 800,
      },
    });

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': ApiKeys.geminiApiKey,
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'AI request failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception(
          'The AI didn\'t return a response. Please try rephrasing.');
    }

    final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception(
          'The AI didn\'t return a response. Please try rephrasing.');
    }

    return parts.map((p) => p['text'] ?? '').join().trim();
  }

  String _buildSystemPrompt(UserProfile? profile) {
    final buffer = StringBuffer()
      ..writeln(
        'You are the AI Coach inside Viora, a fitness tracking app. '
        'Give concise, practical, encouraging advice on workouts, nutrition, '
        'recovery, and healthy habits. Keep replies short and mobile-friendly '
        '(a few sentences, or a short bullet list) unless the user explicitly '
        'asks for more detail. You are not a doctor — for injuries or medical '
        'concerns, recommend seeing a qualified professional instead of '
        'diagnosing or prescribing treatment.',
      );

    if (profile != null) {
      buffer.writeln(
        '\nThe user\'s profile: ${profile.age} years old, ${profile.gender}, '
        '${profile.heightCm.toStringAsFixed(0)}cm tall, ${profile.weightKg.toStringAsFixed(0)}kg, '
        'goal: ${profile.fitnessGoal}. Tailor advice to this when relevant, '
        'but don\'t force it int reply.',
      );
    }

    return buffer.toString();
  }
}
