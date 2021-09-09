# Simple Text Annotation Model

## Introduction

STAM is a simple data model for text annotation and comes with a library and a
set of tools to work with the data model.

Goals:

 * Simple and minimal, no unnecessary abstractions/complexity.
 * Stand-off annotations on plain text
 * Full separation of annotation syntax from annotation semantics (vocabularies)
 * Provides a foundation upon which more complex solutions can be created (using the vocabularies).
 * Correctness, allow validation of data against schemas/vocabularies
 * JSON/YAML/XML serialisations
 * No hard-coded vocabularies
 * Exportable to Web Annotations
 * Performant tooling, no unnecessary overhead

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Data Model

In this section, we will describe the STAM data model, detached from any specific
serialisation format.

### Annotation Set

Attributes:

* ``target`` - The URL of the resource that is annotated, treated as plain text
* ``checksum`` - sha256 checksum of the target file
* ``annotations`` -  List of ``Annotation`` objects.

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
* ``group_id`` - Id for the annotation that may be shared between multiple annotations, all of which are required for full interpretation.
* ``text`` - Text value of the pointed text (optional, for validation purposes)
* ``vocab`` -  URL to the vocabulary used in the body (or in-line definition)
* ``body`` - The body of the annotation, a scalar value or a key/value map (optional)
* ``describes`` - This annotation describes another annotation, rather than the text itself. This can be used instead of the ``begin``, ``end`` attributes and represents *higher-order annotations*. (optional)

The ``begin`` and ``end`` attributes, when provided, *MUST* describe the character position in NFC-normalised unicode points, in reference to the ``target`` of the annotation set. Indexing *MUST* be zero-based the end offset *must* be non-inclusive.
The ``begin`` and ``end`` attributes *MAY* be omitted when the annotation covers the target file as a whole and is less strictly related to any text span. In this case it *should* be interpreted as metadata.

The ``text`` attribute is *OPTIONAL* but *RECOMMENDED*. When used, its value *MUST* be a
copy of the exact same text string as the ``begin`` and ``end`` attributes point to. This is
merely an extra reduncancy level to ensure correctness and aid interpetability.
It is used in validation and tools *SHOULD* be able to automatically derive it
if not explicitly supplied.

The ``id`` attribute is *OPTIONAL* but *RECOMMENDED*. An identifier uniquely
identifies an annotation. The value it is given is an arbitrary identifier (a
string) which must be unique for the entire annotation set, it is *RECOMMENDED*
for it be even globally unique even over multiple annotation sets. No further
contraints are set on the format of identifiers for STAM, but different
serialisations/export options *MAY* posit additional constraints.

The ``body`` attribute provides the body of the annotation, i.e. the actual
values associated with the annotation.  The ``body`` attribute *MAY* be omitted
entirely if there is no need to associate any values with the annotation. If a
body value is provided, it can be either a simple primitive such a a
string/integer/float or boolean, or an actual key/value map. The latter allows
you to associate multiple values with the annotation and to relate the values
to a vocabulary. A vocabulary *MAY* be provided in the ``vocab`` attribute, and
if provided, all keys and values in the body *MUST* comply to the vocabulary.
Providing a vocabulary is *RECOMMENDED* for validation purposes.  If no
vocabulary is provided, the key/value map of body *MAY* contain anything and is
completely unchecked.

The ``vocab`` attribute, if provided, *MUST* point to a URL describing a **vocabulary set**.

It is possible that an annotation can not be interpreted by itself but relies on other annotations
for a full interpretation. Such annotations *SHOULD* be represented by setting the ``group_id`` to an identifier that
is shared between multiple annotations and which effectively groups them together. All parts of the group
*MUST* be considered for a full interpretation of the annotation and all *MUST* be part of the same annotation set.

The ``describes`` attribute designates that this annotation describes another
(one or more) annotations, rather than the text itself. It *SHOULD* be
interpreted as having no direct bearing on the text, but only on the
annotation(s) it points to.  This attribute can be used instead of the
``begin``/``end`` attributes and effectively allows expression of *higher-order
annotations*. This feature *should* be used sparingly and the following methods
are *RECOMMENDED* over this one:

1. Use a ``body`` with a key/value map, allowing you to specify multiple values directly
   and foregoing the need for an extra annotation.
2. Use ``group_id`` to group multiple annotations that must be interpreted together.

### Vocabulary Set

Attributes:

* ``base`` - A list of zero or more other vocabulary sets to import (URLs), this offers some modularity
* ``terms`` - An unordered list of **vocabulary terms**

### Vocabulary Item

**Vocabulary**:
    * ``key`` - An identifier, the string *MUST* be unique at the level which it is specified. The key *MUST NOT* contain any slashes.
    * ``type`` - The datatype of this key (all types start with ``@``)
        * An array of specific values, this defines the closed vocabulary
        * A map, indicating that this is a nested type
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
    * ``constraints`` - Extra constraints on the data type, specified as list of key/value pairs:
        * ``minvalue`` - mininum numeric value (inclusive)
        * ``maxvalue`` - maximum numeric value (inclusive)
        * ``default`` - a default value in case this element is not specified
        * ``allowunknown`` - Allow out of vocabulary items even when a closed vocabulary is specified (default: false)
        * ``required`` - boolean indicating whether this field is required (default: false)
        * ``conflicts`` - A list of keys which *MUST NOT* not be used at the same time as this key, to match against
            higher/deeper levels, use path syntax like ``../`` , ``key/childkey``.
        * ``requires`` - A list of keys which *MUST* be used at the same time as this key
        * ``maxlength`` - Maximum length of the list (for all the ``@list`` datatypes).

## Serialisation

The data model should be serializable to, and parsable from, formats like JSON, YAML and XML.  We take JSON to be the
canonical serialisation and exchange format as it is simple and a wide variety of parsers is already available.

Both annotation sets and vocabulary sets are serialisable/parseable. Users *MAY* use extensions such as
``.annotations.json`` and ``.vocabulary.json`` for respectively an annotation set and a vocabulary set. Due to the
strict stand-off nature, the text content is always a separate file, referred to as ``target`` from the annotation set.



## Implementation

Library implementations *SHOULD* provide the following functions:

* Querying
    * Low-level:
        * Retrieve annotations by ID
        * Retrieve annotations by Group ID
        * Retrieve annotations by position ranges
        * Retrieve annotations by matching on the body
    * Given an annotation, retrieve contained annotations
    * Given an annotation, retrieve annotations it is contained in
* Validation: Check if annotation bodies correspond to the vocabularies
* Parsing:
    * from STAM JSON
* Serialisation:
    * to STAM JSON

