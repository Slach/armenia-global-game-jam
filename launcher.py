#!/usr/bin/env python3
"""
Standalone Armenian Global Game Jam Launcher
This script can be used directly without building binaries.
"""

import os
import sys
import subprocess
from pathlib import Path


def check_api_key():
    """Check if GEMINI_API_KEY is set, prompt if not."""
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("=== Armenian Global Game Jam Launcher ===")
        print("This game requires a Gemini API key to generate AI images.")
        print("Get your free API key from: https://aistudio.google.com/app/apikey")
        print()

        while True:
            api_key = input(
                "Enter your Gemini API key (or press Ctrl+C to exit): "
            ).strip()
            if api_key and api_key.startswith("AIza"):
                os.environ["GEMINI_API_KEY"] = api_key
                print("✓ API key accepted!")
                print()
                break
            else:
                print("Invalid API key format. API keys should start with 'AIza'")
                print(
                    "Please get a valid key from: https://aistudio.google.com/app/apikey"
                )
                print()

    return api_key


def run_with_gui():
    """Run with pypedream-gui visualization."""
    print("🎨 Launching with AI visualization (PipeDream GUI)...")

    # Get project directory
    project_dir = Path(__file__).parent

    # Find pipedream-gui in virtual environment
    venv_dir = project_dir / ".venv"
    if not venv_dir.exists():
        print(
            "Error: Virtual environment not found. Run 'uv venv && uv pip install -e .' first."
        )
        sys.exit(1)

    # Find pipedream-gui executable
    if sys.platform == "win32":
        pipedream_exe = venv_dir / "Scripts" / "pipedream-gui.exe"
        pytrek_script = project_dir / "pytrek-9000.sh"
        bash_cmd = "bash"
    else:
        pipedream_exe = venv_dir / "bin" / "pipedream-gui"
        pytrek_script = project_dir / "pytrek-9000.sh"
        bash_cmd = "bash"

    if not pipedream_exe.exists():
        print(f"Error: pipedream-gui not found at {pipedream_exe}")
        sys.exit(1)

    # Run pipedream-gui with pytrek command
    cmd = [
        str(pipedream_exe),
        "--art-style",
        "StarTrek sci-fi game, orange monochrome",
        bash_cmd,
        str(pytrek_script),
    ]

    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running GUI: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print("Error: Required command not found")
        sys.exit(1)


def run_cli():
    """Run pytrek_cli directly."""
    print("🚀 Launching terminal-only version (PyTrek)...")

    # Get project directory
    project_dir = Path(__file__).parent

    # Run pytrek_cli.py directly
    pytrek_script = project_dir / "pytrek_cli.py"

    if not pytrek_script.exists():
        print(f"Error: pytrek_cli.py not found at {pytrek_script}")
        sys.exit(1)

    try:
        # Use the current Python interpreter
        subprocess.run([sys.executable, str(pytrek_script)], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running CLI: {e}")
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
