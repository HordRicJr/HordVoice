#!/bin/bash

# HordVoice Test Runner Script
# This script runs all tests and generates coverage reports

echo "🧪 Starting HordVoice Azure AI Services Test Suite"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Generate mocks if build_runner is available
print_status "Generating mocks..."
if flutter pub deps | grep -q "build_runner"; then
    flutter packages pub run build_runner build --delete-conflicting-outputs
    print_success "Mocks generated successfully"
else
    print_warning "build_runner not found, skipping mock generation"
fi

# Run unit tests
print_status "Running unit tests..."
flutter test test/unit/ --coverage
UNIT_TEST_EXIT_CODE=$?

if [ $UNIT_TEST_EXIT_CODE -eq 0 ]; then
    print_success "Unit tests passed"
else
    print_error "Unit tests failed with exit code $UNIT_TEST_EXIT_CODE"
fi

# Run integration tests
print_status "Running integration tests..."
flutter test test/integration/
INTEGRATION_TEST_EXIT_CODE=$?

if [ $INTEGRATION_TEST_EXIT_CODE -eq 0 ]; then
    print_success "Integration tests passed"
else
    print_error "Integration tests failed with exit code $INTEGRATION_TEST_EXIT_CODE"
fi

# Generate coverage report
if [ $UNIT_TEST_EXIT_CODE -eq 0 ]; then
    print_status "Generating coverage report..."
    
    # Check if genhtml is available (part of lcov)
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        print_success "HTML coverage report generated in coverage/html/"
        
        # Open coverage report if on macOS or Linux with desktop environment
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open coverage/html/index.html
        elif [[ "$OSTYPE" == "linux-gnu"* ]] && command -v xdg-open &> /dev/null; then
            xdg-open coverage/html/index.html
        fi
    else
        print_warning "genhtml not found. Install lcov to generate HTML reports: brew install lcov (macOS) or apt-get install lcov (Ubuntu)"
    fi
    
    # Display coverage summary
    if [ -f "coverage/lcov.info" ]; then
        print_status "Coverage Summary:"
        echo "=================="
        
        # Extract coverage percentage (basic parsing)
        if command -v lcov &> /dev/null; then
            lcov --summary coverage/lcov.info
        else
            # Basic coverage info extraction
            TOTAL_LINES=$(grep -c "DA:" coverage/lcov.info)
            HIT_LINES=$(grep "DA:" coverage/lcov.info | grep -c ",1")
            
            if [ $TOTAL_LINES -gt 0 ]; then
                COVERAGE_PERCENT=$((HIT_LINES * 100 / TOTAL_LINES))
                echo "Line Coverage: $COVERAGE_PERCENT% ($HIT_LINES/$TOTAL_LINES lines)"
                
                if [ $COVERAGE_PERCENT -ge 80 ]; then
                    print_success "Coverage target met: $COVERAGE_PERCENT% >= 80%"
                else
                    print_warning "Coverage below target: $COVERAGE_PERCENT% < 80%"
                fi
            fi
        fi
    fi
else
    print_warning "Skipping coverage report due to test failures"
fi

# Run linting
print_status "Running Flutter analyzer..."
flutter analyze
ANALYZE_EXIT_CODE=$?

if [ $ANALYZE_EXIT_CODE -eq 0 ]; then
    print_success "No analyzer issues found"
else
    print_warning "Analyzer found issues (exit code: $ANALYZE_EXIT_CODE)"
fi

# Summary
echo ""
echo "🏁 Test Suite Summary"
echo "===================="
echo "Unit Tests: $([ $UNIT_TEST_EXIT_CODE -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")"
echo "Integration Tests: $([ $INTEGRATION_TEST_EXIT_CODE -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")"
echo "Analyzer: $([ $ANALYZE_EXIT_CODE -eq 0 ] && echo "✅ PASSED" || echo "⚠️  WARNINGS")"

# Overall exit code
OVERALL_EXIT_CODE=0
if [ $UNIT_TEST_EXIT_CODE -ne 0 ] || [ $INTEGRATION_TEST_EXIT_CODE -ne 0 ]; then
    OVERALL_EXIT_CODE=1
    print_error "Some tests failed"
else
    print_success "All tests passed! 🎉"
fi

echo ""
echo "💡 Next Steps:"
echo "- Review coverage report in coverage/html/index.html"
echo "- Fix any failing tests or analyzer issues"
echo "- Update documentation if needed"
echo "- Ready for Hacktoberfest PR! 🎃"

exit $OVERALL_EXIT_CODE