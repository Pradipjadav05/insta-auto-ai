import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/providers.dart';
import '../domain/content_model.dart';
import '../../scheduler/domain/schedule_model.dart';

class GeneratorScreen extends ConsumerStatefulWidget {
  const GeneratorScreen({super.key});

  @override
  ConsumerState<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends ConsumerState<GeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Input fields
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();
  final _toneController = TextEditingController(text: 'Catchy & Engaging');
  final _keywordsController = TextEditingController();
  final _imagePromptController = TextEditingController();

  MediaType _selectedType = MediaType.feedPost;
  bool _isGeneratingText = false;
  bool _isGeneratingImage = false;

  // Generated results editable state
  final _generatedBodyController = TextEditingController();
  final _generatedCaptionController = TextEditingController();
  List<String> _generatedHashtags = [];
  List<String> _generatedMediaUrls = [];

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _toneController.dispose();
    _keywordsController.dispose();
    _imagePromptController.dispose();
    _generatedBodyController.dispose();
    _generatedCaptionController.dispose();
    super.dispose();
  }

  // Generate text (caption + hashtags) using AIRepository
  Future<void> _generateContentText() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a content prompt first.')),
      );
      return;
    }

    setState(() => _isGeneratingText = true);
    try {
      final aiRepo = ref.read(aiRepositoryProvider);
      final keywordsList = _keywordsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final result = await aiRepo.generateTextContent(
        contentType: _selectedType.displayName,
        prompt: _promptController.text,
        tone: _toneController.text,
        keywords: keywordsList,
      );

      setState(() {
        _generatedBodyController.text = result['body'] ?? '';
        _generatedCaptionController.text = result['caption'] ?? '';
        _generatedHashtags = List<String>.from(result['hashtags'] ?? []);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Content Generated!'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generation failed: ${e.toString()}'),
          backgroundColor: AppTheme.neonPink,
        ),
      );
    } finally {
      setState(() => _isGeneratingText = false);
    }
  }

  // Generate Image using AIRepository
  Future<void> _generateContentImage() async {
    final promptText = _imagePromptController.text.isNotEmpty
        ? _imagePromptController.text
        : _promptController.text;

    if (promptText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an image prompt or general prompt.')),
      );
      return;
    }

    setState(() => _isGeneratingImage = true);
    try {
      final aiRepo = ref.read(aiRepositoryProvider);
      final count = _selectedType == MediaType.carousel ? 3 : 1;
      final urls = await aiRepo.generateImages(prompt: promptText, count: count);

      setState(() {
        _generatedMediaUrls = urls;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Image Assets Generated!'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image generation failed: ${e.toString()}'),
          backgroundColor: AppTheme.neonPink,
        ),
      );
    } finally {
      setState(() => _isGeneratingImage = false);
    }
  }

  // Save content as a draft
  Future<void> _saveAsDraft() async {
    final title = _titleController.text.isNotEmpty ? _titleController.text : 'Draft ${_selectedType.displayName}';
    final contentItem = ContentItem(
      id: const Uuid().v4(),
      title: title,
      body: _generatedBodyController.text,
      caption: _generatedCaptionController.text,
      hashtags: _generatedHashtags,
      mediaUrls: _generatedMediaUrls,
      mediaType: _selectedType,
      createdAt: DateTime.now(),
      status: ContentStatus.draft,
    );

    try {
      await ref.read(aiRepositoryProvider).saveContent(contentItem);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved successfully!'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save draft: $e'), backgroundColor: AppTheme.neonPink),
      );
    }
  }

  // Open Scheduler picker and set scheduled post
  Future<void> _showSchedulerDialog() async {
    if (_generatedCaptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate caption/hashtags before scheduling.')),
      );
      return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );

    if (pickedTime == null) return;

    final scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final title = _titleController.text.isNotEmpty ? _titleController.text : 'Scheduled ${_selectedType.displayName}';
    final contentId = const Uuid().v4();
    final scheduleId = const Uuid().v4();

    final contentItem = ContentItem(
      id: contentId,
      title: title,
      body: _generatedBodyController.text,
      caption: _generatedCaptionController.text,
      hashtags: _generatedHashtags,
      mediaUrls: _generatedMediaUrls,
      mediaType: _selectedType,
      createdAt: DateTime.now(),
      status: ContentStatus.scheduled,
    );

    final scheduleItem = ScheduleItem(
      id: scheduleId,
      contentId: contentId,
      scheduledTime: scheduledDateTime,
      status: ContentStatus.scheduled,
    );

    try {
      // 1. Save Content
      await ref.read(aiRepositoryProvider).saveContent(contentItem);
      // 2. Register Schedule
      await ref.read(schedulerRepositoryProvider).schedulePost(scheduleItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully scheduled for ${scheduledDateTime.toString()}!'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scheduling failed: $e'), backgroundColor: AppTheme.neonPink),
      );
    }
  }

  void _resetForm() {
    _titleController.clear();
    _promptController.clear();
    _keywordsController.clear();
    _imagePromptController.clear();
    _generatedBodyController.clear();
    _generatedCaptionController.clear();
    setState(() {
      _generatedHashtags = [];
      _generatedMediaUrls = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 1000;
    final activeAccountAsync = ref.watch(instagramAccountProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Text(
              'AI Content Lab',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Configure smart prompts to draft and illustrate posts automatically.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Pane (Left)
                Expanded(
                  flex: isWide ? 4 : 0,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassCard(
                          borderColor: AppTheme.neonPurple.withOpacity(0.15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('1. Content Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 20),
                              
                              // Post title (internal reference)
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Internal Reference Title (Optional)',
                                  hintText: 'e.g. Product launch promo',
                                ),
                              ),
                              const SizedBox(height: 16),

                              // MediaType Choice Row
                              const Text('Format Type', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: MediaType.values.map((type) {
                                    final isSelected = _selectedType == type;
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: InkWell(
                                          onTap: () => setState(() => _selectedType = type),
                                          borderRadius: BorderRadius.circular(8),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isSelected ? AppTheme.neonPurple.withOpacity(0.15) : const Color(0xFF101018),
                                              border: Border.all(
                                                  color: isSelected ? AppTheme.neonPurple : AppTheme.panelBorder),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              type.displayName,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                                fontSize: 13,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Prompts Panel
                        GlassCard(
                          borderColor: AppTheme.neonPurple.withOpacity(0.15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('2. AI Text Writer Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _promptController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Post prompt / Core idea',
                                  hintText: 'Describe what the post should talk about (e.g. 5 benefits of Flutter Web)...',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _toneController,
                                      decoration: const InputDecoration(labelText: 'Tone'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _keywordsController,
                                      decoration: const InputDecoration(
                                        labelText: 'Keywords (comma-separated)',
                                        hintText: 'flutter, devops, coding',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _isGeneratingText ? null : _generateContentText,
                                  icon: _isGeneratingText
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.auto_awesome),
                                  label: Text(_isGeneratingText ? 'Generating Copy...' : 'Write Caption with Gemini'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Image Generator Panel
                        GlassCard(
                          borderColor: AppTheme.neonPurple.withOpacity(0.15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('3. Image Design settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _imagePromptController,
                                decoration: const InputDecoration(
                                  labelText: 'Image Prompt (Optional)',
                                  hintText: 'Leave empty to auto-derive from core post prompt...',
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _isGeneratingImage ? null : _generateContentImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    side: const BorderSide(color: AppTheme.neonCyan),
                                  ),
                                  icon: _isGeneratingImage
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonCyan),
                                        )
                                      : const Icon(Icons.palette_outlined, color: AppTheme.neonCyan),
                                  label: Text(
                                    _isGeneratingImage ? 'Illustrating...' : 'Design Mockup Image',
                                    style: const TextStyle(color: AppTheme.neonCyan),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (isWide) const SizedBox(width: 32) else const SizedBox(height: 32),

                // Mock Preview Canvas Pane (Right)
                Expanded(
                  flex: isWide ? 3 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Post Simulator Preview',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Instagram Phone Mockup Layout
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF101018),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: AppTheme.panelBorder, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top phone notch line
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 12, bottom: 8),
                                width: 70,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            // Instagram App Header
                            activeAccountAsync.maybeWhen(
                              data: (account) => ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundImage:
                                      account.isConnected ? NetworkImage(account.profilePictureUrl) : null,
                                  backgroundColor: AppTheme.panelDark,
                                  child: !account.isConnected ? const Icon(Icons.person, size: 16) : null,
                                ),
                                title: Text(
                                  account.isConnected ? account.username : 'your_brand_page',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: const Text('Sponsored', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                trailing: const Icon(Icons.more_vert, size: 18),
                              ),
                              orElse: () => const SizedBox(),
                            ),

                            // Post Image Canvas
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: Container(
                                width: double.infinity,
                                color: const Color(0xFF0C0C12),
                                child: _generatedMediaUrls.isNotEmpty
                                    ? Image.network(
                                        _generatedMediaUrls[0],
                                        fit: BoxFit.cover,
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.photo_library_outlined, size: 40, color: AppTheme.textSecondary),
                                            SizedBox(height: 12),
                                            Text(
                                              'Image Design Area',
                                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),

                            // Action buttons
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.favorite_border, size: 22),
                                  SizedBox(width: 14),
                                  Icon(Icons.mode_comment_outlined, size: 20),
                                  SizedBox(width: 14),
                                  Icon(Icons.send_outlined, size: 20),
                                  Spacer(),
                                  Icon(Icons.bookmark_border, size: 22),
                                ],
                              ),
                            ),

                            // Editable Caption Area inside Phone simulator
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _generatedCaptionController,
                                    maxLines: 4,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      fillColor: Colors.transparent,
                                      hintText: 'Edit generated caption here...',
                                    ),
                                  ),
                                  if (_generatedHashtags.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(
                                        _generatedHashtags.join(' '),
                                        style: const TextStyle(fontSize: 11, color: AppTheme.neonCyan, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions to save
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _generatedCaptionController.text.isNotEmpty ? _saveAsDraft : null,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.panelBorder),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.bookmark_outline, color: AppTheme.textPrimary),
                              label: const Text('Save Draft', style: TextStyle(color: AppTheme.textPrimary)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _generatedCaptionController.text.isNotEmpty ? _showSchedulerDialog : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.neonPurple,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.schedule_send),
                              label: const Text('Schedule Post'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
