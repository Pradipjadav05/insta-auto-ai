import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../domain/ai_repository.dart';
import '../domain/content_model.dart';
import '../../../core/constants/constants.dart';

class AIRepositoryImpl implements AIRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch API configurations from database
  Future<Map<String, dynamic>?> _getApiKeys() async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.settings)
          .doc(FirestoreDocs.settingsConfig)
          .get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> generateTextContent({
    required String contentType,
    required String prompt,
    String? tone,
    List<String>? keywords,
  }) async {
    final keys = await _getApiKeys();
    final geminiKey = keys?['geminiApiKey'] as String?;

    if (geminiKey == null || geminiKey.trim().isEmpty) {
      // Return high quality simulated content if no API key is set
      await Future.delayed(const Duration(seconds: 2)); // Simulate network lag
      final List<String> simulatedHashtags = keywords?.map((k) => '#${k.replaceAll(" ", "").toLowerCase()}').toList() ?? [];
      simulatedHashtags.addAll(['#instagram', '#automation', '#aiContent', '#instaAuto']);
      
      return {
        'body': '🚀 AI Generated script outline for a $contentType discussing: "$prompt".\n\n📌 Key talking points:\n- Introduction & Hooks\n- Core concept explanation\n- Engagement Question (CTA)\n\nTone matched: ${tone ?? "engaging, interactive"}.',
        'caption': 'Unlocking automated AI content workflows with InstaAuto AI! ✨\n\n$prompt\n\nWhat are your thoughts on using AI to schedule posts? Let us know below! 👇',
        'hashtags': simulatedHashtags.take(10).toList(),
      };
    }

    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiKey');

      final systemPrompt = '''You are a professional social media manager.
Write a highly engaging Instagram $contentType.
Tone: ${tone ?? "professional, catchy"}.
Keywords to include: ${(keywords ?? []).join(", ")}.
User Instructions: $prompt

Output format must be a raw JSON object with the following fields:
"body": "Detailed script outline, visual steps, or draft content",
"caption": "The final caption to copy/paste under the post",
"hashtags": ["list", "of", "relevant", "hashtags", "with", "#"]

Do not enclose the JSON inside Markdown code blocks (e.g. do not write ```json ... ```), just return the raw JSON object string.''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': systemPrompt}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textResponse = data['candidates'][0]['content']['parts'][0]['text'] as String;
        return jsonDecode(textResponse.trim());
      } else {
        throw Exception('Gemini API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate content: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> generateImages({
    required String prompt,
    int count = 1,
  }) async {
    final keys = await _getApiKeys();
    final openaiKey = keys?['openaiApiKey'] as String?;

    if (openaiKey == null || openaiKey.trim().isEmpty) {
      // Mock images using Unsplash API placeholders for responsive UI testing
      await Future.delayed(const Duration(seconds: 2));
      final List<String> mockUrls = [];
      // Random list of design related photographic collections to look premium
      final styles = [
        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?auto=format&fit=crop&q=80&w=800',
        'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?auto=format&fit=crop&q=80&w=800'
      ];

      for (int i = 0; i < count; i++) {
        mockUrls.add('${styles[i % styles.length]}&sig=${i}_${DateTime.now().millisecondsSinceEpoch}');
      }
      return mockUrls;
    }

    try {
      final url = Uri.parse('https://api.openai.com/v1/images/generations');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openaiKey',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,
          'size': '1024x1024',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final urls = (data['data'] as List).map((img) => img['url'] as String).toList();
        return urls;
      } else {
        throw Exception('DALL-E image generation failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate image: ${e.toString()}');
    }
  }

  @override
  Future<void> saveContent(ContentItem item) async {
    await _firestore
        .collection(FirestoreCollections.content)
        .doc(item.id)
        .set(item.toJson());
  }

  @override
  Stream<List<ContentItem>> getContentList() {
    return _firestore
        .collection(FirestoreCollections.content)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ContentItem.fromJson(doc.data(), docId: doc.id)).toList();
    });
  }

  @override
  Future<void> deleteContent(String id) async {
    // Delete content document
    await _firestore.collection(FirestoreCollections.content).doc(id).delete();
    
    // Also delete any associated schedule doc
    final scheduleQuery = await _firestore
        .collection(FirestoreCollections.schedules)
        .where('contentId', isEqualTo: id)
        .get();
        
    for (var doc in scheduleQuery.docs) {
      await doc.reference.delete();
    }
  }
}
