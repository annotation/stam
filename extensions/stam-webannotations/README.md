# STAM-WebAnnotations: Interoperability between W3C Web Annotation and STAM 

## Introduction

This is an extension on top of STAM that allows for interoperability between
[W3C Web Annotation Data Model](https://www.w3.org/TR/annotation-model/) and STAM.

The [Web Annotation Data Model](https://www.w3.org/TR/annotation-model/) offers
a model for describing annotations in which the annotations and their targets
(any resource, not just text) can live distributed over the web. The [Web
Annotation Vocabulary](https://www.w3.org/TR/annotation-vocab/) specifies the
exact set of RDF classes and predicates used by the data model. Web Annotations
are typically serialized in JSON-LD with context
<http://www.w3.org/ns/anno.jsonld>.

There are some limitations to this model, as not everything that W3C Web
Annotations support can be expressed in STAM, and vice versa. This STAM extension 
describes how to map one to the other.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Data Model

The W3C Web Annotation Data Model builds on
[RDF](https://www.w3.org/TR/rdf11-concepts/). This means that for
interoperability to work, all the RDF constraints posed in the core STAM
specification *MUST* be adhered to. This mostly entails that all identifiers
*MUST* either be [IRI](https://datatracker.ietf.org/doc/html/rfc3987)s or
transformable into one, we recap from from section Identifiers in the main
specification:

> The public identifier of keys *MUST* be able to be transformed into an IRI as follows:
>    * It it already an IRI by itself (no transformation necessary).
>    * It forms an IRI when appended to the public identifier of the annotation data set. If identifier of the annotation data set does not end in `/` or `#`, an extra `/` *SHOULD* be inserted as delimiter in the concatenation.

This extension does not specify any extensions to the STAM data model itself -
the core model suffices - instead, it defines some data annotation sets and
protocols for conversion.

## Mapping STAM to Web Annotations

[JSON-LD](https://www.w3.org/TR/json-ld/) is the preferred serialization format
for Web Annotations, using the context definition
`http://www.w3.org/ns/anno.jsonld`. This STAM extension defines how to
serialize STAM to valid Web Annotations in JSON-LD. Note that although STAM
JSON looks very similar to JSON-LD, it is not.

For interoperability with Web Annotation, you can reuse a lot of the
vocabulary defined in `http://www.w3.org/ns/anno.jsonld` from within STAM. We
prescribe that you *MUST* use a STAM Annotation DataSet with that exact URI as
identifier if you want to use any of the terms of that vocabulary. The keys in
the JSON-LD file then correspond one-to-one to the STAM datakeys in the set.
This allows us to use much of the web annotation vocabulary from STAM without
any complicated mappings. We will refer to this as the w3anno set in this
documentation, simply to avoid having to mention the full URI every time.

Let's illustrate this with an example. Consider the following STAM
Annotation in STAM JSON (partial excerpt) in which we express an annotation
using vocabulary from the Web Annotation Data Model (the key `creator` is
defined there).

```json
{
    "@type": "Annotation",
    "@id": "https://example.org/annotation1",
    "data": [
        {
            "@type": "AnnotationData",
            "set": "http://www.w3.org/ns/anno.jsonld"
            "key": "creator",
            "value": "proycon",
        }
    ],
    "target": {
        ...
    }
}
```

This translates to the following Web Annotation (JSON-LD):

```json
{
    "@context": "http://www.w3.org/ns/anno.jsonld",
    "id": "https://example.org/annotation1",
    "creator": "proycon",
    "target": {
        ...
    }
}
```

You're not limited to only the w3anno set, it is merely a convenience if you
want to directly reuse terms defined in their JSON-LD context definition, and
their use is *RECOMMENDED* if you know in advance you want to export to web
annotations. Aside from these, you *MAY* use any RDF predicate/object as a key/value
as we established mapping rules for public identifiers in STAM and IRIs. 

Web Annotations have the notion of *body*  which corresponds more or less to what is
called `data` in STAM JSON, i.e. a collection of STAM AnnotationData elements. If
there is multiple data associated with an annotation, they *SHOULD* translate to a
*single* body element. A type of `DataSet` *SHOULD* be associated with the WebAnnotation body. 

(If conversely, translating Web Annotations to STAM, multiple bodies *SHOULD* be translated
to multiple STAM annotations).

In the first examples above we showed that `creator` was mapped directly onto
the annotation (rather than the body); implementations of this extension
*SHOULD* convert annotation data in the w3anno set
(`http://www.w3.org/ns/anno.jsonld`) to properties directly on the web
annotation *if and only if* these properties are commonly expressed on the web
annotation. Any other properties *SHOULD* go into the `body` scope. As this can
not be unambiguously determined, implementations have a fair degree of freedom
in choosing which properties they assign to the annotation as a whole, and which to a
body (e.g. by parametrising this).

Consider the next STAM JSON excerpt where we do not use the w3anno set but
other sets that map to RDF via the mapping rules:

```json
{
    "@type": "Annotation",
    "@id": "https://example.org/annotation1",
    "data": [
        {
            "@id": "D1",
            "@type": "AnnotationData",
            "set": "http://example.org/my-set"
            "key": "valuation",
            "value": "I like this part!",
        },
        {
            "@id": "D2",
            "@type": "AnnotationData",
            "set": "http://schema.org",
            "key": "contentRating",
            "value": 5,
        }
    ],
    "target": {
        ...
    }
}
```

This translates to the following Web Annotation (JSON-LD):

```json
{
    "@context": "http://www.w3.org/ns/anno.jsonld",
    "id": "https://example.org/annotation1",
    "body": {
        "type": "DataSet",
        "https://example.org/my-set/valuation": "I like this part!",
        "https://schema.org/contentRating": 5,
    },
    "target": {
        ...
    }
}
```

This example shows a few other things

* The body has `type: DataSet`, which is *RECOMMENDED*. 
* The JSON-LD keys will be full IRIs as they are not part of the context. Implementations *MAY* generate additional context and use aliases.
* The STAM dataset's public identifier and key public identifier have been joined to form a valid RDF URI,
this *SHOULD* be done by concatenating them, adding a `/` in the middle *if and only if* the set identifier does not already end in `/` or `#`. 
* Other ontologies can be used as if they are a STAM Annotation Dataset (such as schema.org in this example). The important criterion is only that the identifiers match, taking the above concatenation rule in consideration.
* The public identifiers of `AnnotationData` can not be preserved, they are lost in this conversion.

Next, we show an example where the data value (STAM `DataValue`) maps to RDF, first we recap from the main specification:

> * Any String value that is a valid [IRI](https://datatracker.ietf.org/doc/html/rfc3987) *SHOULD* be interpreted as such
>  in conversion from/to RDF.

STAM JSON excerpt:

```json
{
    "@type": "Annotation",
    "@id": "https://example.org/annotation1",
    "data": [
        {
            "@id": "D1",
            "@type": "AnnotationData",
            "set": "http://www.w3.org/ns/anno.jsonld"
            "key": "creator",
            "value": "https://orcid.org/0000-0002-1046-0006",
        },
    ],
    "target": {
        ...
    }
}
```

JSON-LD output:

```json
{
    "@context": "http://www.w3.org/ns/anno.jsonld",
    "id": "https://example.org/annotation1",
    "creator": { "id": "https://orcid.org/0000-0002-1046-0006" },
    "target": {
        ...
    }
}
```

Compare this to the first example and notice the extra `id` in the JSON-LD output.

Not shown in the excerpts thus-far is the target, which serves the same purpose
in both STAM and Web Annotations. Let's take a look at a more complete STAM
JSON example now that includes the target:

```json
{
    "@type": "Annotation",
    "@id": "https://example.org/annotation1",
    "data": [
        {
            "@type": "AnnotationData",
            "set": "http://www.w3.org/ns/anno.jsonld"
            "key": "creator",
            "value": "proycon",
        },
        {
            "@type": "AnnotationData",
            "set": "http://schema.org",
            "key": "contentRating",
            "value": 5,
        }
    ],
    "target": {
        "@type": "TextSelector",
        "resource": "http://example.org/hello.txt"
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
    "body": {
        "type": "DataSet",
        "http://schema.org/contentRating": 5, 
    }
    "target": {
        "source": "https://example.org/hello.txt",
        "selector": {
            "type": "TextPositionSelector",
            "start": 0,
            "end": 5
        }
    }
}
```

The underlying coordinate system for STAM's `TextSelector` and w3anno's
`TextPositionSelector` are identical (unicode points, 0-indexed, end
non-inclusive). STAM's `TextSelector` however, offers more expressive power,
any `stam:EndAlignedCursor` *MUST* first be resolved to its absolute
(begin-aligned) position. 

### Higher-order annotation and relative offsets

STAM allows formulating annotations relative to the annotations that contain
them; the `AnnotationSelector` supports selecting text offsets relative to the
target annotation. This can for example be used for expressing words relative
to sentences. This we call higher-order annotation with relative offsets. 

An example of this can be found [here](../../examples/explicit_containment_rdf.json).
This has two annotations in STAM JSON, the first expresses a
sentence in a text, and the second expresses a word in that sentence formulated
relative to it. 

Converting this to Web Annotations, however, poses a problem. If a
`stam:AnnotationSelector` expresses such offsets, implementations *MUST* choose
one of two options for conversion:

1. Resolve the relative annotations to absolute ones and make the webannotation
   target the resource directly, rather than the other annotation. This way the resulting
   solution is simpler, at the cost of losing the relative annotations.
2. Translate this to the Web Annotation model in the most direct way possible
   by having one webannotation target another, and including a
   `TextPositionSelector` as-if it was a text. This may be a stretching the
   web annotation model a bit, as such higher-order annotations are not
   specified by its specification, but it does not violate the specification
   either. This way the relative offset are maintained at the cost of extra complexity.

If an implementation can't determine which choice is most appropriate, it *MAY* let the user decide, e.g. via a parameter.

### Multiple targets (Complex selectors)

In STAM we have the notion of *complex selectors*, a selector which selects multiple targets.
This is either a  `MultiSelector` or `DirectionalSelector`, `CompositeSelector`.

The [Web Annotation Data Model](https://www.w3.org/TR/annotation-model/) does
not describe a clear unequivocal mechanism for referencing multiple targets.
The underlying [Web Annotation
Vocabulary](https://www.w3.org/TR/annotation-vocab/), however, does propose
some solutions in section D. These, however, are not normative for the Web
Annotation standard. They do make for the best and easiest translation when
mapping from/to STAM. We therefore consider them *RECOMMENDED*:

* [oa:Composite](https://www.w3.org/TR/annotation-vocab/#composite) can be used for STAM's `CompositeSelector`.
* [oa:Independents](https://www.w3.org/TR/annotation-vocab/#independents) can be used for STAM's `MultiSelector`.
* [oa:List](https://www.w3.org/TR/annotation-vocab/#list) can be used for STAM's `DirectionalSelector`.

Consider this STAM JSON excerpt in which the annotations targets a discontinuous text (two fragments) as one:

```json
    "target": {
        "@type": "CompositeSelector",
        "selectors": [
            {
                "@type": "TextSelector",
                "resource": "http://example.org/hello.txt"
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
            },
            {
                "@type": "TextSelector",
                "resource": "http://example.org/hello.txt"
                "offsets": {
                    "begin": {
                        "@type": "BeginAlignedCursor",
                        "value": 10,
                    }, 
                    "end": {
                        "@type": "BeginAlignedCursor",
                        "value": 15,
                    }, 
                }
            },
        ]
    }
```

This would translate to the following JSON-LD except for Web Annotations. As the mappings we just introduced are not part of the w3anno JSON-LD context we've been using, we will write their IRIs in full in the following example:

```json
{
    "@context": "http://www.w3.org/ns/anno.jsonld",
    ...
    "target": {
        "type": "http://www.w3.org/ns/oa#Composite",
        "items": [
            {
                "source": "https://example.org/hello.txt",
                "selector": {
                    "type": "TextPositionSelector",
                    "start": 0,
                    "end": 5
                }
            },
            {
                "source": "https://example.org/hello.txt",
                "selector": {
                    "type": "TextPositionSelector",
                    "start": 10,
                    "end": 15
                }
            }
        ]
    }
}
```

Do consider that due to this being non-normative in the Web Annotation
specification, it may not be implemented widely.

A `MultiSelector` *MAY* also be mapped simply to multiple `target` elements in
the WebAnnotation output. Recall that this means that the annotation applies to
all of targets equally, individually and independently.

### Referencing external resources and interpreting JSON-LD contexts

A lot of the value in using linked data comes from the ability to actually
*link* to external resources, which may live anywhere and are identified by an
[IRI](https://datatracker.ietf.org/doc/html/rfc3987). RDF triples take an IRI
as object and RDF makes a strong distinction between string literals and IRIs.
STAM, however, does not make such a distinction in its data values, as there is
just the string literal.

If we convert from STAM to Web Annotations, the distinction between
IRIs and string literals becomes important again. Fortunately, the JSON-LD
serialization solves this problem for us. JSON by itself does
not have the distinction either, but the JSON-LD context adds these semantics.
When converting from STAM to Web Annotations, users *SHOULD* be able to specify
additional JSON-LD contexts with are then added to the `@context` part of the
output. For this to work, the converter *SHOULD* parse the specified JSON-LD
contexts and use the aliases defined in it.

If this is to abstract, consider the following STAM JSON example (partial excerpt):

```json
{
    "@type": "Annotation",
    "@id": "https://example.org/annotation1",
    "data": [
        {
            "@type": "AnnotationData",
            "set": "https://example.org/my_vocab"
            "key": "review",
            "value": "https://example.org/my_review",
        },
    ],
    "target": {
        ...
    }
}
```

This translates to the following web annotation (partial excerpt) in JSON-LD:


```json
{
    "@context": "http://www.w3.org/ns/anno.jsonld",
    "id": "https://example.org/annotation1",
    "creator": "proycon",
    "body": {
        "type": "DataSet",
        "https://example.org/my_vocab/review": "https://example.org/my_review", 
    }
    "target": {
            ...
    }
}
```

At this point `https://example.org/my_review` would be just string literal. To
solve this,  we make a JSON-LD context for our vocabulary, let's pretend we
host this at `https://example.org/my_vocab.jsonld`:

```json
{   
    "@context": {
        "myvocab": "https://example.org/my_vocab/",
        "review": {
            "@type": "@id",
            "@id": "myvocab:review"
        }
    },
}
```

Now all we have to do is pass our STAM to web annotation converter our extra
context to include. STAM to Webannotation converters parse this JSON-LD context
and resolve the full IRIs to the aliases mentioned. We then get the following
output instead:

```json
{
    "@context": [ "http://www.w3.org/ns/anno.jsonld","https://example.org/my_vocab.jsonld"],
    "id": "https://example.org/annotation1",
    "creator": "proycon",
    "body": {
        "type": "DataSet",
        "review": "https://example.org/my_review", 
    }
    "target": {
            ...
    }
}
```

The predicate which we saw in expanded form before is now resolved to its alias and any JSON-LD capable parser will now
interpret the value as an IRI rather than a string literal, as that is how it is defined in the context (via `@type`: `@id`).

Because of the extra type information and cleaner web annotation output, the
use of JSON-LD contexts for your vocabulary is *RECOMMENDED*.

### Hierarchical data structures

As RDF can encode generic knowledge graphs, you can have an arbitrary nesting
of information in for instance the annotation body, example:

```json
{
    "@context": [
        "http://www.w3.org/ns/anno.jsonld",
        {
            "sdo": "http://schema.org/",
            "myvocab": "https://example.org/my_vocab/",
        }
    ],
    "body": {
        "@type": "DataSet",
        "reviewer": {
            "@type": "sdo:Person",
            "sdo:givenName": "John",
            "sdo:familyName": "Doe",
            "sdo:affiliation": {
                "@type": "sdo:Organization",
                "sdo:name": "United Nations",
            }
        }
    },
    ...
}
```

In RDF-terms, both reviewer and affiliation are so-called blank nodes, as no ID is associated with them.

If you want to encode this nested information in STAM, you *SHOULD* use the `Map` DataValue type, as shown in the following STAM JSON excerpt:

```json
{
    "@type": "Annotation",
    "@id": "https://example.org/annotation1",
    "data": [
        {
            "@type": "AnnotationData",
            "set": "http://www.w3.org/ns/anno.jsonld"
            "key": "type",
            "value": "DataSet",
        },
        {
            "@type": "AnnotationData",
            "set": "https://example.org/my_vocab/",
            "key": "reviewer",
            "value": {
                "@type": "Map",
                "type": {
                    "@type": "String",
                    "value": "http://schema.org/Person",
                },
                "http://schema.org/givenName": {
                    "@type": "String",
                    "value": "John",
                },
                "http://schema.org/familyName": {
                    "@type": "String",
                    "value": "Doe",
                },
                "http://schema.org/affiliation": {
                    "@type": "Map",
                    "http://www.w3.org/1999/02/22-rdf-syntax-ns#type": {
                        "@type": "String",
                        "value": "http://schema.org/Organization",
                    },
                    "http://schema.org/name": {
                        "@type": "String",
                        "value": "United Nations",
                    }
                }

            }
        }
    ],
    "target": {
        ...
    }
}
```

Map keys *SHOULD* be either be full IRIs or otherwise are passed as-is in conversion to RDF / Web Annotation.
This implies that keys that are not full IRIs may be undefined in the output if there is no JSON-LD context that
covers those. Note that unlike `DataKey` in STAM, map keys do not carry their own set. 

The key `http://www.w3.org/1999/02/22-rdf-syntax-ns#type` translates to `@type`
in JSON-LD, converters *MUST* implement this conversion as `@type` in STAM JSON
is a different keyword. In the example above we just used `type`, which will be
mapped to JSON-LD as-is and is given meaning by the JSON-LD context.

### Foreign targets and selectors

The Web Annotation Data model has a large number of selectors for different
format and media types which do not exist in STAM, so we call them *foreign*.
Still, you might want to make use of these foreign targets and selectors when
converting to web annotations. The way to encode them in STAM is as annotation
data using the `target` key in the w3anno dataset
(`http://www.w3.org/ns/anno.jsonld`, which covers all web annotation vocabulary
and was established earlier in this specification for use in the conversion
process).

Though `target` can take a simple string as value as is also the case in the
web annotation model, in most cases you will want to take a `Map` as value and
mirror the structured linked data representation for the selector you want.
Example, say we want to output the following Web Annotation (JSON-LD):

```json
{
    "@context": "http://www.w3.org/ns/anno.jsonld",
    "body": {
        ...
    },
    "target": [
        {
            "source": "https://example.org/hello.txt",
            "selector": {
                "type": "TextPositionSelector",
                "start": 0,
                "end": 5
            }
        },
        {
            "source": "https://example.org/hello.xml",
            "selector": {
                "type": "XPathSelector",
                "value": "/html/body/p[1]/span[1]"
            }
        },
    ]
    ...
}
```

(Note that multiple targets in the web annotation data model means that the
annotation applies to each of the targets equally and independently (cf. STAM's
MultiSelector))

The first target is a normal one that is covered by STAM's
`TextSelector`, the second however, has no STAM counterpart. We can still encode
this by putting that target in the annotation data as follows, following all
the other rules established in this specification. That leads us to this STAM
JSON excerpt as input for the conversion:

```json
{
    "@type": "Annotation",
    "@id": "https://example.org/annotation1",
    "data": [
        {
            "@type": "AnnotationData",
            "set": "http://www.w3.org/ns/anno.jsonld"
            "key": "target",
            "value": {
                "@type": "Map",
                "value": {
                    "source": {
                        "@type": "String",
                        "value": "https://example.org/hello.xml",
                    },
                    "selector": {
                        "@type": "Map",
                        "type": {
                            "@type": "String",
                            "value": "XPathSelector",
                        },
                        "value": { 
                            "@type": "String",
                            "value": "/html/body/p[1]/span[1]"
                        }
                    },
                }
            }
        },
    ],
    "target": {
        "@type": "TextSelector",
        "resource": "http://example.org/hello.txt"
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

It may feel odd to have a target in the annotation data rather than as an
actual target, but as far as STAM is concerned it's just annotation data like
any other, and it's pretty agnostic about it. Targets in STAM have their own
specific semantics. This pseudo-target only gains its meaning after it's
converted to web annotations and interpreted in that model.

### Limitations

* A `stam:AnnotationDataSet` itself can not be mapped to Web Annotations (out of
  scope), this also goes for any annotations using `stam:DataSetSelector`.
* Public identifiers for `AnnotationData` are lost. This also implies that annotations using `stam:AnnotationDataSelector` can not be converted. The same also applied to `stam:DataKeySelector`. All these, however, are more interesting for STAM's internal model and out of scope for Web Annotations.

## Mapping Web Annotation to STAM

Mapping Web Annotation to STAM generally follows the inverse of what we have
already seen, but is not strictly specified in the current specification.
However, Web Annotation and RDF upon which it builds forms a broader model than
STAM typically provides, so not all that can be expressed there can be
unambiguously expressed in STAM terms. 

### Limitations 

* As Web Annotations does not have the concept of annotation data set,
  implementations *SHOULD* allow users to associate some annotation data sets
  prior to the conversion. Any keys then found in the web annotation will be
  associated with those sets. Any keys that are not found *MUST* either be
  simply mapped to a single annotation data set, or to multiple annotation data
  sets that are created on the fly based on for instance a shared RDF
  namespace.
* Annotations on text in STAM are mediated by a `TextSelector`. This
  always translates to a `TextPositionSelector` in the Web Annotation model
  (and vice versa). The web annotation model supports a wide variety of
  selectors for different media types which STAM does not, it only references plain
  text. This extension therefore only supports w3anno `TextPositionSelector`.
  Implementations parsing web annotations for STAM, when encountering any other
  selectors, *MUST* produce either an error or convert the selector to an
  STAM `TextSelector` if deemed possible.
