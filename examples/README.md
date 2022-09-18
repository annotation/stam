# Examples

## Explicit containment

This example shows how you can model explicit containment and relative offset
using higher-order annotations. Targeting a short text, it annotates the second
sentence of the text, and the third word in that sentence (relative).

The vocabulary is ad-hoc and (implicitly) lumped into one
annotation data set. The JSON serialisation uses inline annotations.

* [text resource](explicit_containment.txt)
* [STAM JSON](explicit_containment.json)

## RDF constraints

This example builds on the previous one and shows how to make a STAM model
comply to the constraints needed for RDF. Vocabularies are no longer ad-hoc but
specific:

* `rdf:type` is used to denote the annotating type here
* the value of the type itself uses the [NIF 2.0](https://persistence.uni-leipzig.org/nlp2rdf/) vocabulary

* [text resource](explicit_containment.txt)
* [STAM JSON](explicit_containment_rdf.json)

