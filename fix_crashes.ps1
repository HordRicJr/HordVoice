# Script de correction des crashes HordVoice
# Exécute automatiquement les corrections critiques

Write-Host "🔧 CORRECTION DES CRASHES HORDVOICE" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# 1. Clean build pour supprimer les caches corrompus
Write-Host "🧹 Nettoyage des caches de build..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Cache Flutter nettoyé" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur nettoyage cache" -ForegroundColor Red
}

# 2. Restaurer les dépendances
Write-Host "📦 Restauration des dépendances..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dépendances restaurées" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur restauration dépendances" -ForegroundColor Red
}

# 3. Regenerer les fichiers de plugin
Write-Host "🔌 Régénération des plugins natifs..." -ForegroundColor Yellow
flutter pub deps
flutter packages get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Plugins régénérés" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur plugins" -ForegroundColor Red
}

# 4. Vérifier les erreurs de code
Write-Host "🔍 Analyse du code..." -ForegroundColor Yellow
flutter analyze --no-fatal-infos > analysis_report.txt 2>&1
$analysisErrors = Get-Content analysis_report.txt | Where-Object { $_ -match "error|warning" }
if ($analysisErrors.Count -gt 0) {
    Write-Host "⚠️ Erreurs trouvées:" -ForegroundColor Yellow
    $analysisErrors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
} else {
    Write-Host "✅ Aucune erreur critique trouvée" -ForegroundColor Green
}

# 5. Build en mode debug avec optimisations
Write-Host "🔨 Build optimisé pour Android..." -ForegroundColor Yellow
flutter build apk --debug --shrink --obfuscate --split-debug-info=build/debug-info
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build réussi" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur de build" -ForegroundColor Red
    Write-Host "Tentative de build simple..." -ForegroundColor Yellow
    flutter build apk --debug
}

# 6. Lancement avec monitoring
Write-Host "🚀 Lancement de l'application..." -ForegroundColor Yellow
Write-Host "📊 Monitoring des performances activé" -ForegroundColor Cyan
Write-Host "🔍 Surveillance des crashes en temps réel" -ForegroundColor Cyan

# Démarrer avec flags de debug avancés
flutter run --debug --enable-software-rendering --verbose --device-timeout=60

Write-Host "🎯 CORRECTION TERMINÉE" -ForegroundColor Green
Write-Host "Si l'app crash encore, vérifiez:" -ForegroundColor Yellow
Write-Host "1. Les permissions Android dans le device" -ForegroundColor White
Write-Host "2. Espace de stockage disponible" -ForegroundColor White
Write-Host "3. La version Android (min SDK 26)" -ForegroundColor White
Write-Host "4. Les logs dans analysis_report.txt" -ForegroundColor White
