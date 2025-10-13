import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/phone_settings_service.dart';
import '../painters/spatial_universe_painter.dart' as spatial_painter;
import 'spatial_voice_onboarding_view.dart';

/// Page d'autorisations prioritaires avec design spatial (style splash screen)
/// Doit être validée avant l'accès à l'onboarding principal
class PriorityPermissionsView extends StatefulWidget {
  const PriorityPermissionsView({super.key});

  @override
  State<PriorityPermissionsView> createState() => _PriorityPermissionsViewState();
}

class _PriorityPermissionsViewState extends State<PriorityPermissionsView>
    with TickerProviderStateMixin {
  // Controllers pour les animations spatiales
  late AnimationController _universeController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _universeRotation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Services
  final PhoneSettingsService _settingsService = PhoneSettingsService();

  // État de la page
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Initialisation...';

  // Permissions prioritaires requises
  final List<Permission> _priorityPermissions = [
    Permission.microphone,
    Permission.speech,
  ];

  Map<Permission, PermissionStatus> _permissionStates = {};
  int _currentPermissionIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePermissions();
  }

  void _initializeAnimations() {
    // Rotation continue de l'univers spatial
    _universeController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _universeRotation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _universeController,
      curve: Curves.linear,
    ));

    // Pulsation pour les éléments interactifs
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Fade pour les transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Scale pour les boutons
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // Démarrer les animations
    _universeController.repeat();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializePermissions() async {
    setState(() {
      _statusMessage = 'Analyse des autorisations...';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    // Vérifier l'état actuel des permissions prioritaires
    for (final permission in _priorityPermissions) {
      final status = await permission.status;
      _permissionStates[permission] = status;
    }

    setState(() {
      _isInitialized = true;
      _statusMessage = 'Autorisations prioritaires requises';
    });

    await _fadeController.forward();
  }

  Future<void> _requestCurrentPermission() async {
    if (_currentPermissionIndex >= _priorityPermissions.length) {
      await _checkAllPermissionsGranted();
      return;
    }

    final permission = _priorityPermissions[_currentPermissionIndex];
    
    setState(() {
      _isProcessing = true;
      _statusMessage = _getPermissionMessage(permission);
    });

    try {
      final status = await permission.request();
      _permissionStates[permission] = status;

      if (status == PermissionStatus.granted) {
        // Permission accordée, passer à la suivante
        _currentPermissionIndex++;
        await Future.delayed(const Duration(milliseconds: 500));
        await _requestCurrentPermission();
      } else if (status == PermissionStatus.permanentlyDenied) {
        // Redirection vers les paramètres
        await _handlePermanentlyDenied(permission);
      } else {
        // Permission refusée temporairement
        await _handleDenied(permission);
      }
    } catch (e) {
      debugPrint('Erreur demande permission: $e');
      await _handleError(permission);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handlePermanentlyDenied(Permission permission) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Autorisation requise',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPermissionIcon(permission),
              color: Colors.blue,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _getPermissionExplanation(permission),
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: Text(
                'Cette autorisation doit être activée manuellement dans les paramètres.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Ignorer', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await _settingsService.openAppSettings();
            },
            child: Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDenied(Permission permission) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Autorisation nécessaire',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPermissionIcon(permission),
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _getPermissionExplanation(permission),
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _currentPermissionIndex++; // Passer à la suivante
              _requestCurrentPermission();
            },
            child: Text('Ignorer', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _requestCurrentPermission(); // Redemander
            },
            child: Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleError(Permission permission) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur lors de la demande d\'autorisation'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _checkAllPermissionsGranted() async {
    // Vérifier si toutes les permissions prioritaires sont accordées
    bool allGranted = true;
    for (final permission in _priorityPermissions) {
      final status = _permissionStates[permission] ?? PermissionStatus.denied;
      if (status != PermissionStatus.granted) {
        allGranted = false;
        break;
      }
    }

    if (allGranted) {
      // Marquer les permissions prioritaires comme accordées
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('priority_permissions_granted', true);

      setState(() {
        _statusMessage = 'Autorisations configurées !';
      });

      await Future.delayed(const Duration(milliseconds: 1000));

      // Redirection vers l'onboarding principal
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => FadeTransition(
              opacity: animation,
              child: const SpatialVoiceOnboardingView(),
            ),
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } else {
      // Proposer de continuer malgré tout ou recommencer
      await _showContinueDialog();
    }
  }

  Future<void> _showContinueDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Autorisations incomplètes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              'Certaines autorisations prioritaires ne sont pas accordées. '
              'HordVoice fonctionnera avec des fonctionnalités limitées.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _currentPermissionIndex = 0; // Recommencer
              _requestCurrentPermission();
            },
            child: Text('Recommencer', style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await _checkAllPermissionsGranted();
            },
            child: Text('Continuer'),
          ),
        ],
      ),
    );
  }

  String _getPermissionMessage(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return 'Autorisation microphone requise';
      case Permission.speech:
        return 'Autorisation reconnaissance vocale requise';
      default:
        return 'Autorisation requise';
    }
  }

  IconData _getPermissionIcon(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return Icons.mic;
      case Permission.speech:
        return Icons.record_voice_over;
      default:
        return Icons.security;
    }
  }

  String _getPermissionExplanation(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return 'Le microphone est essentiel pour que HordVoice puisse entendre vos commandes vocales. Sans cette autorisation, l\'assistant ne peut pas fonctionner.';
      case Permission.speech:
        return 'La reconnaissance vocale permet à HordVoice de comprendre et traiter vos commandes. Cette fonctionnalité est au cœur de l\'expérience utilisateur.';
      default:
        return 'Cette autorisation est nécessaire pour le bon fonctionnement de HordVoice.';
    }
  }

  @override
  void dispose() {
    _universeController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Univers spatial de fond (identique au splash screen)
          _buildSpatialBackground(),

          // Interface des permissions
          if (_isInitialized) _buildPermissionsInterface(),

          // Overlay de chargement
          if (!_isInitialized) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSpatialBackground() {
    return AnimatedBuilder(
      animation: _universeRotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _universeRotation.value * 0.1, // Rotation très lente
          child: CustomPaint(
            painter: spatial_painter.SpatialUniversePainter(
              animationValue: _universeRotation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo HordVoice
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
            ).createShader(bounds),
            child: Text(
              'HordVoice',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // Indicateur de chargement
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 20),
          
          Text(
            _statusMessage,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsInterface() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo et titre
                  _buildHeader(),
                  const SizedBox(height: 60),
                  
                  // Permission actuelle
                  if (_currentPermissionIndex < _priorityPermissions.length)
                    _buildPermissionCard(),
                  
                  const SizedBox(height: 40),
                  
                  // Bouton d'action principal
                  _buildActionButton(),
                  
                  const SizedBox(height: 20),
                  
                  // Progression
                  _buildProgressIndicator(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo avec effet de pulsation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.security, size: 40, color: Colors.white),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        
        // Titre
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
          ).createShader(bounds),
          child: Text(
            'Autorisations Prioritaires',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        
        Text(
          'Configurons les autorisations essentielles\npour votre expérience vocale',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPermissionCard() {
    final permission = _priorityPermissions[_currentPermissionIndex];
    final status = _permissionStates[permission] ?? PermissionStatus.denied;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Icône de la permission
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getPermissionColor(status).withOpacity(0.2),
              border: Border.all(
                color: _getPermissionColor(status),
                width: 2,
              ),
            ),
            child: Icon(
              _getPermissionIcon(permission),
              color: _getPermissionColor(status),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          
          // Nom de la permission
          Text(
            _getPermissionName(permission),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            _getPermissionExplanation(permission),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          // État actuel
          if (status != PermissionStatus.denied) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPermissionColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getPermissionColor(status).withOpacity(0.5),
                ),
              ),
              child: Text(
                _getPermissionStatusText(status),
                style: TextStyle(
                  color: _getPermissionColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () async {
                await _scaleController.forward();
                await _scaleController.reverse();
                await _requestCurrentPermission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 8,
                shadowColor: Colors.blue.withOpacity(0.3),
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Traitement...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.security, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Autoriser',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentPermissionIndex + 1) / _priorityPermissions.length;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '${_currentPermissionIndex + 1}/${_priorityPermissions.length}',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ],
    );
  }

  Color _getPermissionColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.blue;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.microphone:
        return 'Microphone';
      case Permission.speech:
        return 'Reconnaissance Vocale';
      default:
        return 'Autorisation';
    }
  }

  String _getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Accordée';
      case PermissionStatus.denied:
        return 'En attente';
      case PermissionStatus.permanentlyDenied:
        return 'Refusée définitivement';
      case PermissionStatus.restricted:
        return 'Restreinte';
      default:
        return 'Inconnue';
    }
  }
}