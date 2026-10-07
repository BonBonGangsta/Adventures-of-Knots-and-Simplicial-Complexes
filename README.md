# AdventuresOfKnotsAndSimplicialComplexes

This repository contains simplified, foundational versions of scripts developed during our research. Performance optimizations, caching, logging, and other development-specific features have been intentionally excluded to keep the underlying mathematical implementations accessible, understandable, and reproducible.

## Folders and scripts

### `GAP/`

GAP templates that use the `simpcomp` package to study simplicial complexes loaded from facet data. Replace the `<<<FILE_NAME>>>` and `<<<SC_NAME>>>` placeholders before use; the input file should define `facets`.

- [`collapsibility.g.template`](GAP/collapsibility.g.template): Attempts to collapse a complex to a single vertex using repeated greedy collapses (100 rounds by default), followed by lexicographic and reverse-lexicographic collapses. A successful collapse certifies collapsibility; an unsuccessful search does not prove non-collapsibility.
- [`scmorseengstroem.g.template`](GAP/scmorseengstroem.g.template): Runs `simpcomp`'s `SCMorseEngstroem` discrete Morse routine on the complex and prints its result.

### `Macaulay2/`

Macaulay2 examples using the `SimplicialComplexes` and `SimplicialDecomposability` packages.

- [`vertex_decomposible_example.m2`](Macaulay2/vertex_decomposible_example.m2): Builds a simplicial complex from vertex labels and facets, tests vertex decomposability, and lists shedding vertices. Replace the example vertex and facet placeholders with actual data; setting `M2_BUILD_ONLY=1` runs only the construction step.

### `SageMath/`

SageMath scripts for subdivision, non-evasiveness, and homology calculations. Input facet files are supplied through `FACETS_FILE` and contain JSON or Python-style lists of facets.

- [`relative_barycentric_subdivision.sage`](SageMath/relative_barycentric_subdivision.sage): Computes a relative barycentric subdivision while preserving the subcomplex specified by `PROTECTIVE_FACETS`. Saves the resulting facets to `outputs/<KNOT_NAME>_relative_barycentric_subdivision.txt`.
- [`nonevasive_checker.sage`](SageMath/nonevasive_checker.sage): Checks non-evasiveness by recursively testing vertex links and deletions, with connectivity, Euler characteristic, and reduced-homology rejection checks. Supports configurable vertex search orders through `SEARCH_STRATEGY` and reproducible random ordering through `RANDOM_SEED`; prints `NON_EVASIVE` or `EVASIVE`.
- [`nonevasive_homology_deletion_checker.sage`](SageMath/nonevasive_homology_deletion_checker.sage): Examines all sets of `floor(n/2) - 1` vertex deletions, where `n` is the original vertex count, and saves those leaving trivial reduced homology to `outputs/<name>_potential_cases.txt`. These are candidate cases, not certificates of non-evasiveness.
- [`remaining_homology_checker.sage`](SageMath/remaining_homology_checker.sage): Reads the saved candidate deletion sets, then computes reduced homology after deleting each remaining vertex individually from each candidate complex. Set `POTENTIAL_CASES_FILE` in the script to the matching input file; reports are printed and saved to `outputs/<name>_remaining_homology.txt`.

The SageMath scripts that save results create the `outputs/` folder when needed.

## References

Works referenced in this code can be found here:
- https://www3.math.tu-berlin.de/IfM/Nachrufe/Frank_Lutz/stellar/

- https://docs.gap-system.org/pkg/simpcomp/doc/manual.pdf

- https://macaulay2.com/doc/Macaulay2/share/doc/Macaulay2/SimplicialDecomposability/html/index.html
