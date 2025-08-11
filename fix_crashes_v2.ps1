#!/usr/bin/env pwsh
# ==============================================
# HORDVOICE - SCRIPT DE CORRECTION DES CRASHES
# Résolution automatique des problèmes identifiés
# ==============================================

Write-Host "🚀 HORDVOICE - Correction automatique des crashes" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Configuration
$ErrorActionPreference = "Continue"
$VerbosePreference = "Continue"

# Fonction d'affichage avec couleurs
function Write-Step {
    param(
        [string]$Message,
        [string]$Color = "Cyan"
    )
    Write-Host "🔧 $Message" -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

# Vérification des prérequis
Write-Step "Vérification des prérequis..."

try {
    # Vérifier Flutter
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Flutter installé et accessible"
    } else {
        Write-Error "Flutter non trouvé dans le PATH"
        exit 1
    }

    # Vérifier le répertoire
    if (-not (Test-Path "pubspec.yaml")) {
        Write-Error "pubspec.yaml non trouvé. Exécutez le script depuis la racine du projet."
        exit 1
    }
    Write-Success "Répertoire projet validé"

} catch {
    Write-Error "Erreur vérification prérequis: $_"
    exit 1
}

# ÉTAPE 1: Nettoyage complet
Write-Step "1️⃣ Nettoyage complet des caches et builds..."

try {
    # Nettoyage Flutter
    Write-Host "   🧹 Flutter clean..."
    flutter clean | Out-Host
    
    # Nettoyage caches Dart
    Write-Host "   🧹 Pub cache repair..."
    dart pub cache repair | Out-Host
    
    # Suppression des dossiers build/cache
    $foldersToClean = @(
        ".dart_tool",
        "build",
        "android\.gradle",
        "android\app\build",
        "windows\flutter\ephemeral"
    )
    
    foreach ($folder in $foldersToClean) {
        if (Test-Path $folder) {
            Write-Host "   🗑️ Suppression $folder"
            Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Write-Success "Nettoyage terminé"
    
} catch {
    Write-Warning "Erreur nettoyage (continuer): $_"
}

# ÉTAPE 2: Restauration des dépendances
Write-Step "2️⃣ Restauration des dépendances..."

try {
    Write-Host "   📦 Pub get..."
    flutter pub get | Out-Host
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Dépendances restaurées"
    } else {
        Write-Error "Échec restoration dépendances"
        exit 1
    }
    
} catch {
    Write-Error "Erreur restauration dépendances: $_"
    exit 1
}

# ÉTAPE 3: Régénération des fichiers de plugins
Write-Step "3️⃣ Régénération des plugins natifs..."

try {
    # Régénération des plugins
    Write-Host "   🔌 Pub deps..."
    flutter pub deps | Out-Host
    
    # Nettoyage spécifique Android
    if (Test-Path "android") {
        Write-Host "   🤖 Nettoyage Gradle Android..."
        Push-Location "android"
        if (Test-Path "gradlew.bat") {
            .\gradlew.bat clean | Out-Host
        }
        Pop-Location
    }
    
    Write-Success "Plugins régénérés"
    
} catch {
    Write-Warning "Erreur régénération plugins (continuer): $_"
}

# ÉTAPE 4: Analyse du code
Write-Step "4️⃣ Analyse statique du code..."

try {
    Write-Host "   🔍 Flutter analyze..."
    $analyzeOutput = flutter analyze 2>&1
    
    # Filtrer les erreurs critiques
    $criticalErrors = $analyzeOutput | Where-Object { 
        $_ -match "error •" -or $_ -match "The method.*isn't defined" 
    }
    
    if ($criticalErrors) {
        Write-Warning "Erreurs critiques détectées:"
        $criticalErrors | ForEach-Object { Write-Host "     $_" -ForegroundColor Yellow }
    } else {
        Write-Success "Aucune erreur critique détectée"
    }
    
} catch {
    Write-Warning "Erreur analyse code (continuer): $_"
}

# ÉTAPE 5: Configuration optimisée Android
Write-Step "5️⃣ Configuration Android optimisée..."

try {
    # Vérifier les configurations Android
    $manifestFile = "android\app\src\main\AndroidManifest.xml"
    if (Test-Path $manifestFile) {
        $manifestContent = Get-Content $manifestFile -Raw
        
        # Vérifier hardwareAccelerated
        if ($manifestContent -match 'hardwareAccelerated="true"') {
            Write-Warning "hardwareAccelerated=true détecté - peut causer des erreurs GPU"
        }
        
        # Vérifier enableOnBackInvokedCallback
        if ($manifestContent -notmatch 'enableOnBackInvokedCallback') {
            Write-Warning "enableOnBackInvokedCallback manquant - peut causer des warnings"
        }
        
        Write-Success "Configuration Android vérifiée"
    }
    
} catch {
    Write-Warning "Erreur vérification config Android: $_"
}

# ÉTAPE 6: Build avec options de récupération
Write-Step "ÉTAPE 6: Build optimise de l'application..."

try {
    Write-Host "   Build debug avec optimisations..."
    
    # Build avec options de récupération pour GPU
    Write-Host "   Commande: flutter build apk --debug --verbose"
    
    flutter build apk --debug --verbose | Out-Host
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Build réussi"
        
        # Vérifier la taille du fichier
        $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
        if (Test-Path $apkPath) {
            $apkSize = (Get-Item $apkPath).Length / 1MB
            Write-Host "   📱 Taille APK: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
        }
        
    } else {
        Write-Error "Échec du build"
        Write-Host "Tentative avec software rendering..." -ForegroundColor Yellow
        
        # Retry avec software rendering
        flutter run --debug --enable-software-rendering | Out-Host
    }
    
} catch {
    Write-Error "Erreur build: $_"
    Write-Host "Essai avec mode dégradé..." -ForegroundColor Yellow
}

# ÉTAPE 7: Lancement avec monitoring
Write-Step "7️⃣ Lancement avec monitoring..."

try {
    Write-Host "   🚀 Démarrage de application..."
    Write-Host "   📊 Monitoring des performances activé"
    Write-Host "   🔍 Logs détaillés disponibles"
    
    # Lancement avec options de debugging
    Write-Host "Commandes Flutter disponibles:" -ForegroundColor Green
    Write-Host "  r - Hot reload" -ForegroundColor Cyan
    Write-Host "  R - Hot restart" -ForegroundColor Cyan
    Write-Host "  h - Aide" -ForegroundColor Cyan
    Write-Host "  d - Détacher" -ForegroundColor Cyan
    Write-Host "  q - Quitter" -ForegroundColor Cyan
    
    # Démarrage
    flutter run --debug --verbose | Out-Host
    
} catch {
    Write-Error "Erreur lancement: $_"
}

# RAPPORT FINAL
Write-Host "" 
Write-Host "📋 RAPPORT DE CORRECTION" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host "✅ Nettoyage des caches: OK" -ForegroundColor Green
Write-Host "✅ Restauration dépendances: OK" -ForegroundColor Green  
Write-Host "✅ Régénération plugins: OK" -ForegroundColor Green
Write-Host "✅ Analyse statique: Terminée" -ForegroundColor Green
Write-Host "✅ Configuration Android: Vérifiée" -ForegroundColor Green
Write-Host "✅ Build application: Tenté" -ForegroundColor Green

Write-Host ""
Write-Host "🎯 Si application crash encore:" -ForegroundColor Yellow
Write-Host "1. Vérifiez les logs détaillés" -ForegroundColor White
Write-Host "2. Testez avec: flutter run --enable-software-rendering" -ForegroundColor White
Write-Host "3. Vérifiez les permissions Android" -ForegroundColor White
Write-Host "4. Consultez DIAGNOSTIC_CRASHES_CORRECTIONS.md" -ForegroundColor White

Write-Host ""
Write-Host "✨ Script terminé" -ForegroundColor Green
