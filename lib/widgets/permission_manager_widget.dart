import 'package:flutter/material.dart';
import '../services/advanced_permission_manager.dart';
import '../services/voice_permission_service.dart';
import '../services/unified_hordvoice_service.dart';
import '../services/azure_speech_service.dart';

/// Widget pour gérer et afficher l'état des permissions
class PermissionManagerWidget extends StatefulWidget {
  const PermissionManagerWidget({super.key});

  @override
  State<PermissionManagerWidget> createState() =>
      _PermissionManagerWidgetState();
}

class _PermissionManagerWidgetState extends State<PermissionManagerWidget> {
  final AdvancedPermissionManager _permissionManager =
      AdvancedPermissionManager();
  final VoicePermissionService _voicePermissionService =
      VoicePermissionService();

  PermissionSummary? _permissionSummary;
  bool _isLoading = false;
  bool _voicePermissionServiceReady = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);

    try {
      // Initialiser le manager de permissions
      await _permissionManager.initialize();

      // Initialiser le service vocal des permissions si possible
      try {
        final unifiedService = UnifiedHordVoiceService();
        final speechService = AzureSpeechService();

        await _voicePermissionService.initialize(
          speechService: speechService,
          hordVoiceService: unifiedService,
        );
        _voicePermissionServiceReady = true;
      } catch (e) {
        debugPrint('Service vocal permissions non disponible: $e');
        _voicePermissionServiceReady = false;
      }

      // Charger le résumé des permissions
      await _loadPermissionSummary();
    } catch (e) {
      debugPrint('Erreur initialisation permissions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPermissionSummary() async {
    try {
      final summary = await _permissionManager.getPermissionSummary();
      setState(() {
        _permissionSummary = summary;
      });
    } catch (e) {
      debugPrint('Erreur chargement résumé permissions: $e');
    }
  }

  Future<void> _requestPermissionsByCategory(String category) async {
    setState(() => _isLoading = true);

    try {
      if (_voicePermissionServiceReady && mounted) {
        // Demande vocale des permissions
        final result = await _voicePermissionService
            .requestPermissionsWithVoice(category: category, context: context);

        _showSnackBar(
          result.wasGranted
              ? 'Permissions $category accordées'
              : 'Permissions $category ${result.userChoice}',
        );
      } else {
        // Demande standard des permissions
        final result = await _permissionManager.requestPermissionsByCategory(
          category,
          context: context,
        );

        _showSnackBar(
          result.success
              ? 'Permissions $category accordées'
              : 'Erreur: ${result.message}',
        );
      }

      // Recharger le résumé
      await _loadPermissionSummary();
    } catch (e) {
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _isLoading = true);

    try {
      if (_voicePermissionServiceReady && mounted) {
        // Demande vocale de toutes les permissions
        final results = await _voicePermissionService
            .requestAllPermissionsWithVoice(context: context);

        final granted = results.where((r) => r.wasGranted).length;
        _showSnackBar('$granted permissions accordées sur ${results.length}');
      } else {
        // Demande standard de toutes les permissions
        final results = await _permissionManager
            .requestAllPermissionsByPriority(context: context);

        final granted = results.where((r) => r.success).length;
        _showSnackBar('$granted permissions accordées sur ${results.length}');
      }

      // Recharger le résumé
      await _loadPermissionSummary();
    } catch (e) {
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildPermissionSummary(),
              const SizedBox(height: 16),
              _buildPermissionCategories(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.security, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          'Gestion des Permissions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (_voicePermissionServiceReady)
          Chip(
            label: const Text('Vocal', style: TextStyle(fontSize: 10)),
            backgroundColor: Colors.green.withOpacity(0.2),
            labelStyle: const TextStyle(color: Colors.green),
          ),
      ],
    );
  }

  Widget _buildPermissionSummary() {
    if (_permissionSummary == null) {
      return const Text('Chargement du résumé...');
    }

    final summary = _permissionSummary!;
    final totalCategories =
        AdvancedPermissionManager.availableCategories.length;
    final completedCategories = summary.categories.values
        .where((status) => status.allGranted)
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'État global: $completedCategories/$totalCategories catégories complètes',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: summary.overallCompletionRate,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              completedCategories == totalCategories
                  ? Colors.green
                  : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Taux de completion: ${(summary.overallCompletionRate * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCategories() {
    if (_permissionSummary == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégories de permissions:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...AdvancedPermissionManager.availableCategories.map(
          (category) => _buildCategoryCard(category),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String category) {
    final categoryInfo = AdvancedPermissionManager.getCategoryInfo(category);
    final categoryStatus = _permissionSummary?.categories[category];

    final isComplete = categoryStatus?.allGranted ?? false;
    final grantedCount = categoryStatus?.grantedCount ?? 0;
    final totalCount = categoryStatus?.totalCount ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _requestPermissionsByCategory(category),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isComplete ? Colors.green : Colors.grey.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
            color: isComplete ? Colors.green.withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isComplete ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryInfo['name'] ?? category,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isComplete ? Colors.green.shade700 : null,
                      ),
                    ),
                    Text(
                      categoryInfo['description'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (totalCount > 0)
                      Text(
                        '$grantedCount/$totalCount permissions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _requestAllPermissions,
                icon: Icon(
                  _voicePermissionServiceReady ? Icons.mic : Icons.security,
                ),
                label: Text(
                  _voicePermissionServiceReady
                      ? 'Demande Vocale Complète'
                      : 'Demander Toutes',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await _permissionManager.openSystemSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Paramètres'),
            ),
          ],
        ),
      ],
    );
  }
}
