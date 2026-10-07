"""Barebones exact non-evasiveness checker for a simplicial complex.

Run with, for example:

    FACETS_FILE=knots/example.txt \
    SEARCH_STRATEGY=random \
    RANDOM_SEED=12345 \
    sage scripts/nonevasive_check.sage

The facets file must contain a JSON or Python-style list of facets.
"""

import ast
import json
import os
import random
from collections import Counter, deque

from sage.all import ZZ
from sage.topology.simplicial_complex import SimplicialComplex


VALID_SEARCH_STRATEGIES = {
    "greedy",
    "outer_layer",
    "random",
    "max_degree",
    "lexical",
    "reverse_lexical",
}


def load_facets_from_file(path):
    """Load and validate a JSON or Python-style list of integer facets."""
    with open(path, "r", encoding="utf-8") as facets_input:
        text = facets_input.read()

    try:
        facets = json.loads(text)
    except json.JSONDecodeError:
        facets = ast.literal_eval(text)

    if not isinstance(facets, (list, tuple)) or not facets:
        raise ValueError("The facets file must contain a nonempty list of facets")

    normalized_facets = []
    for index, facet in enumerate(facets, start=1):
        if not isinstance(facet, (list, tuple)) or not facet:
            raise ValueError(f"Facet {index} must be a nonempty list or tuple")
        if any(type(vertex) is not int for vertex in facet):
            raise ValueError(f"Facet {index} contains a non-integer vertex label")
        if len(set(facet)) != len(facet):
            raise ValueError(f"Facet {index} repeats a vertex")
        normalized_facets.append(list(facet))

    return normalized_facets


def delete_vertex(K, vertex):
    """Return the deletion K - vertex."""
    deletion = SimplicialComplex(K.facets())
    deletion.remove_faces([[vertex]])
    return SimplicialComplex(deletion.facets())


def is_simplex(K):
    """Return whether K is one nonempty simplex."""
    vertices = set(K.vertices())
    facets = list(K.facets())
    return (
        bool(vertices)
        and len(facets) == 1
        and set(facets[0]) == vertices
    )


def is_tree(K):
    """Return whether K is a one-dimensional tree."""
    return K.dimension() == 1 and K.graph().is_tree()


def vertex_eccentricities(K):
    """Compute 1-skeleton eccentricities for outer-layer ordering."""
    vertices = list(K.vertices())
    graph = K.graph()
    eccentricities = {}

    for source in vertices:
        distances = {source: 0}
        queue = deque([source])

        while queue:
            vertex = queue.popleft()
            next_distance = distances[vertex] + 1
            for neighbor in graph.neighbor_iterator(vertex):
                if neighbor not in distances:
                    distances[neighbor] = next_distance
                    queue.append(neighbor)

        if len(distances) == len(vertices):
            eccentricities[source] = max(distances.values())
        else:
            eccentricities[source] = len(vertices) + 1

    return eccentricities


def get_vertices_by_strategy(K, strategy="random", rng=None):
    """Return every vertex in the requested search order."""
    if strategy == "greedy":
        return sorted(
            K.vertices(),
            key=lambda vertex: (len(K.link([vertex]).facets()), vertex),
        )

    if strategy == "outer_layer":
        eccentricities = vertex_eccentricities(K)
        return sorted(
            K.vertices(),
            key=lambda vertex: (
                -eccentricities[vertex],
                len(K.link([vertex]).facets()),
                vertex,
            ),
        )

    if strategy == "random":
        vertices = list(K.vertices())
        (rng or random).shuffle(vertices)
        return vertices

    if strategy == "max_degree":
        facet_degree = Counter(
            vertex for facet in K.facets() for vertex in facet
        )
        return sorted(
            K.vertices(),
            key=lambda vertex: (-facet_degree[vertex], vertex),
        )

    if strategy == "lexical":
        return sorted(K.vertices())

    if strategy == "reverse_lexical":
        return sorted(K.vertices(), reverse=True)

    raise ValueError(f"Unknown search strategy: {strategy}")


def homology_group_is_trivial(group):
    """Return whether an integral homology group has no invariants."""
    return len(group.invariants()) == 0


def has_trivial_reduced_homology(K):
    """Apply the single integral reduced-homology rejection test."""
    homology = K.homology(reduced=True, base_ring=ZZ)
    return all(
        homology_group_is_trivial(group)
        for group in homology.values()
    )


def is_nonevasive(K, strategy="random", rng=None):
    """Decide non-evasiveness by exact, uncached link/deletion recursion."""
    if not K.vertices():
        return False

    if is_simplex(K) or K.cone_vertices():
        return True

    if K.dimension() == 1:
        return is_tree(K)

    # Every non-evasive complex is contractible, so these are sound
    # rejection tests.  Passing them does not certify non-evasiveness.
    if not K.is_connected():
        return False

    if K.euler_characteristic() != 1:
        return False

    if not has_trivial_reduced_homology(K):
        return False

    for vertex in get_vertices_by_strategy(K, strategy, rng=rng):
        # Both children must be non-evasive.  Check the usually smaller link
        # first so a failed link avoids exploring the deletion subtree.
        link = K.link([vertex])
        if not is_nonevasive(link, strategy=strategy, rng=rng):
            continue

        deletion = delete_vertex(K, vertex)
        if is_nonevasive(deletion, strategy=strategy, rng=rng):
            return True

    return False


def normalize_strategy(raw_strategy):
    """Accept underscore, hyphen, or space-separated strategy names."""
    strategy = raw_strategy.strip().lower().replace("-", "_").replace(" ", "_")
    aliases = {
        "reverse_lex": "reverse_lexical",
        "reverse_lexicographic": "reverse_lexical",
    }
    return aliases.get(strategy, strategy)


facets_file = os.environ.get("FACETS_FILE")
if not facets_file:
    raise SystemExit("Set FACETS_FILE to the path of a facets file.")
if not os.path.isfile(facets_file):
    raise FileNotFoundError(f"FACETS_FILE was not found: {facets_file}")

seed_text = os.environ.get("RANDOM_SEED")
if seed_text is None:
    seed = random.SystemRandom().randrange(1_000_000_000)
else:
    try:
        seed = int(seed_text)
    except ValueError as error:
        raise ValueError("RANDOM_SEED must be an integer") from error

search_strategy = normalize_strategy(
    os.environ.get("SEARCH_STRATEGY", "random")
)
if search_strategy not in VALID_SEARCH_STRATEGIES:
    valid_names = ", ".join(sorted(VALID_SEARCH_STRATEGIES))
    raise ValueError(f"SEARCH_STRATEGY must be one of: {valid_names}")

facets = load_facets_from_file(facets_file)
complex_to_check = SimplicialComplex(facets)
rng = random.Random(seed)

result = is_nonevasive(
    complex_to_check,
    strategy=search_strategy,
    rng=rng,
)
print("NON_EVASIVE" if result else "EVASIVE")
