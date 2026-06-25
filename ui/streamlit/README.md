# Streamlit Viewer – Shallow Water Equations

A lightweight Python/Streamlit app that reads the CSV output files
produced by the Fortran solver and renders interactive visualisations.

## Requirements

- Python ≥ 3.10
- Packages listed in `requirements.txt`

## Quick start

```bash
# 1. (optional) create a virtual environment
python -m venv .venv
source .venv/bin/activate

# 2. install dependencies
pip install -r requirements.txt

# 3. run the app  (solver output expected at ../../output by default)
streamlit run app.py
```

## Configuration

Pass the path to the solver output directory in the sidebar text field.
The app automatically discovers all `swe_*.csv` files and provides a
time-step slider.
