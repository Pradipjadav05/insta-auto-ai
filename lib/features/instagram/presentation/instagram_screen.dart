import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/providers.dart';
import '../domain/instagram_account.dart';
import '../domain/app_settings.dart';

class InstagramScreen extends ConsumerStatefulWidget {
  const InstagramScreen({super.key});

  @override
  ConsumerState<InstagramScreen> createState() => _InstagramScreenState();
}

class _InstagramScreenState extends ConsumerState<InstagramScreen> {
  final _connectFormKey = GlobalKey<FormState>();
  final _settingsFormKey = GlobalKey<FormState>();

  // Instagram controllers
  final _pageIdController = TextEditingController();
  final _pageNameController = TextEditingController();
  final _accessTokenController = TextEditingController();
  final _igAccountIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _picUrlController = TextEditingController();

  // Settings controllers
  final _adminEmailController = TextEditingController();
  final _geminiKeyController = TextEditingController();
  final _openaiKeyController = TextEditingController();
  final _openaiModelController = TextEditingController(text: 'gpt-4o');

  bool _isConnecting = false;
  bool _isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    // Load initial settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  @override
  void dispose() {
    _pageIdController.dispose();
    _pageNameController.dispose();
    _accessTokenController.dispose();
    _igAccountIdController.dispose();
    _usernameController.dispose();
    _picUrlController.dispose();
    _adminEmailController.dispose();
    _geminiKeyController.dispose();
    _openaiKeyController.dispose();
    _openaiModelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(instagramRepositoryProvider);
    final settings = await repo.getSettings();
    final account = await repo.getConnectedAccount();

    setState(() {
      // Load Settings Form
      _adminEmailController.text = settings.adminEmail;
      _geminiKeyController.text = settings.geminiApiKey;
      _openaiKeyController.text = settings.openaiApiKey;
      _openaiModelController.text = settings.openaiModel;

      // Prefill connect form if already connected
      if (account.isConnected) {
        _pageIdController.text = account.pageId;
        _pageNameController.text = account.pageName;
        _accessTokenController.text = account.accessToken;
        _igAccountIdController.text = account.instagramBusinessAccountId;
        _usernameController.text = account.username;
        _picUrlController.text = account.profilePictureUrl;
      }
    });
  }

  // Connect Instagram credentials
  Future<void> _connectInstagram() async {
    if (!_connectFormKey.currentState!.validate()) return;

    setState(() => _isConnecting = true);

    final account = InstagramAccount(
      isConnected: true,
      pageId: _pageIdController.text.trim(),
      pageName: _pageNameController.text.trim(),
      accessToken: _accessTokenController.text.trim(),
      instagramBusinessAccountId: _igAccountIdController.text.trim(),
      username: _usernameController.text.trim(),
      profilePictureUrl: _picUrlController.text.isNotEmpty
          ? _picUrlController.text.trim()
          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop',
      connectedAt: DateTime.now(),
    );

    try {
      await ref.read(instagramRepositoryProvider).connectAccount(account);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instagram Account Connected successfully!'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e'), backgroundColor: AppTheme.neonPink),
      );
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  // Disconnect Instagram credentials
  Future<void> _disconnectInstagram() async {
    try {
      await ref.read(instagramRepositoryProvider).disconnectAccount();
      setState(() {
        _pageIdController.clear();
        _pageNameController.clear();
        _accessTokenController.clear();
        _igAccountIdController.clear();
        _usernameController.clear();
        _picUrlController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instagram Account Disconnected.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disconnect: $e'), backgroundColor: AppTheme.neonPink),
      );
    }
  }

  // Save Settings
  Future<void> _saveSettings() async {
    if (!_settingsFormKey.currentState!.validate()) return;

    setState(() => _isSavingSettings = true);

    final settings = AppSettings(
      adminEmail: _adminEmailController.text.trim(),
      geminiApiKey: _geminiKeyController.text.trim(),
      openaiApiKey: _openaiKeyController.text.trim(),
      openaiModel: _openaiModelController.text.trim(),
    );

    try {
      await ref.read(instagramRepositoryProvider).saveSettings(settings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application Settings updated!'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: AppTheme.neonPink),
      );
    } finally {
      setState(() => _isSavingSettings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountAsync = ref.watch(instagramAccountProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Title
            Text(
              'Integration Hub',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Link social business accounts and customize third-party AI keys.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instagram Link Panel (Left)
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Instagram Graph Configuration',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      accountAsync.maybeWhen(
                        data: (account) {
                          if (account.isConnected) {
                            return _buildConnectedView(account);
                          }
                          return _buildConnectForm();
                        },
                        orElse: () => const Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                ),

                if (isWide) const SizedBox(width: 32) else const SizedBox(height: 32),

                // Settings Panel (Right)
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'AI Keys & Global Config',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildSettingsForm(),
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

  Widget _buildConnectedView(InstagramAccount account) {
    return GlassCard(
      borderColor: AppTheme.neonGreen.withOpacity(0.2),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: NetworkImage(account.profilePictureUrl),
                backgroundColor: AppTheme.panelDark,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.pageName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${account.username}',
                      style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.neonGreen.withOpacity(0.4)),
                ),
                child: const Text(
                  'Connected',
                  style: TextStyle(color: AppTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          _buildDetailRow('Instagram Page ID', account.pageId),
          _buildDetailRow('Instagram Account ID', account.instagramBusinessAccountId),
          _buildDetailRow('Page Access Token', '••••••••••••••••••••••••'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _disconnectInstagram,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.neonPink),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Disconnect Account', style: TextStyle(color: AppTheme.neonPink)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildConnectForm() {
    return GlassCard(
      borderColor: AppTheme.neonPurple.withOpacity(0.15),
      child: Form(
        key: _connectFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Input Instagram Graph API credentials below to authorize automated publishing workflows.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _pageNameController,
              decoration: const InputDecoration(labelText: 'Page Name', hintText: 'e.g. My Brand Page'),
              validator: (v) => v!.isEmpty ? 'Page Name required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Instagram Handle', hintText: 'e.g. brand_username (no @)'),
              validator: (v) => v!.isEmpty ? 'Handle required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pageIdController,
              decoration: const InputDecoration(labelText: 'Instagram Page ID'),
              validator: (v) => v!.isEmpty ? 'Instagram Page ID required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _igAccountIdController,
              decoration: const InputDecoration(labelText: 'Instagram Business Account ID'),
              validator: (v) => v!.isEmpty ? 'Instagram Business Account ID required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accessTokenController,
              decoration: const InputDecoration(labelText: 'Page Access Token (Permanent)'),
              validator: (v) => v!.isEmpty ? 'Access Token required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _picUrlController,
              decoration: const InputDecoration(labelText: 'Profile Picture URL (Optional)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _connectInstagram,
                child: _isConnecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Connection Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsForm() {
    return GlassCard(
      borderColor: AppTheme.neonPurple.withOpacity(0.15),
      child: Form(
        key: _settingsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _adminEmailController,
              decoration: const InputDecoration(
                labelText: 'Admin Login Email',
                hintText: 'Allowed administrator login email address',
              ),
              validator: (v) => v!.isEmpty ? 'Admin email required' : null,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'API Credentials (Stored Securely in Firestore)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _geminiKeyController,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AI Text Writer credentials...',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _openaiKeyController,
              decoration: const InputDecoration(
                labelText: 'OpenAI API Key (DALL-E)',
                hintText: 'AI Image generator credentials...',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _openaiModelController,
              decoration: const InputDecoration(
                labelText: 'OpenAI Image Model',
                hintText: 'dall-e-3 / dall-e-2',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSavingSettings ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  side: const BorderSide(color: AppTheme.neonCyan),
                ),
                child: _isSavingSettings
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: AppTheme.neonCyan, strokeWidth: 2),
                      )
                    : const Text('Save Settings', style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
