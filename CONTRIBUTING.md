# Contributing to HordVoice 🎤

Welcome to HordVoice! We're excited that you want to contribute to our intelligent voice assistant project. This guide will help you get started.

## 🎃 Hacktoberfest 2025

HordVoice is proudly participating in **Hacktoberfest 2025**! We welcome meaningful contributions that help improve our AI-powered voice assistant.

### 🏷️ Hacktoberfest Labels
- `hacktoberfest` - Issues/PRs eligible for Hacktoberfest
- `good first issue` - Perfect for newcomers
- `hacktoberfest-accepted` - Approved Hacktoberfest contributions

### 🎯 Quality Standards
To ensure your Hacktoberfest contribution is valuable:
- ✅ Make meaningful changes that improve the project
- ✅ Follow our coding standards and guidelines
- ✅ Test your changes thoroughly
- ✅ Write clear commit messages and PR descriptions
- ❌ Avoid trivial changes (typos, whitespace, etc.)
- ❌ Don't submit spam or duplicate PRs

## 🚀 Getting Started

### Prerequisites
- Flutter 3.32.8 or higher
- Dart 3.8.0 or higher
- Android SDK 34 or higher
- Azure Cognitive Services account (for testing)
   git clone https://github.com/YourUsername/HordVoice.git
   cd HordVoice
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your Azure credentials for testing
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📋 Contribution Types

### 🐛 Bug Fixes
- Fix voice recognition issues
- Resolve Azure AI integration problems
- Address UI/UX inconsistencies
- Fix performance bottlenecks

### ✨ New Features
- Voice command enhancements
- New Azure AI service integrations
- UI/UX improvements
- Accessibility features
- Internationalization

### 📚 Documentation
- Code documentation
- README improvements
- API documentation
- User guides
- Developer tutorials

### 🧪 Testing
- Unit tests
- Integration tests
- Voice recognition testing
- Azure AI service testing
- UI testing

## 🛠️ Development Process

### 1. Choose an Issue
- Look for `good first issue` or `hacktoberfest` labels
- Comment on the issue to claim it

### 2. Create a Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### 3. Make Changes
- Follow the existing code style
- Write meaningful commit messages
- Test your changes thoroughly
- Update documentation if needed

### 4. Commit Guidelines
```bash
# Good commit messages:
git commit -m "feat: add wake word customization feature"
git commit -m "fix: resolve Azure Speech timeout issue"
git commit -m "docs: update installation guide"

# Use conventional commit format:
# feat: new feature
# fix: bug fix
# docs: documentation
# style: formatting
# refactor: code refactoring
# test: adding tests
# chore: maintenance
```

### 5. Submit Pull Request
- Push your changes to your fork
- Create a pull request using our template
- Link related issues
- Wait for review and address feedback

## 🎯 Areas to Contribute

### 🔊 Voice & AI
- Azure Speech Recognition improvements
- Wake word detection enhancements
- Natural language processing
- Voice command parsing
- Azure OpenAI integration

### 📱 Mobile Development
- Flutter UI improvements
- Android native integration
- Performance optimizations
- Accessibility features
- Material Design 3 implementation

### 🔐 Security & Privacy
- API key management
- Data encryption
- Privacy controls
- Security audits
- Secure storage

### 🌐 Internationalization
- French language improvements
- New language support
- Localization
- Cultural adaptations
- Voice model training

### 📖 Documentation
- Code comments
- API documentation
- User guides
- Developer tutorials
- Architecture documentation

## 🎨 Code Style

### Dart/Flutter
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` before committing
- Run `flutter analyze` to check for issues
- Maximum line length: 80 characters
- Use meaningful variable names

### File Organization
```
lib/
├── core/           # Core functionality
├── features/       # Feature modules
├── shared/         # Shared components
└── services/       # Business logic
```

### Azure Integration
- Use environment variables for API keys
- Implement proper error handling
- Add timeout configurations
- Follow Azure SDK best practices

## 🧪 Testing

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Code coverage
flutter test --coverage
```

### Test Requirements
- Write tests for new features
- Maintain >80% code coverage
- Test Azure AI integrations
- Test voice recognition functionality
- Test error scenarios

## 📦 Building

### Debug Build
```bash
flutter build apk --debug
```

### Release Build
```bash
flutter build apk --release
```

### CI/CD
All PRs are automatically tested with:
- Flutter analyze
- Unit tests
- Build verification
- Security scans

## 🤝 Community

### Communication
- [GitHub Discussions](https://github.com/HordRicJr/HordVoice/discussions)
- [Issues](https://github.com/HordRicJr/HordVoice/issues)
- Email: assounrodrigue5@gmail.com

### Code of Conduct
We follow the [Contributor Covenant](https://www.contributor-covenant.org/) code of conduct. Be respectful, inclusive, and collaborative.

## 🏆 Recognition

Contributors will be:
- Added to our README contributors section
- Recognized in release notes
- Eligible for Hacktoberfest rewards
- Invited to join our development team

## 🆘 Getting Help

- **New to Flutter?** Check the [Flutter documentation](https://docs.flutter.dev/)
- **New to Azure AI?** Review [Azure Cognitive Services docs](https://docs.microsoft.com/azure/cognitive-services/)
- **Stuck on an issue?** Comment on the issue or start a discussion
- **Need immediate help?** Reach out via email

## 📄 License

By contributing to HordVoice, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to HordVoice! Together, we're building the future of intelligent voice assistants.** 🚀

*Happy Hacktoberfest 2025!* 🎃