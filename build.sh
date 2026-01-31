#!/bin/bash
# Cross-platform build script for Armenian Global Game Jam
# Creates standalone binaries for macOS, Linux, and Windows

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build configuration
PROJECT_NAME="armenian_global_game_jam"
VERSION="0.1.0"
BUILD_DIR="build"
DIST_DIR="dist"
TEMP_DIR="temp_build"

# Platform-specific output names
MACOS_BINARY="${PROJECT_NAME}"
LINUX_BINARY="${PROJECT_NAME}"
WINDOWS_BINARY="${PROJECT_NAME}.exe"
MACOS_DMG="${PROJECT_NAME}.dmg"

echo -e "${BLUE}🚀 Building ${PROJECT_NAME} v${VERSION} for all platforms${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to detect current platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*)    echo "macos" ;;
        Linux*)     echo "linux" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

# Function to check if running on correct platform for build
check_platform() {
    local target_platform=$1
    local current_platform=$(detect_platform)
    
    if [[ "$current_platform" != "$target_platform" && "$current_platform" != "unknown" ]]; then
        print_warning "Cannot build $target_platform binaries on $current_platform"
        print_warning "Use GitHub Actions or run on appropriate platform"
        return 1
    fi
    return 0
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Install uv if not present
    if ! command -v uv &> /dev/null; then
        print_status "Installing uv..."
        pip install uv
    fi
    
    # Create fresh virtual environment
    if [[ -d ".venv" ]]; then
        print_status "Removing existing virtual environment..."
        rm -rf .venv
    fi
    
    print_status "Creating virtual environment..."
    uv venv
    source .venv/bin/activate 2>/dev/null || source .venv/Scripts/activate
    
    # Install dependencies
    print_status "Installing project dependencies..."
    uv pip install -e .
    
    # Install PyInstaller
    uv pip install pyinstaller
    
    # Install additional dependencies for building
    case "$(detect_platform)" in
        macos)
            # Install create-dmg for macOS
            if ! command -v create-dmg &> /dev/null; then
                print_status "Installing create-dmg..."
                brew install create-dmg || print_warning "create-dmg not installed, will use hdiutil"
            fi
            ;;
        windows)
            # Install Windows build tools
            uv pip install pywin32
            ;;
    esac
}

# Function to create unified launcher script
create_launcher() {
    local platform=$1
    print_status "Creating unified launcher for $platform..."
    
    mkdir -p "${TEMP_DIR}/launcher"
    
    cat > "${TEMP_DIR}/launcher/launcher.py" << 'EOF'
#!/usr/bin/env python3
"""
Armenian Global Game Jam Unified Launcher
Launches either pypedream-gui or pytrek_cli based on user selection.
"""

import os
import sys
import subprocess
import tempfile
import shutil
from pathlib import Path

def check_api_key():
    """Check if GEMINI_API_KEY is set, prompt if not."""
    api_key = os.environ.get('GEMINI_API_KEY')
    if not api_key:
        print("=== Armenian Global Game Jam Launcher ===")
        print("This game requires a Gemini API key to generate AI images.")
        print("Get your free API key from: https://aistudio.google.com/app/apikey")
        print()
        
        while True:
            api_key = input("Enter your Gemini API key (or press Ctrl+C to exit): ").strip()
            if api_key and api_key.startswith('AIza'):
                os.environ['GEMINI_API_KEY'] = api_key
                print("✓ API key accepted!")
                print()
                break
            else:
                print("Invalid API key format. API keys should start with 'AIza'")
                print("Please get a valid key from: https://aistudio.google.com/app/apikey")
                print()
    
    return api_key

def extract_binary(binary_name):
    """Extract bundled binary to temporary directory."""
    # Get the directory where the launcher is located
    launcher_dir = Path(__file__).parent
    
    # Find the bundled binary (PyInstaller puts it in a different location when frozen)
    if hasattr(sys, '_MEIPASS'):
        # Running in PyInstaller bundle
        bundled_dir = Path(sys._MEIPASS)
        binary_path = bundled_dir / binary_name
    else:
        # Running in development
        binary_path = launcher_dir / binary_name
    
    if not binary_path.exists():
        print(f"Error: Could not find {binary_name}")
        sys.exit(1)
    
    # Extract to temporary directory
    temp_dir = tempfile.mkdtemp(prefix="armenian_game_jam_")
    extracted_path = Path(temp_dir) / binary_name
    
    try:
        shutil.copy2(binary_path, extracted_path)
        os.chmod(extracted_path, 0o755)  # Make executable
        return str(extracted_path)
    except Exception as e:
        print(f"Error extracting {binary_name}: {e}")
        sys.exit(1)

def run_with_gui():
    """Run pypedream-gui with AI visualization."""
    print("🎨 Launching with AI visualization (PipeDream GUI)...")
    
    # Extract and run pypedream-gui
    gui_binary = extract_binary("pypedream-gui" + (".exe" if os.name == 'nt' else ""))
    
    try:
        # Run the GUI application
        subprocess.run([gui_binary], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running GUI: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print("Error: GUI application not found")
        sys.exit(1)

def run_cli():
    """Run pytrek_cli (terminal game only)."""
    print("🚀 Launching terminal-only version (PyTrek)...")
    
    # Extract and run pytrek_cli
    cli_binary = extract_binary("pytrek_cli" + (".exe" if os.name == 'nt' else ""))
    
    try:
        # Run the CLI application in current terminal
        subprocess.run([cli_binary], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running CLI: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print("Error: CLI application not found")
        sys.exit(1)

def show_menu():
    """Display game selection menu."""
    print("🎮 Select Game Mode:")
    print("1. Play with AI Visualization (Recommended)")
    print("2. Play Terminal-Only Version")
    print("3. Exit")
    print()

def main():
    """Main launcher logic."""
    # Check API key first
    check_api_key()
    
    while True:
        show_menu()
        choice = input("Enter your choice (1-3): ").strip()
        
        if choice == "1":
            run_with_gui()
            break
        elif choice == "2":
            run_cli()
            break
        elif choice == "3":
            print("Goodbye! 🖖")
            sys.exit(0)
        else:
            print("Invalid choice. Please enter 1, 2, or 3.")
            print()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nGoodbye! 🖖")
        sys.exit(0)
EOF

    # Create platform-specific launcher scripts
    case $platform in
        macos|linux)
            cat > "${TEMP_DIR}/launcher/launcher.sh" << EOF
#!/bin/bash
# Launcher script for $platform

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export GEMINI_API_KEY="\${GEMINI_API_KEY:-}"
"\${SCRIPT_DIR}/launcher.py" "\$@"
EOF
            chmod +x "${TEMP_DIR}/launcher/launcher.sh"
            ;;
        windows)
            cat > "${TEMP_DIR}/launcher/launcher.bat" << EOF
@echo off
setlocal
REM Launcher script for Windows

set SCRIPT_DIR=%~dp0
set GEMINI_API_KEY=%GEMINI_API_KEY%
"%SCRIPT_DIR%launcher.py" %*
EOF
            ;;
    esac
}

# Function to build individual applications
build_apps() {
    local platform=$1
    print_status "Building applications for $platform..."
    
    # Ensure we're in the activated virtual environment
    source .venv/bin/activate 2>/dev/null || source .venv/Scripts/activate 2>/dev/null || true
    
    # Build pytrek_cli
    print_status "Building pytrek_cli..."
    pyinstaller \
        --name="pytrek_cli" \
        --onefile \
        --console \
        --distpath="${TEMP_DIR}/apps" \
        --workpath="${TEMP_DIR}/build" \
        --specpath="${TEMP_DIR}/specs" \
        pytrek_cli.py
    
    print_status "Building pypedream-gui..."

    # Find pipedream module entry point
    PYPEDREAM_MAIN=$(find .venv/Lib/site-packages -path "*/pipedream/__main__.py" -type f | head -1)
    if [[ -z "$PYPEDREAM_MAIN" ]]; then
        PYPEDREAM_MAIN=$(find .venv/lib/python*/site-packages -path "*/pipedream/__main__.py" -type f | head -1)
    fi

    if [[ -z "$PYPEDREAM_MAIN" ]]; then
        print_error "Could not find pipedream/__main__.py"
        return 1
    fi

    print_status "Found pipedream at: $PYPEDREAM_MAIN"

    # Build GUI application using Python module entry point
    pyinstaller \
        --name="pypedream-gui" \
        --onefile \
        --windowed \
        --distpath="${TEMP_DIR}/apps" \
        --workpath="${TEMP_DIR}/build" \
        --specpath="${TEMP_DIR}/specs" \
        --hidden-import=pipedream \
        "$PYPEDREAM_MAIN"
}

# Function to create unified binary
build_unified_binary() {
    local platform=$1
    print_status "Creating unified binary for $platform..."
    
    # Create unified launcher spec
    cat > "${TEMP_DIR}/unified.spec" << EOF
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['launcher/launcher.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('apps/pypedream-gui${WINDOWS_EXT:+.exe}', '.'),
        ('apps/pytrek_cli${WINDOWS_EXT:+.exe}', '.'),
    ],
    hiddenimports=['tkinter', 'subprocess', 'tempfile', 'shutil', 'pathlib'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='${PROJECT_NAME}${WINDOWS_EXT:+.exe}',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,  # Keep console to show API key prompt
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None
)
EOF

    # Set Windows extension flag
    WINDOWS_EXT=""
    if [[ "$platform" == "windows" ]]; then
        WINDOWS_EXT=1
    fi

    DIST_ABS_PATH="$(pwd)/${DIST_DIR}"

    # Build unified binary
    cd "${TEMP_DIR}"
    pyinstaller unified.spec --distpath="${DIST_ABS_PATH}"
    cd - > /dev/null
}

# Function to create macOS DMG
create_macos_dmg() {
    if ! check_platform "macos"; then
        return 1
    fi
    
    print_status "Creating macOS DMG..."
    
    # Create app bundle structure
    APP_DIR="${DIST_DIR}/${PROJECT_NAME}.app"
    mkdir -p "${APP_DIR}/Contents/MacOS"
    mkdir -p "${APP_DIR}/Contents/Resources"
    
    # Create Info.plist
    cat > "${APP_DIR}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${PROJECT_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.armenia.gamejam</string>
    <key>CFBundleName</key>
    <string>Armenian Global Game Jam</string>
    <key>CFBundleDisplayName</key>
    <string>Armenian Global Game Jam</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
    
    # Move binary to app bundle
    if [[ -f "${DIST_DIR}/${PROJECT_NAME}" ]]; then
        mv "${DIST_DIR}/${PROJECT_NAME}" "${APP_DIR}/Contents/MacOS/"
    else
        print_error "Binary not found for DMG creation"
        return 1
    fi
    
    # Create DMG
    if command -v create-dmg &> /dev/null; then
        create-dmg \
            --volname "Armenian Global Game Jam" \
            --window-pos 200 120 \
            --window-size 800 600 \
            --icon-size 100 \
            --icon "${PROJECT_NAME}.app" 200 190 \
            --hide-extension "${PROJECT_NAME}.app" \
            --app-drop-link 600 185 \
            "${DIST_DIR}/${MACOS_DMG}" \
            "${DIST_DIR}/"
    else
        # Fallback to hdiutil
        hdiutil create -volname "Armenian Global Game Jam" \
                     -srcfolder "${DIST_DIR}/${PROJECT_NAME}.app" \
                     -ov -format UDZO "${DIST_DIR}/${MACOS_DMG}"
    fi
    
    print_status "Created ${MACOS_DMG}"
}

# Function to build for specific platform
build_for_platform() {
    local platform=$1
    
    # Check if we can build for this platform
    if ! check_platform "$platform"; then
        print_warning "Skipping $platform build (not on correct platform)"
        return 0
    fi
    
    print_status "Building for $platform..."
    
    # Clean build directories
    rm -rf "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"
    
    # Install dependencies
    install_dependencies
    
    # Create launcher
    create_launcher "$platform"
    
    # Build applications
    build_apps "$platform"
    
    # Create unified binary
    build_unified_binary "$platform"
    
    # Create platform-specific package
    case $platform in
        macos)
            create_macos_dmg
            ;;
        linux)
            print_status "Linux binary created: ${DIST_DIR}/${LINUX_BINARY}"
            # Optionally create AppImage or tar.gz
            tar -czf "${DIST_DIR}/${PROJECT_NAME}-linux-${VERSION}.tar.gz" -C "${DIST_DIR}" "${LINUX_BINARY}"
            ;;
        windows)
            print_status "Windows binary created: ${DIST_DIR}/${WINDOWS_BINARY}"
            # Optionally create installer
            ;;
    esac
    
    # Clean up temp files
    rm -rf "${TEMP_DIR}"
    
    print_status "✅ $platform build completed successfully!"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [PLATFORMS...]"
    echo ""
    echo "Platforms:"
    echo "  macos    Build for macOS"
    echo "  linux    Build for Linux"
    echo "  windows  Build for Windows"
    echo "  all      Build for all platforms (default)"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --clean    Clean build directories"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build for current platform only"
    echo "  $0 all               # Build for all platforms"
    echo "  $0 macos linux       # Build for macOS and Linux"
}

# Function to clean build directories
clean_build() {
    print_status "Cleaning build directories..."
    rm -rf "${BUILD_DIR}" "${DIST_DIR}" "${TEMP_DIR}"
    print_status "Clean completed!"
}

# Main script logic
main() {
    # Parse command line arguments
    platforms=()
    clean_only=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--clean)
                clean_only=true
                shift
                ;;
            macos|linux|windows|all)
                platforms+=("$1")
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Default: build for current platform if no platforms specified
    if [[ ${#platforms[@]} -eq 0 ]]; then
        platforms+=("$(detect_platform)")
    fi
    
    # Handle clean only
    if [[ "$clean_only" == "true" ]]; then
        clean_build
        exit 0
    fi
    
    # Clean old builds
    clean_build
    
    # Create build directories
    mkdir -p "${BUILD_DIR}" "${DIST_DIR}"
    
    # Build for each platform
    for platform in "${platforms[@]}"; do
        if [[ "$platform" == "all" ]]; then
            for p in macos linux windows; do
                build_for_platform "$p"
            done
        else
            build_for_platform "$platform"
        fi
    done
    
    # Show results
    print_status "🎉 Build completed successfully!"
    echo ""
    echo "Output files:"
    
    if [[ -f "${DIST_DIR}/${MACOS_DMG}" ]]; then
        echo "  macOS:   ${DIST_DIR}/${MACOS_DMG}"
    fi
    
    if [[ -f "${DIST_DIR}/${LINUX_BINARY}" ]]; then
        echo "  Linux:   ${DIST_DIR}/${LINUX_BINARY}"
        if [[ -f "${DIST_DIR}/${PROJECT_NAME}-linux-${VERSION}.tar.gz" ]]; then
            echo "           ${DIST_DIR}/${PROJECT_NAME}-linux-${VERSION}.tar.gz"
        fi
    fi
    
    if [[ -f "${DIST_DIR}/${WINDOWS_BINARY}" ]]; then
        echo "  Windows: ${DIST_DIR}/${WINDOWS_BINARY}"
    fi
    
    echo ""
    print_status "Ready to distribute! 🚀"
}

# Run main function
main "$@"