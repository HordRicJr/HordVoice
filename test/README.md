# HordVoice Test Configuration

# Test patterns and directories

test/
unit/ # Unit tests for individual components
services/ # Service layer tests
integration/ # Integration tests for complete workflows
mocks/ # Mock implementations for testing

# Coverage configuration

coverage/
lcov.info # Coverage data file
html/ # HTML coverage reports

# Test running scripts

run_tests.sh # Unix/macOS test runner
run_tests.bat # Windows test runner
coverage_config.yaml # Coverage configuration

# Key testing features:

# - Comprehensive unit tests for Azure AI services

# - Integration tests for voice processing pipeline

# - Mock implementations for reliable testing

# - Coverage reporting with 80% target

# - Cross-platform test runners

# - Automated mock generation

# - Error scenario testing

# - Performance and stress testing

# - Stream processing validation

# - Service coordination testing

# Running tests:

# ./run_tests.sh (Unix/macOS)

# run_tests.bat (Windows)

# flutter test (Basic test run)

# flutter test --coverage (With coverage)

# Test coverage targets:

# - Overall: 80% line coverage

# - Azure Speech Service: 85% coverage

# - Azure OpenAI Service: 85% coverage

# - Environment Config: 80% coverage

# - Circuit Breaker: 80% coverage
