#!/bin/bash

# Swift Version Testing Script
# This script tests the MetaCodable project across multiple Swift versions using swiftly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default Swift versions to test
DEFAULT_VERSIONS=("5.9" "5.10" "6.0" "6.1" "latest")

# Check if swiftly is installed
if ! command -v swiftly &> /dev/null; then
    echo -e "${RED}Error: swiftly is not installed.${NC}"
    echo -e "${BLUE}Please install swiftly from: https://swift.org/install${NC}"
    exit 1
fi

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

# Function to print test results
print_result() {
    local status=$1
    local message=$2
    
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✅ $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

# Parse command line arguments
VERSIONS=("${DEFAULT_VERSIONS[@]}")
SKIP_INSTALL=false
BUILD_ONLY=false
TEST_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --versions)
            IFS=',' read -ra VERSIONS <<< "$2"
            shift 2
            ;;
        --skip-install)
            SKIP_INSTALL=true
            shift
            ;;
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --versions VERSIONS    Comma-separated list of Swift versions to test"
            echo "                        Default: ${DEFAULT_VERSIONS[*]}"
            echo "  --skip-install        Skip installing Swift versions (assume already installed)"
            echo "  --build-only          Only test building, skip running tests"
            echo "  --test-only           Only run tests, skip building"
            echo "  --help, -h            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Test all default versions"
            echo "  $0 --versions 6.0,6.1               # Test only Swift 6.0 and 6.1"
            echo "  $0 --build-only                     # Only test building"
            echo "  $0 --skip-install --versions 6.1    # Test Swift 6.1 without installing"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_section "Swift Version Testing for MetaCodable"

echo -e "${BLUE}Testing Swift versions: ${VERSIONS[*]}${NC}"
echo -e "${BLUE}Skip install: $SKIP_INSTALL${NC}"
echo -e "${BLUE}Build only: $BUILD_ONLY${NC}"
echo -e "${BLUE}Test only: $TEST_ONLY${NC}\n"

# Store original Swift version to restore later
ORIGINAL_VERSION=$(swiftly list | grep '*' | awk '{print $2}' || echo "none")

# Track overall results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_VERSIONS=()

# Install required Swift versions
if [ "$SKIP_INSTALL" = false ]; then
    print_section "Installing Swift Versions"
    
    for version in "${VERSIONS[@]}"; do
        echo -e "${YELLOW}Installing Swift $version...${NC}"
        if swiftly install "$version" 2>/dev/null; then
            echo -e "${GREEN}✅ Swift $version installed successfully${NC}"
        else
            echo -e "${YELLOW}⚠️  Swift $version already installed or installation skipped${NC}"
        fi
    done
fi

# Test each version
for version in "${VERSIONS[@]}"; do
    print_section "Testing Swift $version"
    
    echo -e "${YELLOW}Switching to Swift $version...${NC}"
    if ! swiftly use "$version"; then
        echo -e "${RED}❌ Failed to switch to Swift $version${NC}"
        FAILED_VERSIONS+=("$version (switch failed)")
        continue
    fi
    
    # Verify version switch
    CURRENT_VERSION=$(swift --version | head -n1)
    echo -e "${BLUE}Current Swift version: $CURRENT_VERSION${NC}\n"
    
    # Clean build directory
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    swift package clean
    
    if [ "$TEST_ONLY" = false ]; then
        # Test building
        echo -e "${YELLOW}Testing build...${NC}"
        if swift build; then
            print_result 0 "Swift $version: Build successful"
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            print_result 1 "Swift $version: Build failed"
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
            FAILED_VERSIONS+=("$version (build failed)")
            continue
        fi
    fi
    
    if [ "$BUILD_ONLY" = false ]; then
        # Test running tests
        echo -e "${YELLOW}Running tests...${NC}"
        if swift test; then
            print_result 0 "Swift $version: Tests passed"
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            print_result 1 "Swift $version: Tests failed"
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
            FAILED_VERSIONS+=("$version (tests failed)")
        fi
    fi
    
    echo -e "\n${BLUE}------------------------${NC}"
done

# Restore original Swift version
if [ "$ORIGINAL_VERSION" != "none" ] && [ "$ORIGINAL_VERSION" != "" ]; then
    print_section "Restoring Original Swift Version"
    echo -e "${YELLOW}Restoring Swift $ORIGINAL_VERSION...${NC}"
    if swiftly use "$ORIGINAL_VERSION"; then
        echo -e "${GREEN}✅ Restored to Swift $ORIGINAL_VERSION${NC}"
    else
        echo -e "${RED}❌ Failed to restore Swift $ORIGINAL_VERSION${NC}"
    fi
fi

# Print summary
print_section "Test Summary"

echo -e "${BLUE}Total tests: $TOTAL_TESTS${NC}"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $((TOTAL_TESTS - PASSED_TESTS))${NC}"

if [ ${#FAILED_VERSIONS[@]} -gt 0 ]; then
    echo -e "\n${RED}Failed versions:${NC}"
    for failed in "${FAILED_VERSIONS[@]}"; do
        echo -e "${RED}  - $failed${NC}"
    done
fi

echo -e "\n${BLUE}Testing complete!${NC}"

# Exit with appropriate code
if [ $PASSED_TESTS -eq $TOTAL_TESTS ] && [ $TOTAL_TESTS -gt 0 ]; then
    echo -e "${GREEN}All tests passed! 🎉${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed! 💥${NC}"
    exit 1
fi