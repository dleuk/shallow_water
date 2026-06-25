# React Viewer – Shallow Water Equations (Placeholder)

A future React-based visualisation front-end for the shallow water solver.

## Planned features

- Real-time WebSocket streaming of solver output
- 2-D colour map of water depth and velocity vectors
- Time-scrubbing slider and playback controls
- Terrain overlay

## Bootstrap (once implementation begins)

```bash
npx create-react-app shallow-water-viewer
cd shallow-water-viewer
npm install
npm start
```

## Notes

The Fortran solver writes CSV files to `output/`.
The React app will consume these files (or a thin REST/WebSocket wrapper
around the solver) to render the visualisation.
