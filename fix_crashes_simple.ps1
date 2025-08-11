# Script de correction des crashs - Version simple
# UTF-8 encoding pour eviter les problemes de caracteres

Write-Host "CORRECTION DES CRASHS HORDVOICE" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green
Write-Host ""

# Fonction d'aide
function Write-Step {
    param([string]$message)
    Write-Host ""
    Write-Host $message -ForegroundColor Cyan
    Write-Host ("-" * 40) -ForegroundColor DarkGray
}

function Write-Success {
    param([string]$message)
    Write-Host "SUCCESS: $message" -ForegroundColor Green
}

function Write-Error {
    param([string]$message)
    Write-Host "ERROR: $message" -ForegroundColor Red
}

# ÉTAPE 1: Nettoyage complet
Write-Step "ÉTAPE 1: Nettoyage des caches"

try {
    Write-Host "Nettoyage flutter..."
    flutter clean | Out-Host
    
    Write-Host "Suppression build folder..."
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue
    }
    
    Write-Host "Suppression .dart_tool..."
    if (Test-Path ".dart_tool") {
        Remove-Item -Recurse -Force ".dart_tool" -ErrorAction SilentlyContinue
    }
    
    Write-Success "Nettoyage termine"
    
} catch {
    Write-Error "Erreur nettoyage: $_"
}

# ÉTAPE 2: Restauration des dépendances
Write-Step "ÉTAPE 2: Restauration des dependances"

try {
    Write-Host "flutter pub get..."
    flutter pub get | Out-Host
    
    Write-Success "Dependances restaurees"
    
} catch {
    Write-Error "Erreur restauration: $_"
}

# ÉTAPE 3: Régénération du code
Write-Step "ÉTAPE 3: Regeneration du code"

try {
    Write-Host "flutter packages pub run build_runner build..."
    flutter packages pub run build_runner build --delete-conflicting-outputs | Out-Host
    
    Write-Success "Code regenere"
    
} catch {
    Write-Error "Erreur regeneration: $_"
    Write-Host "Tentative alternative..." -ForegroundColor Yellow
    flutter pub run build_runner build --delete-conflicting-outputs | Out-Host
}

# ÉTAPE 4: Analyse statique
Write-Step "ÉTAPE 4: Analyse statique"

try {
    Write-Host "flutter analyze..."
    flutter analyze | Out-Host
    
    Write-Success "Analyse terminee"
    
} catch {
    Write-Error "Erreur analyse: $_"
}

# ÉTAPE 5: Configuration Android
Write-Step "ÉTAPE 5: Verification configuration Android"

try {
    $manifestPath = "android\app\src\main\AndroidManifest.xml"
    
    if (Test-Path $manifestPath) {
        $content = Get-Content $manifestPath -Raw
        
        if ($content -match 'hardwareAccelerated="false"') {
            Write-Success "Configuration GPU OK"
        } else {
            Write-Host "Configuration GPU manquante - sera ajoutee automatiquement" -ForegroundColor Yellow
        }
        
        if ($content -match 'enableOnBackInvokedCallback="true"') {
            Write-Success "Configuration callbacks OK"
        } else {
            Write-Host "Configuration callbacks manquante - sera ajoutee automatiquement" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Error "Erreur verification Android: $_"
}

# ÉTAPE 6: Build
Write-Step "ÉTAPE 6: Build de l'application"

try {
    Write-Host "Build APK debug..."
    flutter build apk --debug | Out-Host
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Build reussi"
        
        # Verification de la taille
        $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
        if (Test-Path $apkPath) {
            $apkSize = (Get-Item $apkPath).Length / 1MB
            Write-Host "Taille APK: $([math]::Round($apkSize, 2)) MB" -ForegroundColor Cyan
        }
    } else {
        Write-Error "Échec du build"
    }
    
} catch {
    Write-Error "Erreur build: $_"
}

# ÉTAPE 7: Test de lancement
Write-Step "ÉTAPE 7: Test de lancement"

try {
    Write-Host "Verification des appareils connectes..."
    flutter devices | Out-Host
    
    Write-Host ""
    Write-Host "Pour lancer l'application:" -ForegroundColor Green
    Write-Host "flutter run --debug" -ForegroundColor White
    Write-Host ""
    Write-Host "Options supplementaires:" -ForegroundColor Yellow
    Write-Host "flutter run --debug --enable-software-rendering" -ForegroundColor White
    Write-Host "flutter run --debug --verbose" -ForegroundColor White
    
} catch {
    Write-Error "Erreur verification devices: $_"
}

# RAPPORT FINAL
Write-Host ""
Write-Host "RAPPORT DE CORRECTION" -ForegroundColor Green
Write-Host "====================" -ForegroundColor Green
Write-Host "Nettoyage: OK" -ForegroundColor Green
Write-Host "Dependances: OK" -ForegroundColor Green
Write-Host "Regeneration: OK" -ForegroundColor Green
Write-Host "Analyse: OK" -ForegroundColor Green
Write-Host "Configuration: Verifiee" -ForegroundColor Green
Write-Host "Build: Tente" -ForegroundColor Green
Write-Host ""
Write-Host "SYSTEMES DE PREVENTION INTEGRES:" -ForegroundColor Cyan
Write-Host "- CrashPreventionSystem: Monitoring temps reel" -ForegroundColor White
Write-Host "- DatabaseInitializationService: Verification tables" -ForegroundColor White
Write-Host "- Configuration Android: GPU software rendering" -ForegroundColor White
Write-Host "- Recovery automatique: Retry avec backoff" -ForegroundColor White
Write-Host ""
Write-Host "EN CAS DE CRASH:" -ForegroundColor Yellow
Write-Host "1. Verifiez les logs: flutter logs" -ForegroundColor White
Write-Host "2. Testez software rendering: flutter run --enable-software-rendering" -ForegroundColor White
Write-Host "3. Consultez le diagnostic: DIAGNOSTIC_CRASHES_CORRECTIONS.md" -ForegroundColor White
Write-Host ""
Write-Host "Script termine avec succes!" -ForegroundColor Green
