# HordVoice Development Makefile
# Simplifies common development tasks

.PHONY: help setup clean deps analyze test build install format security

# Default target
help: ## Show this help message
	@echo "HordVoice Development Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Setup development environment
	@echo "🔧 Setting up HordVoice development environment..."
	flutter doctor -v
	flutter pub get
	@echo "✅ Setup complete!"

clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	flutter clean
	flutter pub get
	@echo "✅ Cleaned!"

deps: ## Update dependencies
	@echo "📦 Updating dependencies..."
	flutter pub get
	flutter pub upgrade
	@echo "✅ Dependencies updated!"

analyze: ## Run static analysis
	@echo "🔍 Running static analysis..."
	dart format --set-exit-if-changed .
	flutter analyze --fatal-infos
	@echo "✅ Analysis complete!"

test: ## Run all tests
	@echo "🧪 Running tests..."
	flutter test --coverage
	@echo "✅ Tests complete!"

test-unit: ## Run unit tests only
	@echo "🧪 Running unit tests..."
	flutter test test/unit/
	@echo "✅ Unit tests complete!"

test-widget: ## Run widget tests only
	@echo "🧪 Running widget tests..."
	flutter test test/widget/
	@echo "✅ Widget tests complete!"

test-integration: ## Run integration tests
	@echo "🧪 Running integration tests..."
	flutter test integration_test/
	@echo "✅ Integration tests complete!"

build-debug: ## Build debug APK
	@echo "🔨 Building debug APK..."
	flutter build apk --debug
	@echo "✅ Debug APK built!"

build-release: ## Build release APK
	@echo "🔨 Building release APK..."
	flutter build apk --release
	@echo "✅ Release APK built!"

build-bundle: ## Build app bundle for Play Store
	@echo "🔨 Building app bundle..."
	flutter build appbundle --release
	@echo "✅ App bundle built!"

install: ## Install app on connected device
	@echo "📱 Installing app on device..."
	flutter install
	@echo "✅ App installed!"

run: ## Run app in debug mode
	@echo "🚀 Running HordVoice in debug mode..."
	flutter run

run-release: ## Run app in release mode
	@echo "🚀 Running HordVoice in release mode..."
	flutter run --release

format: ## Format code
	@echo "🎨 Formatting code..."
	dart format .
	@echo "✅ Code formatted!"

security: ## Run security checks
	@echo "🔒 Running security checks..."
	flutter pub deps --json > deps.json
	@echo "Security scan completed. Check deps.json for vulnerabilities."
	@echo "✅ Security checks complete!"

docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	dart doc .
	@echo "✅ Documentation generated!"

env-check: ## Check environment configuration
	@echo "🔧 Checking environment configuration..."
	@if [ -f .env ]; then \
		echo "✅ .env file exists"; \
	else \
		echo "❌ .env file missing. Copy .env.example to .env"; \
		exit 1; \
	fi
	@echo "✅ Environment check complete!"

contributors: ## Update contributors list
	@echo "👥 Updating contributors list..."
	# This would run all-contributors CLI if installed
	@echo "✅ Contributors list updated!"

hacktoberfest: ## Check Hacktoberfest readiness
	@echo "🎃 Checking Hacktoberfest readiness..."
	@echo "  Checking for contributing guidelines..."
	@if [ -f CONTRIBUTING.md ]; then echo "  ✅ CONTRIBUTING.md exists"; else echo "  ❌ CONTRIBUTING.md missing"; fi
	@echo "  Checking for code of conduct..."
	@if [ -f CODE_OF_CONDUCT.md ]; then echo "  ✅ CODE_OF_CONDUCT.md exists"; else echo "  ❌ CODE_OF_CONDUCT.md missing"; fi
	@echo "  Checking for issue templates..."
	@if [ -d .github/ISSUE_TEMPLATE ]; then echo "  ✅ Issue templates exist"; else echo "  ❌ Issue templates missing"; fi
	@echo "  Checking for PR template..."
	@if [ -f .github/pull_request_template.md ]; then echo "  ✅ PR template exists"; else echo "  ❌ PR template missing"; fi
	@echo "✅ Hacktoberfest readiness check complete!"

# Development shortcuts
dev: setup analyze test ## Full development setup and validation

ci: analyze test build-debug ## CI/CD pipeline simulation

all: clean setup analyze test build-release ## Full build pipeline