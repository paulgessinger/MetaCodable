# Swift Version Testing with Swiftly

This guide explains how to use `swiftly` to test your MetaCodable project across different Swift versions and handle version-specific deprecation warnings.

## Current Status

Your project already handles Swift version compatibility well:

### ✅ Code Already Updated
The deprecation warning you mentioned:
```swift
warning: 'appending' is deprecated: Use `URL` type instead of `Path`.
```

Has already been fixed in your codebase. The current code uses the modern URL-based API:

```swift
// Modern approach (already implemented)
let genFolder = context.pluginWorkDirectoryURL.appending(path: "ProtocolGen")
try FileManager.default.createDirectory(
    at: genFolder, withIntermediateDirectories: true
)
```

Instead of the deprecated Path-based API:
```swift
// Deprecated approach (no longer used)
let genFolder = context.pluginWorkDirectory.appending(["ProtocolGen"])
```

### ✅ CI Already Testing Multiple Versions
Your GitHub Actions workflow already tests with:
- Swift 5.9, 5.10, 6.0, 6.1, and latest
- Multiple swift-syntax versions (509.1.1, 510.0.3, 600.0.1, 601.0.1)

## Installing and Using Swiftly

### Installation
Install swiftly from the official Swift website:
```bash
# Visit swift.org/install and follow the installation instructions
# Or use curl (the exact command will be provided on the site)
curl -fsSL https://swift.org/install/swiftly/swiftly-install.sh | bash
```

### Basic Swiftly Commands

```bash
# List available Swift versions
swiftly list-available

# List installed versions
swiftly list

# Install specific Swift versions
swiftly install 5.9
swiftly install 5.10
swiftly install 6.0
swiftly install 6.1
swiftly install latest

# Install nightly snapshots
swiftly install main-snapshot

# Switch between versions
swiftly use 6.0
swiftly use 5.9

# Check current version
swift --version

# Run a command with a specific version temporarily
swiftly run swift test +6.1
swiftly run swift build +5.9

# Update swiftly itself
swiftly self-update
```

## Project-Specific Testing Strategy

### 1. Set Up Project Version File
Create a `.swift-version` file in your project root to standardize the version across your team:

```bash
echo "6.1" > .swift-version
```

### 2. Test Across Multiple Versions
Create a testing script to validate your project across different Swift versions:

```bash
#!/bin/bash
# test-swift-versions.sh

VERSIONS=("5.9" "5.10" "6.0" "6.1" "latest")

for version in "${VERSIONS[@]}"; do
    echo "Testing with Swift $version..."
    
    # Switch to version
    swiftly use $version
    
    # Clean build
    swift package clean
    
    # Test build
    if swift build; then
        echo "✅ Swift $version: Build successful"
    else
        echo "❌ Swift $version: Build failed"
    fi
    
    # Test package
    if swift test; then
        echo "✅ Swift $version: Tests passed"
    else
        echo "❌ Swift $version: Tests failed"
    fi
    
    echo "------------------------"
done
```

### 3. Handle Version-Specific Code
Your codebase already uses conditional compilation for Swift version differences:

```swift
#if swift(<6)
let toolUrl = URL(string: tool.path.string)!
#else
let toolUrl = tool.url
#endif
```

### 4. Address Deprecation Warnings Systematically

For any remaining deprecation warnings, use this pattern:

```swift
#if swift(<6.0)
// Use older API for Swift < 6.0
let path = context.pluginWorkDirectory.appending(["folder"])
#else
// Use newer API for Swift >= 6.0  
let path = context.pluginWorkDirectoryURL.appending(path: "folder")
#endif
```

## Local Development Workflow

### Setting Up Multiple Versions
```bash
# Install the versions you need to test
swiftly install 5.9
swiftly install 6.0
swiftly install 6.1

# Set your default for development
swiftly use 6.1
```

### Testing Workflow
```bash
# Test with your current default version
swift test

# Test with older version without switching default
swiftly run swift test +5.9

# Test building examples with different versions
swiftly run swift build +6.0
```

### Debugging Version Issues
```bash
# Check which version is active
swiftly list
swift --version

# Check for deprecation warnings
swift build 2>&1 | grep -i deprecated

# Test specific files with different versions
swiftly run swift -frontend -typecheck Sources/MetaCodable/File.swift +5.9
```

## Continuous Integration Integration

### Update Your CI to Use Swiftly
Consider updating your GitHub Actions to use swiftly for more flexible version management:

```yaml
- name: Install swiftly
  run: |
    curl -fsSL https://swift.org/install/swiftly/swiftly-install.sh | bash
    echo "$HOME/.local/bin" >> $GITHUB_PATH

- name: Install Swift ${{ matrix.swift-version }}
  run: swiftly install ${{ matrix.swift-version }}

- name: Use Swift ${{ matrix.swift-version }}
  run: swiftly use ${{ matrix.swift-version }}
```

## Best Practices

### 1. Version Compatibility Strategy
- **Minimum Version**: Define the minimum Swift version you support
- **Testing Matrix**: Test against minimum, current stable, and latest versions
- **Deprecation Timeline**: Plan migration away from deprecated APIs

### 2. Code Organization
- Use `#if swift()` conditionals sparingly and document them well
- Prefer feature checks over version checks when possible
- Create wrapper functions for version-specific APIs

### 3. Documentation
- Document Swift version requirements in README
- Keep CHANGELOG.md updated with version compatibility changes
- Use clear commit messages for version-specific fixes

## Troubleshooting Common Issues

### Xcode vs Swiftly Conflicts
If you're on macOS and have both Xcode and swiftly:
```bash
# Check which Swift you're using
which swift
swift --version

# Force use of swiftly version
swiftly use 6.1
```

### Path Issues
Ensure swiftly is in your PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Package.swift Version Compatibility
Your `Package@swift-5.swift` file shows you're already handling this correctly for older Swift versions.

## Next Steps

1. **Install swiftly** following the official instructions
2. **Test your current codebase** with the script above
3. **Review deprecation warnings** systematically across versions
4. **Update CI/CD** to leverage swiftly if desired
5. **Document version requirements** for contributors

Your project is already well-structured for multi-version Swift support. Swiftly will make it easier to test locally and catch version-specific issues early in development.