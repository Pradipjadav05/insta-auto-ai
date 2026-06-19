import '../domain/content_model.dart';

abstract class AIRepository {
  Future<Map<String, dynamic>> generateTextContent({
    required String contentType,
    required String prompt,
    String? tone,
    List<String>? keywords,
  });

  Future<List<String>> generateImages({
    required String prompt,
    int count,
  });

  Future<void> saveContent(ContentItem item);
  
  Stream<List<ContentItem>> getContentList();

  Future<void> deleteContent(String id);
}
