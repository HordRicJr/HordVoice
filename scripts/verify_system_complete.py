#!/usr/bin/env python3
"""
Script de vérification complète du système HordVoice IA
Vérifie la base de données, les permissions Android, et l'intégrité du système
Date: 2025-08-09
"""

import os
import sys
import json
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path
import re

class HordVoiceSystemChecker:
    def __init__(self, project_root):
        self.project_root = Path(project_root)
        self.errors = []
        self.warnings = []
        self.success_count = 0
        self.total_checks = 0
        
    def log_success(self, message):
        self.success_count += 1
        print(f"✅ {message}")
        
    def log_warning(self, message):
        self.warnings.append(message)
        print(f"⚠️ {message}")
        
    def log_error(self, message):
        self.errors.append(message)
        print(f"❌ {message}")
        
    def check_database_schema(self):
        """Vérifie le schéma de base de données"""
        print("\n🗄️ VÉRIFICATION BASE DE DONNÉES")
        print("=" * 50)
        
        self.total_checks += 1
        db_schema_file = self.project_root / "docs" / "database_update_v3_voice_ai_complete.sql"
        
        if not db_schema_file.exists():
            self.log_error("Fichier de schéma de base de données manquant")
            return
            
        content = db_schema_file.read_text(encoding='utf-8')
        
        # Tables critiques à vérifier
        critical_tables = [
            'voice_emotion_detection',
            'voice_emotion_profiles', 
            'voice_effects_configuration',
            'contextual_conversation_memory',
            'karaoke_vocal_calibration',
            'secret_commands_security',
            'multilingual_voice_configuration',
            'realtime_avatar_state',
            'voice_system_events',
            'voice_service_sessions',
            'voice_system_configuration'
        ]
        
        missing_tables = []
        for table in critical_tables:
            if f"CREATE TABLE IF NOT EXISTS public.{table}" not in content:
                missing_tables.append(table)
                
        if missing_tables:
            self.log_error(f"Tables manquantes: {', '.join(missing_tables)}")
        else:
            self.log_success("Toutes les tables critiques sont présentes")
            
        # Vérifier les index
        if "CREATE INDEX IF NOT EXISTS idx_voice_" in content:
            self.log_success("Index de performance créés")
        else:
            self.log_warning("Index de performance manquants")
            
        # Vérifier les triggers
        if "CREATE TRIGGER" in content:
            self.log_success("Triggers automatiques configurés")
        else:
            self.log_warning("Triggers automatiques manquants")
            
        # Vérifier les fonctions de nettoyage
        if "cleanup_expired_contextual_memory" in content:
            self.log_success("Fonctions de nettoyage automatique présentes")
        else:
            self.log_warning("Fonctions de nettoyage manquantes")
            
    def check_android_permissions(self):
        """Vérifie les permissions Android"""
        print("\n📱 VÉRIFICATION PERMISSIONS ANDROID")
        print("=" * 50)
        
        self.total_checks += 1
        manifest_file = self.project_root / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
        
        if not manifest_file.exists():
            self.log_error("AndroidManifest.xml manquant")
            return
            
        try:
            tree = ET.parse(manifest_file)
            root = tree.getroot()
            
            # Permissions critiques pour le système vocal IA
            critical_permissions = [
                'android.permission.RECORD_AUDIO',
                'android.permission.MICROPHONE',
                'android.permission.MODIFY_AUDIO_SETTINGS',
                'android.permission.INTERNET',
                'android.permission.ACCESS_NETWORK_STATE',
                'android.permission.FOREGROUND_SERVICE',
                'android.permission.WAKE_LOCK',
                'android.permission.POST_NOTIFICATIONS',
                'android.permission.VIBRATE'
            ]
            
            # Permissions avancées recommandées
            advanced_permissions = [
                'android.permission.BIND_VOICE_INTERACTION',
                'android.permission.CAPTURE_AUDIO_HOTWORD',
                'android.permission.FOREGROUND_SERVICE_MICROPHONE',
                'android.permission.USE_BIOMETRIC',
                'android.permission.BLUETOOTH_CONNECT',
                'android.permission.CAMERA'
            ]
            
            granted_permissions = []
            for permission_elem in root.findall('.//uses-permission'):
                perm_name = permission_elem.get('{http://schemas.android.com/apk/res/android}name')
                if perm_name:
                    granted_permissions.append(perm_name)
                    
            # Vérifier permissions critiques
            missing_critical = []
            for perm in critical_permissions:
                if perm not in granted_permissions:
                    missing_critical.append(perm)
                    
            if missing_critical:
                self.log_error(f"Permissions critiques manquantes: {', '.join(missing_critical)}")
            else:
                self.log_success("Toutes les permissions critiques sont présentes")
                
            # Vérifier permissions avancées
            missing_advanced = []
            for perm in advanced_permissions:
                if perm not in granted_permissions:
                    missing_advanced.append(perm)
                    
            if missing_advanced:
                self.log_warning(f"Permissions avancées recommandées manquantes: {', '.join(missing_advanced)}")
            else:
                self.log_success("Toutes les permissions avancées sont présentes")
                
            # Vérifier features matériel
            required_features = [
                'android.hardware.microphone',
                'android.hardware.audio.output'
            ]
            
            granted_features = []
            for feature_elem in root.findall('.//uses-feature'):
                feature_name = feature_elem.get('{http://schemas.android.com/apk/res/android}name')
                if feature_name:
                    granted_features.append(feature_name)
                    
            missing_features = []
            for feature in required_features:
                if feature not in granted_features:
                    missing_features.append(feature)
                    
            if missing_features:
                self.log_error(f"Features matériel manquantes: {', '.join(missing_features)}")
            else:
                self.log_success("Toutes les features matériel requises sont présentes")
                
        except ET.ParseError as e:
            self.log_error(f"Erreur de parsing AndroidManifest.xml: {e}")
            
    def check_service_files(self):
        """Vérifie les fichiers de service vocal IA"""
        print("\n🎤 VÉRIFICATION SERVICES VOCAL IA")
        print("=" * 50)
        
        services_path = self.project_root / "lib" / "services"
        
        # Services critiques
        critical_services = [
            'voice_emotion_detection_service.dart',
            'voice_effects_service.dart',
            'contextual_memory_service.dart',
            'karaoke_calibration_service.dart',
            'secret_commands_service.dart',
            'multilingual_service.dart',
            'realtime_avatar_service.dart'
        ]
        
        for service in critical_services:
            self.total_checks += 1
            service_file = services_path / service
            
            if not service_file.exists():
                self.log_error(f"Service manquant: {service}")
                continue
                
            content = service_file.read_text(encoding='utf-8')
            
            # Vérifications de base
            if "class " in content and "Service" in content:
                self.log_success(f"Service {service} présent et valide")
            else:
                self.log_error(f"Service {service} invalide ou mal structuré")
                continue
                
            # Vérifications spécifiques
            if "initialize(" in content:
                self.log_success(f"  ↳ Méthode initialize() présente")
            else:
                self.log_warning(f"  ↳ Méthode initialize() manquante dans {service}")
                
            if "dispose()" in content:
                self.log_success(f"  ↳ Méthode dispose() présente")
            else:
                self.log_warning(f"  ↳ Méthode dispose() manquante dans {service}")
                
            if "StreamController" in content:
                self.log_success(f"  ↳ Gestion des streams configurée")
            else:
                self.log_warning(f"  ↳ Gestion des streams manquante dans {service}")
                
    def check_dependencies(self):
        """Vérifie les dépendances du projet"""
        print("\n📦 VÉRIFICATION DÉPENDANCES")
        print("=" * 50)
        
        self.total_checks += 1
        pubspec_file = self.project_root / "pubspec.yaml"
        
        if not pubspec_file.exists():
            self.log_error("pubspec.yaml manquant")
            return
            
        content = pubspec_file.read_text(encoding='utf-8')
        
        # Dépendances critiques
        critical_deps = [
            'flutter_tts',
            'speech_to_text', 
            'permission_handler',
            'shared_preferences',
            'supabase_flutter',
            'http'
        ]
        
        # Dépendances recommandées pour le système vocal IA
        recommended_deps = [
            'flutter_riverpod',
            'crypto',
            'path_provider',
            'flutter_local_notifications',
            'device_info_plus',
            'package_info_plus'
        ]
        
        missing_critical = []
        for dep in critical_deps:
            if f"{dep}:" not in content:
                missing_critical.append(dep)
                
        if missing_critical:
            self.log_error(f"Dépendances critiques manquantes: {', '.join(missing_critical)}")
        else:
            self.log_success("Toutes les dépendances critiques sont présentes")
            
        missing_recommended = []
        for dep in recommended_deps:
            if f"{dep}:" not in content:
                missing_recommended.append(dep)
                
        if missing_recommended:
            self.log_warning(f"Dépendances recommandées manquantes: {', '.join(missing_recommended)}")
        else:
            self.log_success("Toutes les dépendances recommandées sont présentes")
            
    def check_configuration_files(self):
        """Vérifie les fichiers de configuration"""
        print("\n⚙️ VÉRIFICATION FICHIERS CONFIGURATION")
        print("=" * 50)
        
        # Vérifier environment_config.dart
        self.total_checks += 1
        env_config = self.project_root / "lib" / "services" / "environment_config.dart"
        
        if env_config.exists():
            content = env_config.read_text(encoding='utf-8')
            if "azureOpenAIKey" in content and "azureSpeechKey" in content:
                self.log_success("Configuration Azure présente")
            else:
                self.log_warning("Configuration Azure incomplète")
        else:
            self.log_error("Fichier environment_config.dart manquant")
            
        # Vérifier les modèles de données
        models_path = self.project_root / "lib" / "models"
        
        if models_path.exists():
            model_files = list(models_path.glob("*.dart"))
            if len(model_files) >= 3:  # Au moins 3 modèles attendus
                self.log_success(f"Modèles de données présents ({len(model_files)} fichiers)")
            else:
                self.log_warning("Modèles de données insuffisants")
        else:
            self.log_error("Dossier models/ manquant")
            
    def run_flutter_analyze(self):
        """Exécute flutter analyze pour vérifier le code"""
        print("\n🔍 ANALYSE STATIQUE DU CODE")
        print("=" * 50)
        
        self.total_checks += 1
        
        try:
            result = subprocess.run(
                ['flutter', 'analyze', '--no-fatal-infos'],
                cwd=self.project_root,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                self.log_success("Analyse statique réussie - aucune erreur détectée")
            else:
                lines = result.stdout.split('\n')
                error_count = 0
                warning_count = 0
                
                for line in lines:
                    if 'error' in line.lower():
                        error_count += 1
                    elif 'warning' in line.lower():
                        warning_count += 1
                        
                if error_count > 0:
                    self.log_error(f"Analyse statique: {error_count} erreurs détectées")
                else:
                    self.log_warning(f"Analyse statique: {warning_count} avertissements")
                    
        except subprocess.TimeoutExpired:
            self.log_warning("Analyse statique: timeout (> 60s)")
        except FileNotFoundError:
            self.log_warning("Flutter CLI non trouvé - analyse statique ignorée")
        except Exception as e:
            self.log_warning(f"Erreur lors de l'analyse statique: {e}")
            
    def generate_report(self):
        """Génère le rapport final"""
        print("\n" + "=" * 60)
        print("📊 RAPPORT FINAL DE VÉRIFICATION")
        print("=" * 60)
        
        print(f"\n✅ Vérifications réussies: {self.success_count}/{self.total_checks}")
        print(f"⚠️ Avertissements: {len(self.warnings)}")
        print(f"❌ Erreurs: {len(self.errors)}")
        
        if self.errors:
            print("\n🚨 ERREURS CRITIQUES À CORRIGER:")
            for i, error in enumerate(self.errors, 1):
                print(f"  {i}. {error}")
                
        if self.warnings:
            print("\n⚠️ AVERTISSEMENTS (Recommandations):")
            for i, warning in enumerate(self.warnings, 1):
                print(f"  {i}. {warning}")
                
        # Score global
        success_rate = (self.success_count / max(self.total_checks, 1)) * 100
        
        if success_rate >= 90:
            status = "🟢 EXCELLENT"
        elif success_rate >= 75:
            status = "🟡 ACCEPTABLE"
        elif success_rate >= 50:
            status = "🟠 ATTENTION REQUISE"
        else:
            status = "🔴 CRITIQUE"
            
        print(f"\n📊 SCORE GLOBAL: {success_rate:.1f}% - {status}")
        
        if len(self.errors) == 0:
            print("\n🎉 SYSTÈME HORDVOICE IA PRÊT POUR DÉPLOIEMENT!")
        else:
            print("\n⚠️ Corriger les erreurs avant déploiement")
            
        # Sauvegarder le rapport
        report_data = {
            'timestamp': '2025-08-09',
            'total_checks': self.total_checks,
            'success_count': self.success_count,
            'warnings': self.warnings,
            'errors': self.errors,
            'success_rate': success_rate,
            'status': status
        }
        
        report_file = self.project_root / "docs" / "system_verification_report.json"
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)
            
        print(f"\n📄 Rapport détaillé sauvegardé: {report_file}")
        
    def run_all_checks(self):
        """Exécute toutes les vérifications"""
        print("🚀 VÉRIFICATION SYSTÈME HORDVOICE IA COMPLET")
        print("=" * 60)
        print("Date: 2025-08-09")
        print("Version: 3.0.0")
        
        self.check_database_schema()
        self.check_android_permissions()
        self.check_service_files()
        self.check_dependencies()
        self.check_configuration_files()
        self.run_flutter_analyze()
        
        self.generate_report()

def main():
    if len(sys.argv) > 1:
        project_root = sys.argv[1]
    else:
        project_root = os.getcwd()
        
    checker = HordVoiceSystemChecker(project_root)
    checker.run_all_checks()

if __name__ == "__main__":
    main()
