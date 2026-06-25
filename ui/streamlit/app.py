"""
Shallow Water Equations – Streamlit visualisation placeholder.

Run with:
    streamlit run app.py

This app reads CSV output files written by the Fortran solver
(one file per time step, format: x,y,h,u,v,hu,hv) and renders
an interactive water-depth heatmap.
"""

import streamlit as st
import pandas as pd
import numpy as np
import glob
import os

st.set_page_config(page_title="Shallow Water Viewer", layout="wide")
st.title("🌊 Shallow Water Equations – Results Viewer")

# ------------------------------------------------------------------
# Sidebar: data source
# ------------------------------------------------------------------
output_dir = st.sidebar.text_input("Output directory", value="../../output")

csv_files = sorted(glob.glob(os.path.join(output_dir, "swe_*.csv")))

if not csv_files:
    st.info(
        f"No output files found in **{output_dir}**.\n\n"
        "Run the Fortran solver first:\n"
        "```\nmake && ./build/shallow_water\n```"
    )
    st.stop()

# ------------------------------------------------------------------
# Step selector
# ------------------------------------------------------------------
step_index = st.sidebar.slider("Time step", 0, len(csv_files) - 1, 0)
selected_file = csv_files[step_index]
step_label = os.path.basename(selected_file).replace(".csv", "")
st.sidebar.write(f"File: `{step_label}`")

# ------------------------------------------------------------------
# Load data
# ------------------------------------------------------------------
@st.cache_data
def load_step(path: str) -> pd.DataFrame:
    return pd.read_csv(path)


df = load_step(selected_file)

# ------------------------------------------------------------------
# Display
# ------------------------------------------------------------------
col1, col2 = st.columns(2)

with col1:
    st.subheader("Water depth  h (m)")
    pivot_h = df.pivot_table(index="y", columns="x", values="h", aggfunc="first")
    st.dataframe(pivot_h.style.background_gradient(cmap="Blues"), use_container_width=True)

with col2:
    st.subheader("x-velocity  u (m/s)")
    pivot_u = df.pivot_table(index="y", columns="x", values="u", aggfunc="first")
    st.dataframe(pivot_u.style.background_gradient(cmap="RdBu_r"), use_container_width=True)

st.caption(f"Loaded: {selected_file}")
