# Simple Text Annotation Model

## Introduction

STAM is a simple data model for text annotation.

Our aim with STAM is to lay a simple but strong foundation for stand-off annotations on text. We define
annotations as any kind of remark, classification/tagging on any particular portion(s) of the text. Examples may be
linguistic annotations, editorial annotations, technical annotations, or whatever comes to mind. STAM does not define
the vocabularies, it merely defines a model so *you* can define your own vocabularies and a model in which you can
express your annotations using your own vocabularies.

Simplicity is the keyword, the data model must be easy to understand and use. It does not depend on other more complex
data models such as RDF, Web Annotations, TEI, FoLiA or whatever, but instead addresses the problem from a more
functional and pragmatic perspective. STAM does offer a significant degree of formalisation and allows for validation to
ensure that the annotations are correct and references to the text are valid. This level of formalism makes conversion
from STEM to more more complex Linked Open Data formats feasible, the reverse, however, would be subject to some strict
contraints.

STAM operates on any of three levels of increased abstraction/complexity/formality (the concepts are correlated to I
group them together), depending on the needs of the user/tool developer/data provider:

1. Untyped Annotation - Annotations are ad-hoc constructs with no formal semantics.
2. Typed Annotation - Annotations are validated against a normative user-defined vocabularies.
3. Constrained Annotation - Like above, but additionally imposes user-defined constraints on how annotations and
   annotation types relate to other annotations/annotation types.

Goals/Features:

 * Stand-off annotations on plain text
 * Simple and minimal; no unnecessary abstractions/complexity/formality, approachable at multiple levels.
 * No commitment to any annotation paradigm aside from stand-off annotation
 * Formality & validation: the data model allows for high degree of strictness and compliance to a specific
   user-defined formalism. The ability to validate annotations of the data is one of the core goals.
 * Usable with user-defined vocabularies, full separation between underlying and data model and vocabularies
 * Usable with user-defined annotation paradigms
 * Interoperability but no dependency:
    * Self-sustained, STAM does not rely on other data models (e.g. RDF) that introduce
      additional complexity.
    * Exportable to webannotations / RDF, when used with the higher levels of formality.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Data Model

In this section, we will describe the STAM data model, note that the data model is detached from any specific
serialisation format. Usually, the default serialisation will be JSON, in which case class in the data model
can be instantiated as a JSON object.

### Annotation Set

Attributes:

* ``target`` - The URL of the resource that is annotated, treated as plain text
* ``checksum`` - sha256 checksum of the target file
* ``modeltype`` - A URL to a **Constraint Set** (more on this later on)
* ``annotations`` -  List of **Annotation** objects.

An Annotation Set is a set of annotations on a particular target text. Aside
from the fact that the annotations in a set are on the same target, there is no
intrinsic meaning in them being grouped together. Each annotation set *MUST*
have exactly one target. The target *MUST* refer to either a full URL or a path
on the local filesystem.  Libraries and tools *MUST* be able to download the
data pointed to by URLs, a dead link renders the annotation set invalid. The
target is interpreted as plain text and *MUST* be UTF-8 encoded. Either the
target *MUST* be in NFC normalisation, or NFC normalisation must be applied
after loading.  All text position offsets in STAM *MUST* refer to
NFC-normalised unicode points (i.e. characters, not bytes).

The target *may* still contain markup such as XML, MarkDown, but this is opaque
to the annotation model.

A checksum *SHOULD* be provided over the full target text, this is used to ensure the annotations describe the right text.

### Annotation

Attributes:

* ``id`` - Unique Id for the annotation (optional)
* ``begin`` - Selector begin character position in the text (optional, absence denotes metadata/higher-order annotation)
* ``end`` - Selector end character position in the text (optional, absende denotes metadata/higher-order annotation)
* ``text`` - Text value of the pointed text (optional, for validation purposes)
* ``type`` -  URL to the vocabulary used in the body (or in-line definition)
* ``body`` - The body of the annotation, a scalar value or a key/value map (optional)

The ``id`` attribute is *OPTIONAL* but *RECOMMENDED*. An identifier uniquely
identifies an annotation. The value it is given is an arbitrary identifier (a
string) which must be unique for the entire annotation set, it is *RECOMMENDED*
for it be even globally unique even over multiple annotation sets. No further
contraints are set on the format of identifiers for STAM, but different
serialisations/export options *MAY* posit additional constraints.

The ``begin`` and ``end`` attributes, when provided, *MUST* describe the character position in NFC-normalised unicode
points, in reference to the ``target`` of the annotation set. Indexing *MUST* be zero-based the end offset *must* be
non-inclusive.  The ``begin`` and ``end`` attributes *MAY* be omitted when the annotation covers the target file as a
whole and is less strictly related to any text span. In this case it *SHOULD* be interpreted as metadata, either over
the text as a whole or over another annotation (higher-order annotation or annotation over annotation), if the body
makes reference to any other annotation.

The ``text`` attribute is *OPTIONAL* but *RECOMMENDED*. When used, its value *MUST* be a
copy of the exact same text string as the ``begin`` and ``end`` attributes point to. This is
merely an extra reduncancy level to ensure correctness and aid interpetability.
It is used in validation and tools *SHOULD* be able to automatically derive it
if not explicitly supplied.

The ``body`` attribute provides the body of the annotation, i.e. the actual
values associated with the annotation.  The ``body`` attribute *MAY* be omitted
entirely if there is no need to associate any values with the annotation. If a
body value is provided, it can be either a simple primitive such a a
string/integer/float or boolean, or an actual key/value map. The latter allows
you to associate multiple values with the annotation and to relate the values
to a vocabulary.

The ``type`` attribute, if provided, *MUST* point to a URL describing a **vocabulary set**. It *MAY* be a list of
multiple vocabulary sets, all of which will apply equally and *MUST NOT* have any conflicting terms.  All keys and
values in the ``body`` *MUST* comply to the referenced vocabulary.  Providing a type/vocabulary is *RECOMMENDED* but
*NOT REQUIRED*. Only the bodies of typed annotations can be validated.  If no vocabulary is provided, the key/value map
of ``body`` *MAY* contain anything and is completely unchecked, which may be desireable in some pragmantic ad-hoc contexts.
This allows users to use STAM at the level of abstraction they are comfortable with. Untyped annotations are simpler,
but less expressive.

It is possible that an annotation can not be interpreted by itself but relies on other annotations
for a full interpretation. In such cases, the body of the annotation *SHOULD* have a key that refers to the ID of
one or more another annotation. It is up to the vocabulary used to defined this.

### Vocabulary Set

Attributes:

* ``base`` - A list of zero or more other vocabulary sets to import (URLs), this offers some modularity.
    * TODO: describe how conflicts are handled
* ``terms`` - An unordered list of **vocabulary terms**

The vocabulary set defines a vocabulary. The vocabulary set essentialy forms the type of the annotation. The
``type`` attribute of an annotation is the URL of a vocabulary set. Vocabulary sets form the second level of
abstraction/complexity/formalism of STAM and are therefore *NOT REQUIRED*.

### Vocabulary Item

Attributes:

* ``key`` - An identifier, the string *MUST* be unique at the level which it is specified. The key *MUST NOT* contain any slashes.
* ``type`` - The datatype for this key; all types start with ``@`` to distinguish them from closed-vocabulary options.. (The maximum size
         of the primitive data types is not strictly defined and *MAY* be determined by the impelmentation)
    * An array of specific values, this defines the closed vocabulary
    * A map of key/value pairs (object in JSON's nomenclature), indicating that this is a nested type
    * ``@idref`` - A reference to another annotation
    * ``@idrefs`` - A list of references to another annotation
    * ``@vocab`` - A URL or list of URLs referring to another vocabulary. This implies nesting: the value for this key is  a map of key/value pairs who adhere to a different vocabulary.
    * ``@url`` - A URL
    * ``@urllist`` - A URL list
    * ``@uri`` - A URI or IRI
    * ``@urilist`` - A URI or IRI list
    * ``@str`` - A string
    * ``@strs`` - A string list
    * ``@int`` - An integer
    * ``@ints`` - An integer list
    * ``@float`` - A floating point number
    * ``@floats`` - A floating point list
    * ``@date`` - A date
    * ``@datelist`` - A date list
    * ``@datetime`` - A date-time combination
    * ``@datetimelist`` - A datetime list
    * Any other value is a fixed static value that will be assigned, if the key does not exist in this case, it will be created.
* ``constraints`` - Extra **vocabulary constraints** on the data type, specified as list of key/value pairs:
    * ``minvalue`` - mininum numeric value (inclusive)
    * ``maxvalue`` - maximum numeric value (inclusive)
    * ``default`` - a default value in case this element is not specified
    * ``allowunknown`` - Allow out of vocabulary items even when a closed vocabulary is specified (default: false)
    * ``required`` - boolean indicating whether this field is required (default: false)
    * ``conflicts`` - A list of keys which *MUST NOT* not be used at the same time as this key, to match against
        higher/deeper levels, use path syntax like ``../`` , ``key/childkey``.
    * ``requires`` - A list of keys which *MUST* be used at the same time as this key
    * ``minlength`` - Minimum length of the list (for all the ``@list`` datatypes).
    * ``maxlength`` - Maximum length of the list (for all the ``@list`` datatypes).

### Query

The STAM data model also defines a query data object that can be used to query an annotation set. A query typically returns
zero or more annotations that match against the criteria you provided.

This object is either simply a **Filter** object, or an ordered list of **Filter** objects. When multiple filters are applied in succession on the output of the previous filter (like a pipe).

### Filter

Attributes, all of them are optional, but at least one *MUST* be specified:

* ``id``: A filter on the ID. (You can use the operators we explain in the next item)
* ``body``: A filter on the annotation body. A map of keys and values, in which they keys match against the keys in the body of potential
    annotations; or the key is an operator:
    * ``@and`` - Value is a list
    * ``@or`` - Value is a list
    When matching keys, the value can be another object with an
    *operator* as key. We distinguish the following operators:
    * ``@equals`` - Exact match (you usually don't need this operator as it is the default if you just specify a
        key/value pair).
    * ``@not_equals``  - Does not match
    * ``@contains``  - is part of the list
    * ``@not_contains``  - is not part of the list
    * ``@greater_than`` - Value is a number
    * ``@less_than`` - Value is a number
    * ``@greater_equal_than`` - Value is a number
    * ``@less_equal_than`` - Value is a number
    You may also use the following special values to simply check whether a key exists or not:
    * ``@undefined`` - The key is not present in the annotation
    * ``@defined`` - The key is present in the annotation.
* ``type``: A selector on the type. Uses the same operators as above.
* ``begin``: Begin offset (optional). Uses the same operators as above.
* ``end``: End offset (optional). Uses the same operators as above.
* Rather than the above attributes, the operators ``@and`` and ``@or`` may also be used at this level.


An example using JSON should explain things better:

```json
{
    "body": {
        "confidence": { "@greater_than": 0.5 },
        "@and": {
            "colour": "red",
            "flower": "rose",
            "length": "@defined"
        }
    }
}
```


### Constraint Set

The Constraint Set, aka the model type, is a fairly high-order definition that lays contraints on how various types/vocabularies can be
used together. It is the third and highest-level abstraction in STAM, and is *NOT REQUIRED*. This concept should not be
confused with the **vocabulary constraints** that can be expressed at the vocabulary level.

Say you have an annotation type for "word" (a proper URL pointing to a vocabulary). One characteristic of words is
normally that they can't overlap. This constraint can not be captured in the vocabulary definition as this is a relation between types (i.e. between a
word and another word, it doesn't matter that the two types are identical). The model type specification, however, is designed to such define constraints.

Another example, if you have an annotation type "Sentence" and an annotation type "Word", you can define that a sentence
should contain at least one word. Or that a word may have only one Part-of-Speech tag, or that two Named Entities may
never overlap, etc...

Attributes:

* ``constraints`` - Ordered list of **Constraints**

### Constraints

Attributes:

* ``subject`` - A **Query** that selects the subject of the constraint.
* ``require`` - List of all the requirements for this subject. See next item
* ``forbid`` - List of all the prohibitions for this subject. Each requirement/prohibition is an object with the
    following keys. The value is another query that selects the object.
    * ``exists`` - True when both subject and object exist (e.g. there are match annotations for both)
    * ``sametext`` - True when both subject and object cover the exact same text
    * ``overlaps`` - True when there is overlap between subject and object in the text
    * ``preceeds`` - True when the subject comes before the object in the text (there are no annotations in between)
    * ``succeeds`` - True when the subject comes after the object in the text (there are no annotations in between)
    * ``contains`` - True when the subject contains the object (the offset of the object is entirely contained within
    * the subject)
    * ``contains_once`` - True when there is only one
    * ``contains_multiple`` - True when there are more than one


Consider the following JSON serialisation as example, this states that a sentence must contain at least one word and
that a sentence can't be part of another sentence.

```json
{
    "subject": {
        "type": "https://example.org/sentence.vocab.json"
    },
    "require": [{
        "contains": {
            "type": "https://example.org/word.vocab.json"
        }
    }],
    "forbid": {
        "contains": {
            "type": "https://example.org/sentence.vocab.json"
        }
    }
}
```

It is *RECOMMENDED* to many requirements and prohibitions as much as possible under one subject.
Implementations *MAY* be more performant then. Note that there is no guarantee on the order of evaluations. All
requirements and prohibitions *MUST* be satisfied for the constraint as a whole to pass validation.

Consider another example that also matches on the annotation body, here we demand that all words have a part of speech
tag with a confidence value of 0.5 or higher:

```json
{
    "subject": {
        "type": "https://example.org/word.vocab.json"
    },
    "require": [{
        "contains": {
            "type": "https://example.org/partofspeech-brown.vocab.json",
            "body": {
                "confidence": { "@greater_equal_than": 0.5 }
            }
        }
    }]
}
```


## Serialisation and file structure

The data model should be serializable to, and parsable from, formats like JSON, YAML and even XML.  We take JSON to be the
canonical serialisation and exchange format as it is simple and a wide variety of parsers is already available.

Both annotation sets and vocabulary sets are serialisable/parseable. We *RECOMMEND* the following file structure and
extensions:

- ``*.annotations.json`` for annotation sets
- ``*.vocabulary.json`` for vocabulary sets
- ``*.constraints.json`` for type constraint sets

Due to the strict stand-off nature, the text content is always a separate file, referred to as ``target`` from the annotation set.


## Implementation

A STAM implementation can comply to one, two or all three levels of complexity/abstract/formality, depending on the need
of the application.

