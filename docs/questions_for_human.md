# Questions for the human maintainer

Answer only what you can; defaults will be used otherwise.

1) Which LIST layers should be treated as the “canonical” built-in examples for Tasmania site panels?
   - Proposed defaults: Orthophoto basemap, TASVEG, roads/localities overlay.

2) Do you want the default plotting stack to remain ggplot2-based, or should we adopt tmap as the primary renderer for panel figures?
   - Default decision (unless you say otherwise): ggplot2 + patchwork.

3) Should the existing Atlas of Living Australia species-occurrence workflow remain in this repo as an optional module, or should we de-emphasize it to focus purely on local site mapping?
   - Default decision: keep it, but treat it as secondary.

4) What is the intended repository URL for CITATION metadata?
   - If unknown now, we will leave a TODO and update before 1.0.

5) Do you have a preferred “publication style” baseline?
   - e.g., font family, typical figure width, whether journals require vector outputs (PDF/SVG).
