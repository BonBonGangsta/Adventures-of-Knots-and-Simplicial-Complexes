-- vertexLabels#i is the original integer label represented by x_i.
print "PROGRESS 1/6: Loading Macaulay2 packages...";
needsPackage "SimplicialComplexes";
needsPackage "SimplicialDecomposability";

print "PROGRESS 2/6: Packages loaded; reading facet data...";

vertexLabels = {1...n};

facetData = {
    {1, .., ..n}
};

print "PROGRESS 3/6: Facet data loaded; building the simplicial complex...";

R = QQ[x_0..x_(#vertexLabels-1)];
vertexVariables = flatten entries vars R;

labelToVariable = new HashTable from apply(
    #vertexLabels,
    i -> vertexLabels#i => vertexVariables#i
    );

facetMonomials = apply(
    facetData,
    F -> product apply(F, label -> labelToVariable#label)
    );

Delta = simplicialComplex facetMonomials;

print (
    "Created Delta with " | toString(#vertexLabels) |
    " labelled vertices and " | toString(#(facets Delta)) | " facets."
    );

print "PROGRESS 4/6: Starting the vertex-decomposability test; this may take a long time...";

VertexDecomp = isVertexDecomposable Delta;

print (
    "Is this vertex decomposable? " |
    toString VertexDecomp
    );

print "PROGRESS 5/6: Vertex-decomposability test finished; finding shedding vertices...";

sheddingVertices = select(
    vertices Delta,
    v -> isSheddingVertex(v, Delta)
    );

print (
    "Shedding vertices: " |
    toString sheddingVertices
    );

print "PROGRESS 6/6: All calculations finished.";
