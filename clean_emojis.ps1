# Script de nettoyage des emojis dans le projet HordVoice
# Usage: powershell -ExecutionPolicy Bypass -File clean_emojis.ps1

Write-Host "Debut du nettoyage des emojis dans le projet HordVoice..." -ForegroundColor Green

# Fonction pour nettoyer un fichier
function Remove-FileEmojis($filePath) {
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw -Encoding UTF8
        $originalContent = $content
        
        # Regex pour capturer la plupart des emojis Unicode
        $emojiPattern = '[\u{1F300}-\u{1F5FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F700}-\u{1F77F}]|[\u{1F780}-\u{1F7FF}]|[\u{1F800}-\u{1F8FF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA00}-\u{1FA6F}]|[\u{1FA70}-\u{1FAFF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]'
        
        # Supprimer les emojis
        $content = $content -replace $emojiPattern, ""
        
        # Nettoyer les espaces doubles consecutifs
        $content = $content -replace "\s{2,}", " "
        $content = $content -replace "\n\s*\n\s*\n", "`n`n"
        
        if ($content -ne $originalContent) {
            Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline
            Write-Host "Nettoye: $filePath" -ForegroundColor Yellow
        }
    }
}

# Nettoyer tous les fichiers markdown
Write-Host "Nettoyage des fichiers .md..." -ForegroundColor Cyan
Get-ChildItem -Path . -Filter "*.md" -Recurse | ForEach-Object {
    Remove-FileEmojis $_.FullName
}

# Nettoyer tous les fichiers dart
Write-Host "Nettoyage des fichiers .dart..." -ForegroundColor Cyan
Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | ForEach-Object {
    Remove-FileEmojis $_.FullName
}

Write-Host "Nettoyage termine!" -ForegroundColor Green
Write-Host "Verifiez les fichiers modifies avec: git status" -ForegroundColor Blue
