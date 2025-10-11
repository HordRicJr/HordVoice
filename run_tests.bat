@echo off
REM HordVoice Test Runner Script for Windows
REM This script runs all tests and generates coverage reports

echo 🧪 Starting HordVoice Azure AI Services Test Suite
echo ==================================================

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    exit /b 1
)

echo [INFO] Flutter version:
flutter --version

REM Clean previous builds
echo [INFO] Cleaning previous builds...
flutter clean
flutter pub get

REM Generate mocks if build_runner is available
echo [INFO] Generating mocks...
flutter packages pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% equ 0 (
    echo [SUCCESS] Mocks generated successfully
) else (
    echo [WARNING] Mock generation failed or build_runner not found
)

REM Run unit tests
echo [INFO] Running unit tests...
flutter test test\unit\ --coverage
set UNIT_TEST_EXIT_CODE=%ERRORLEVEL%

if %UNIT_TEST_EXIT_CODE% equ 0 (
    echo [SUCCESS] Unit tests passed
) else (
    echo [ERROR] Unit tests failed with exit code %UNIT_TEST_EXIT_CODE%
)

REM Run integration tests
echo [INFO] Running integration tests...
flutter test test\integration\
set INTEGRATION_TEST_EXIT_CODE=%ERRORLEVEL%

if %INTEGRATION_TEST_EXIT_CODE% equ 0 (
    echo [SUCCESS] Integration tests passed
) else (
    echo [ERROR] Integration tests failed with exit code %INTEGRATION_TEST_EXIT_CODE%
)

REM Generate coverage report
if %UNIT_TEST_EXIT_CODE% equ 0 (
    echo [INFO] Generating coverage report...
    
    if exist coverage\lcov.info (
        echo [INFO] Coverage file found: coverage\lcov.info
        
        REM Display basic coverage info
        echo [INFO] Coverage Summary:
        echo ==================
        
        REM Count total and hit lines (basic Windows parsing)
        findstr /C:"DA:" coverage\lcov.info > temp_total.txt
        findstr /C:",1" coverage\lcov.info > temp_hit.txt
        
        for /f %%A in ('type temp_total.txt ^| find /c /v ""') do set TOTAL_LINES=%%A
        for /f %%A in ('type temp_hit.txt ^| find /c /v ""') do set HIT_LINES=%%A
        
        del temp_total.txt temp_hit.txt
        
        if %TOTAL_LINES% gtr 0 (
            set /a COVERAGE_PERCENT=%HIT_LINES% * 100 / %TOTAL_LINES%
            echo Line Coverage: !COVERAGE_PERCENT!%% ^(!HIT_LINES!/%TOTAL_LINES% lines^)
            
            if !COVERAGE_PERCENT! geq 80 (
                echo [SUCCESS] Coverage target met: !COVERAGE_PERCENT!%% ^>= 80%%
            ) else (
                echo [WARNING] Coverage below target: !COVERAGE_PERCENT!%% ^< 80%%
            )
        )
    ) else (
        echo [WARNING] Coverage file not found
    )
) else (
    echo [WARNING] Skipping coverage report due to test failures
)

REM Run linting
echo [INFO] Running Flutter analyzer...
flutter analyze
set ANALYZE_EXIT_CODE=%ERRORLEVEL%

if %ANALYZE_EXIT_CODE% equ 0 (
    echo [SUCCESS] No analyzer issues found
) else (
    echo [WARNING] Analyzer found issues ^(exit code: %ANALYZE_EXIT_CODE%^)
)

REM Summary
echo.
echo 🏁 Test Suite Summary
echo ====================
if %UNIT_TEST_EXIT_CODE% equ 0 (
    echo Unit Tests: ✅ PASSED
) else (
    echo Unit Tests: ❌ FAILED
)

if %INTEGRATION_TEST_EXIT_CODE% equ 0 (
    echo Integration Tests: ✅ PASSED
) else (
    echo Integration Tests: ❌ FAILED
)

if %ANALYZE_EXIT_CODE% equ 0 (
    echo Analyzer: ✅ PASSED
) else (
    echo Analyzer: ⚠️  WARNINGS
)

REM Overall exit code
set OVERALL_EXIT_CODE=0
if %UNIT_TEST_EXIT_CODE% neq 0 (
    set OVERALL_EXIT_CODE=1
)
if %INTEGRATION_TEST_EXIT_CODE% neq 0 (
    set OVERALL_EXIT_CODE=1
)

if %OVERALL_EXIT_CODE% neq 0 (
    echo [ERROR] Some tests failed
) else (
    echo [SUCCESS] All tests passed! 🎉
)

echo.
echo 💡 Next Steps:
echo - Review coverage report in coverage\html\index.html
echo - Fix any failing tests or analyzer issues
echo - Update documentation if needed
echo - Ready for Hacktoberfest PR! 🎃

exit /b %OVERALL_EXIT_CODE%