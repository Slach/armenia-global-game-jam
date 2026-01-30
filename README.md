# Armenia Global Game Jam - PyTrek + PipeDream

Combination of **PipeDream** (real-time AI visualization for interactive fiction) and **PyTrek** (classic Star Trek game).

## Setup

### 1. Install Dependencies via UV

```bash
# Install uv if you don't have it
pip install uv

# Create virtual environment
uv venv

# Install PipeDream and PyTrek from their GitHub repos
uv pip install -e .
```

### 2. Configure Environment Variables

Copy the example `.env` file and add your API key:

```bash
cp .env.example .env
```

Edit `.env` and add your Gemini API key:
```
GEMINI_API_KEY=AIzaSy...  # Get from https://aistudio.google.com/app/apikey
```

## Running the Game

### Option 1: Run with PipeDream Visualization

```bash
./run.sh
```

This will:
- Load environment variables from `.env`
- Launch PipeDream GUI with retro 8-bit pixel art style
- Start PyTrek 9000 game
- Generate real-time images based on game events

### Option 2: Run PyTrek Directly (No Visualization)

```bash
./pytrek-9000.sh
```

### Option 3: Run PyTrek via Python

```bash
python pytrek_cli.py
```

## Architecture

- **run.sh**: Main launcher that loads `.env` and runs PipeDream with PyTrek
- **pytrek-9000.sh**: Shell wrapper for PyTrek CLI
- **pytrek_cli.py**: Python script that imports `from PyTrek import PyTrek1`
- **pyproject.toml**: Defines dependencies on PipeDream and PyTrek from GitHub

## Dependencies

- **PipeDream**: Visualizes terminal output with generative AI (Gemini)
  - Repo: https://github.com/CPritch/PipeDream
  - Requires: GEMINI_API_KEY

- **PyTrek**: Classic Star Trek game in Python
  - Repo: https://github.com/Python3-Training/PyTrek
  - Runs as TUI game

## Cost Tracking

PipeDream displays real-time API costs in the GUI. Image generation uses the Gemini Flash model which has competitive pricing.
