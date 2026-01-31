# Build Instructions

This document explains how to build standalone binaries for Armenian Global Game Jam using the provided build script.

## Quick Start

### Option 1: Use the Launcher Directly (Recommended for Development)
```bash
# Install dependencies
uv venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
uv pip install -e .

# Run the launcher
python launcher.py
```

### Option 2: Build Standalone Binaries
```bash
# Build for current platform only
./build.sh

# Build for all platforms (requires different OS for each)
./build.sh all

# Build for specific platforms
./build.sh macos linux

# Clean build directories
./build.sh --clean
```

## Build Script Features

The `build.sh` script provides:
- **Cross-platform building** for macOS, Linux, and Windows
- **Unified launcher** that includes both pypedream-gui and pytrek_cli
- **Automatic dependency management** using uv
- **Platform-specific packaging**:
  - macOS: `.dmg` file with app bundle
  - Linux: binary executable + optional tar.gz
  - Windows: `.exe` file
- **CI/CD integration** with GitHub Actions

## GitHub Actions

The `.github/workflows/build.yml` workflow automatically:
- Builds binaries on all platforms when you push to main/master
- Creates releases when you push tags starting with `v`
- Uploads build artifacts

## Output Files

After building, you'll find these files in the `dist/` directory:

### macOS
- `armenian_global_game_jam.dmg` - macOS installer

### Linux  
- `armenian_global_game_jam` - Linux binary executable
- `armenian_global_game_jam-linux-0.1.0.tar.gz` - Compressed archive

### Windows
- `armenian_global_game_jam.exe` - Windows executable

## Build Requirements

### All Platforms
- Python 3.11+
- uv (for dependency management)
- PyInstaller (auto-installed by script)

### macOS
- Xcode Command Line Tools
- `create-dmg` (optional, for better DMG creation)
- `brew install create-dmg`

### Linux
- `build-essential` package
- `sudo apt-get install build-essential`

### Windows
- Microsoft Visual C++ Build Tools (usually included with Git for Windows)

## Manual Build Process

If you want to understand the build process, here's what the script does:

1. **Setup**: Creates clean virtual environment and installs dependencies
2. **Launcher Creation**: Builds unified launcher with embedded applications
3. **Application Building**: Uses PyInstaller to create standalone binaries:
   - `pypedream-gui` (GUI application with AI visualization)
   - `pytrek_cli` (Terminal-only game)
4. **Unification**: Packages both binaries into single launcher
5. **Platform Packaging**: Creates platform-specific installers

## Technical Details

### PyInstaller Configuration
- **One-file mode**: Creates single executable per platform
- **Console**: Shows terminal for API key input and game output
- **Windowed GUI**: pypedream-gui runs as windowed application
- **Data files**: Embeds both applications in unified launcher

### Launcher Features
- **API Key Management**: Prompts for GEMINI_API_KEY if not set
- **Menu System**: Lets users choose between GUI or CLI mode
- **Extraction**: Extracts embedded binaries to temp directory
- **Error Handling**: Provides clear error messages

## Troubleshooting

### Build Issues
```bash
# Clean everything and restart
./build.sh --clean
./build.sh

# Check virtual environment
ls -la .venv/
source .venv/bin/activate
which python
```

### Runtime Issues
- **Missing API Key**: The launcher will prompt for one
- **Permission Denied**: Ensure executable has proper permissions
- **Missing Dependencies**: Reinstall with `uv pip install -e .`

### Platform-Specific Issues

#### macOS
```bash
# If DMG creation fails, try manual approach
hdiutil create -volname "Armenian Global Game Jam" \
             -srcfolder dist/armenian_global_game_jam.app \
             -ov -format UDZO dist/armenian_global_game_jam.dmg
```

#### Linux
```bash
# If executable doesn't run, check dependencies
ldd dist/armenian_global_game_jam

# Install missing system packages
sudo apt-get install missing-package-name
```

#### Windows
```bash
# If EXE crashes on startup, check Windows Defender
# or run as administrator
```

## Distribution

### Automated Distribution
- Push to `main` or `master` branch → automatic build
- Create tag like `v1.0.0` → automatic release with binaries

### Manual Distribution
1. Build binaries: `./build.sh all` (on respective platforms)
2. Upload files from `dist/` directory
3. Include these instructions in your release notes

## Development vs Production

### Development
- Use `python launcher.py` directly
- Faster iteration
- Live editing of code
- Automatic dependency detection

### Production
- Use built binaries from `dist/`
- Self-contained, no dependencies
- Single file distribution
- Professional installer experience

## Security Notes

- API keys are only stored in environment variables
- No credentials are embedded in binaries
- Temporary files are cleaned up automatically
- Only prompts for API key when not set

## Performance

- **Startup Time**: 2-5 seconds (one-file extraction)
- **Memory Usage**: ~100MB (includes embedded Python)
- **Disk Space**: ~50MB per platform (includes bundled apps)

For the best user experience, distribute the platform-specific installers rather than the raw binaries.