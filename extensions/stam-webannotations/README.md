# STAM-WebAnnotations: Interoperability between W3C Web Annotations and STAM 

## Introduction

This is an extension on top of STAM that allows for interoperability between W3C Web Annotations and STAM.

There are some limitations to this model, as not everything that W3C Web Annotations support can be expressed in STAM:

To prevent confusion, we will consistently use the namespaces prefix `stam:`
for classes and properties STAM defines. We use other prefixes like
`oa:`,`dcterms:` for classes and properties from vocabularies used by the
Web Annotation model.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Data Model

W3C Web Annotations builds on RDF. This means that for interoperability to
work, all the RDF constraints posed in the core STAM specification *MUST* be adhered
to. This mostly entails that all identifiers should be URIs.

This extension does not specify any extensions to the STAM data model itself -
the core model suffices - instead, it defines some data annotation sets and
protocols for conversion.

## Mapping

Web Annotations formulates various *properties* (in the RDF sense) on
annotations. For instance, there is a `dcterms:creator`
(`http://purl.org/dc/terms/creator`) property that can be used on an
`oa:Annotation` to express who created it.

In STAM, all of these properties are possible as `data` (via `stam:AnnotationData`) on a `stam:Annotation`.
The core STAM data model does not need to be extended to allow using this
vocabulary, this extension simply offers a STAM Annotation Dataset
[webannotations.annotationset.json](webannotations.annotationset.json) which defines the
necessary keys. You *SHOULD* use this set for interoperability with web annotations.
For example, to express the creator and a simple textual value of an annotation using vocabulary compatible with Web Annotations, consider the following STAM JSON snippet:

```json
{
    "@type": "Annotation",
    "id": "https://example.org/annotation1",
    "data": [
        {
            "@type": "AnnotationData",
            "key": "http://purl.org/dc/terms/creator",
            "value": "proycon",
            "_part_of_set": "https://w3id.org/stam/extensions/webannotations.annotationset.json"
        },
        {
            "@type": "AnnotationData",
            "key": "http://www.w3.org/ns/oa#bodyValue",
            "value": "I like this part!",
            "_part_of_set": "https://w3id.org/stam/extensions/webannotations.annotationset.json"
        }
    ],
    "target": {
        "@type": "TextSelector",
        "source": "http://example.org/hello.txt"
        "offsets": {
            "begin": {
                "@type": "BeginAlignedCursor",
                "value": 0,
            }, 
            "end": {
                "@type": "BeginAlignedCursor",
                "value": 5,
            }, 
        }
    }
}
```

This translates to the following Web Annotation (JSON-LD):

```json
{
    "@context": "http://www.w3.org/ns/anno.jsonld",
    "id": "https://example.org/annotation1",
    "creator": "proycon",
    "bodyValue": "I like this part!"
    ...
}
```

Web Annotations have the notion of *body* which has no direct counterpart in STAM.
Implementations converting to Web Annotations *SHOULD* create a *single* body
with type `oa:SpecificResource` and *MUST* put inside it all
`stam:AnnotationData` elements that are not known to go on `oa:Annotation`.
Data that translate to known properties of `oa:Annotation` *MUST* be put on the
`oa:Annotation` directly. The only situation in which no body is created is if
there are no properties that should go into a body.

If translating Web Annotations to STAM, multiple bodies
*SHOULD* be translated to multiple independent STAM annotations.

The following example illustrates how usage of some custom vocabulary (fictitious) is
preserved nicely when translating STAM to web annotations:

```json
{
    "@type": "Annotation",
    "id": "https://example.org/annotation2",
    "data": [
        {
            "@type": "AnnotationData",
            "key": "http://purl.org/dc/terms/creator",
            "value": "proycon",
            "_part_of_set": "https://w3id.org/stam/extensions/webannotations.annotationset.json"
        },
        {
            "@type": "AnnotationData",
            "key": "http://example.org/nlp#part-of-speech",
            "value": "noun",
        }
    ],
    "target": {
        "@type": "TextSelector",
        "resource": "http://example.org/hello.txt",
        "offsets": {
            "begin": {
                "@type": "BeginAlignedCursor",
                "value": 6,
            }, 
            "end": {
                "@type": "BeginAlignedCursor",
                "value": 13,
            }, 
        }
    }
}
```

This translates to the following Web Annotation (JSON-LD):

```json
{
    "@context": "http://www.w3.org/ns/anno.jsonld",
    "id": "https://example.org/annotation1",
    "creator": "proycon",
    "body": {
        "@type": "SpecificResource",
        "http://example.org/nlp#part-of-speech": "noun"
    },
    "target": {
        "source": "https://example.org/hello.txt",
        "selector": {
            "type": "TextPositionSelector",
            "start": 6,
            "end": 13
        }
    }
}
```

The coordinate system for `stam:TextSelector` and `oa:TextPositionSelector` are
identical (unicode points). In the mapping, however,  any `stam:EndAlignedCursor` *MUST* first
be resolved to its absolute (begin-aligned) position.

If multiple web annotations reference the exact same body, then implementations *MAY*
optimize the web annotation representation by turning the body into a single
resource that is referenced from multiple annotations.

### Higher-order annotation and relative offsets

STAM allows formulating annotations relative to the annotations that contain
them (the `stam:AnnotationSelector` supports selecting text offsets relative to
the target annotation), such as words relative to sentences. This we call
higher-order annotation with relative offsets. 

An example of this can be found [here](../../examples/explicit_containment_rdf.json).
This has two annotations in STAM JSON, the first expresses a
sentence in a text, and the second expresses a word in that sentence formulated
relative to it. 

Converting this to Web Annotations, however, poses a problem. If a
`stam:AnnotationSelector` expresses such offsets, implementations *MUST* choose
one of two options for conversion:

1. Translate this to the Web Annotation model in the most direct way possible
   by having one `oa:Annotation` target another, and including a
   `oa:TextPositionSelector` as-if it was a text. This may be a stretching the
   web annotation model a bit, as such higher-order annotations are not
   specified by its specification, but it does not violate the specification
   either. This way the relative offset are maintained at the cost of extra complexity.
2. Resolve the relative annotations to absolute ones and make the webannotation
   target the resource directly, rather than the other annotation. This way the resulting
   solution is simpler, at the cost of losing the relative annotations.

If an implementation can't determine which choice is most appropriate, it *SHOULD* let the user decide.


### Limitations

When mapping STAM to Web Annotations:

* A `stam:AnnotationDataSet` itself can not be mapped to Web Annotations (out of
  scope), this also goes for any annotations using `stam:SetSelector`.

When mapping Web Annotations to STAM:

* As Web Annotations does not have the concept of annotation data set,
  implementations *SHOULD* allow users to associate some annotation data sets
  prior to the conversion. Any keys then found in the web annotation will be
  associated with those sets. Any keys that are not found *MUST* either be
  simply mapped to a single annotation data set, or to multiple annotation data
  sets that are created on the fly based on for instance a shared RDF
  namespace.
* Annotations on text in STAM are mediated by a `stam:TextSelector`. This
  always translates to a `oa:TextPositionSelector` in the Web Annotation model
  (and vice versa). The web annotation model supports a wide variety of
  selectors for different media types, STAM does not, it only references plain
  text. This extension therefore only supports `oa:TextPositionSelector`.
  Implementations parsing web annotations for STAM, when encountering any other
  selectors, *MUST* produce either an error or convert the selector to an
  `oa:TextPositionSelector` (`stam:TextSelector`) if possible.

### Functionality

For mapping Web Annotation to STAM:

* Implementations *MUST* implement proper JSON-LD parsing for Web Annotations
* Implementations *SHOULD* use a proper RDF triple store as a foundation

