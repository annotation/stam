# Simple Stand-off Text Annotation Model

## Introduction

STAM is a data model for **simple stand-off text annotation**. The underlying
premise is that any information on a text is represented as an *annotation*. We
define an annotation as any kind of remark, classification/tagging on any
particular portion(s) of a text, on to the resource as a whole, in which case
they can be interpreted as *metadata*. Additionally, rather than reference the
text directly, annotations may point to other annotations (higher-order
annotation). Examples of annotation may be linguistic
annotation, structure/layout annotation, editorial annotation, technical
annotation, or whatever comes to mind. Our model does not define any
vocabularies whatsoever.

The underlying resource is taken in its most bare form without further
information; e.g. plain text (a sequence of unicode points). *Any* additional
information would be considered an annotation in our model. Interpreting and
supporting particular formats/encodings is up to the implementations and opaque
to the data model.

STAM does not depend on other more complex data models such as RDF, Web
Annotations, TEI, FoLiA or whatever, but instead addresses the problem from a
more functional and pragmatic perspective. We separate pragmatics from
semantics and define a kind of lowest common denominator upon which further solution can be built.
The user is free, and in fact encouraged, to use vocabularies that are formalised elsewhere.

STAM is primarily intended as a model for data representation, and less so as a format for data interchange.
It is designed in such as way that an efficient implementation (both speed & memory) is feasible. The form of such an
implementation either in a relational database, triple store, directly modelled in memory, is left open to the implementation.
Our model should also be reducible to a more generalised acyclic directed graph model without much difficulty.

Goals/characteristics of STAM are:

* *Simplicity* - the data model must be easy to understand for a
user/developer and use and only contain what is needed, not more. We provide a **minimal** foundation upon which other 
projects can build more complex solutions. These are deliberately kept out of STAM itself.

* *Separation from semantics* - The data model does not commit to any vocabulary or annotation paradigm. It must be
flexible enough to express whatever annotation paradigm a researcher wants to
use, yet provide the facilities to be specific enough for practical purposes.
The model basically allows for any kind of directed or undirected graph.

* *Standalone* - No dependency on other data models (e.g. RDF) aside from Unicode, no dependency on any software services.

* *Practical* - Rather than provide a theoretical framework, we primarily aim to provide a practical specification and actual low-level tooling you can get to work with right away.

* *Performant* - The data model is set up in such a way that it allows for efficient/performant implementations, with regard to processing requirements but especially memory consumption. The model should be suitable for big data (millions of annotations). 

* *Import & Export* - Reads/writes a simple JSON format. But also designed with export to more complex formats in mind (such as W3C Web Annotations / RDF) and imports from common formats such as CONLL. Note that although STAM puts no constraints on annotation paradigms and vocabularies, higher data models may.


The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Data Model

In this section, we will describe the STAM data model, note that the data model is detached from any specific
serialisation format.

The below UML-like diagram expresses the data model.

![UML diagram](model.png)

Some notes to interpret the diagram:

*  A circled C stands for a Class (items listed are properties that must all be satisfied).
*  A circled A stands for a Abstract class (items listed are properties that must all be satisfied).
*  A circled E stands for an Enumeration (items listed are options in the enumeration)
   *  Enumerations may be parametrised (this could be expanded to an abstract class and concrete classes).
* Dashed edges follow private properties for the recommended memory-model
* Green edges denote a subclass relationship (for the various Selectors)
* The ampersand prefix (``&``) represent a reference/pointer and is merely a *RECOMMENDED* hint for a memory model for implementations.
* The ``?`` suffix represents optional properties. 
*  ``[]`` represents a list/vector/array.
    *  The ``*`` suffix inside a list represents zero or more items of the preceding type
    *  The ``+`` suffix inside a list represents one or more items of the preceding type
* Properties starting with an underscore are *NOT REQUIRED* but *RECOMMENDED* for implementation to facilitate quick lookups, they suggest a memory model.

### Identifiers

Many of the items carry two identifiers. The first is a *private identifier*, an internal numeric identifier (starting
with an underscore) which serves for particular implementations but should not be used outside of the context of a
particular implementation.

The second main identifier is an actual *public identifier* intended to be persistent and usable for data exchange, this
is an arbitrary string and is *OPTIONAL*.

Both identifiers, by definition, *MUST* be unique.

The following overriding constraints apply only for compatibility RDF:

*  The public identifier *MUST* be an [IRI](https://datatracker.ietf.org/doc/html/rfc3987)
*  There *MUST* be a public identifier for each **Annotation**

### Class: Annotation Set

An Annotation Set is a collection of annotations. There is no intrinsic meaning in them being grouped together.  The
actual data of the annotation is also held by the AnnotationSet if the *RECOMMENDED* memory-model is followed. When serialising all annotations in the data model to
file, it usually takes place at this level.

### Class: Annotation

This represents a particular instance of annotation and is the central concept of the model. The instance of annotation
is decoupled from the *data* or value/label of the annotation (``AnnotationData``). After all, multiple instances can be annotated with the same
label (multiple annotations may share the same annotationdata). Moreover, an Annotation can have multiple annotation data associated.

Each annotation *MUST* have a single ``target``. The target is selected using a ``Selector``. It identifies the target and the part of
the target that the annotation applies to.  There are multiple types of selectors:

* ``TextSelector`` - Selects a target resource and a text span within it. The text span *MAY* be noncontiguous. The span
    is specified through one or more offset pairs consisting of a ``begin`` and ``end``.
  These ``begin`` and ``end`` attributes *MUST* describe the character position in NFC-normalised unicode
  points, in text of the resources that is being pointed at. Indexing *MUST* be zero-based and the end offset *MUST* be
  non-inclusive.
* ``ResourceSelector``  - A selector point to a resource as whole. These type of annotation can be interpreted as *metadata*.
* ``AnnotationSelector``  - A selector pointing to one or more other annotations (enables higher-order annotation). If the annotation that is being targeted eventually refers to a text (`TextSelector`), then offsets **MAY** be specified that select a subpart of this text. These offsets are now *relative* to the annotation (starting at 0, negative values allowed, end non-inclusive).
* ``MultiSelector``  - A selector that consists of multiple other selectors, used to select more complex targets that transcend the idea of a single simple selection. This *MUST* be interpreted as the annotation applying equally to the conjunction as a whole, its parts being inter-dependent and for any of them it goes that they *MUST NOT* be omitted for the annotation to makes sense. Note that the order of the selectors is not significant. When there is no dependency relation between the selectors, you *MUST* simply use multiple `Annotation`s instead.
* ``DirectedSelector``  - Another selector that consists of multiple other selectors, but with an explicit direction (from -> to), used to select more complex targets that transcend the idea of a single simple selection.

As said, the actual contents/value/body of the annotation (e.g. the tag/label/comment) is stored in a separate
``AnnotationData`` instance. This is done so multiple annotations with the exact same content require less storage
space, and to facilitate search.  We make no distinction between data and metadata here. Let's look into this:

### Class: AnnotationData

This stores the actual content of an annotation. It is decoupled from the actual ``Annotation`` instances so multiple
instances can point to the same content.

Annotations data consists of a single key/value pair. The ``key`` *MAY* for instance denote the
annotation type (none are predefined). Using a ``key`` is *RECOMMENDED* but *NOT REQUIRED* (it *MAY* be empty). 
A ``key`` *MUST* be globally unique. It is encapsulated in a separate ``DataKey`` type for performance reasons.

For a given AnnotationData instance, Key uniqueness is also *RECOMMENDED* but *NOT REQUIRED*, i.e. there *MAY* be multiple annotations on the same data with
identical keys.

The ``value`` property is a ``DataValue`` instance that holds the
actual value along with its data type. Additionally, a ``vocabulary`` property may refer to a ``Vocabulary`` that
defines what values are allowed.

The ``_referenced_by`` attribute of ``AnnotationData`` links back to all annotations that
instantiate this exact same content, this is effectively a reverse index to facilitate search. It is *OPTIONAL*.

### Class: DataKey

This ``DataKey`` class encapsulates data keys for AnnotationData. It has an
``id`` property, which identifies the key and  *MUST* be globally unique. The
reason for this separate class is only to enable performant implementation with
a minimal memory footprint; allowing the full key ID to be stored in memory only once.

The following overriding constraints apply only for compatibility with RDF:

*  The public identifier *MUST* be an [IRI](https://datatracker.ietf.org/doc/html/rfc3987) identifying a property.

### Enum: DataValue

This ``DataValue`` class encapsulates data values along with their data types, as well as some collection types.
It can be set to one of the following:

* ``Id(v: str)`` - A public identifier (when used with RDF, this *MUST* be an IRI)
* ``String(v: str)``- String
* ``Int(v: int)`` - Integer number
* ``Float(v: float)`` - Fractional number
* ``Datetime(v: datetime)`` - A date/time representation, compatible with ``xsd:datetime``.
* The following are recursive-types:
    * ``List(v: [DataValue])`` - A list of multiple ``DataValue`` instances

Note that there is no ``Map`` type to associate further key, value pairs. If
you want to express nested relations, you *MUST* use `Annotation`s on
`Annotation`s (i.e. using `AnnotationSelector`).

## Serialisation Formats

### JSON

A simple JSON serialisation will be formulated analogous to the in-memory
representation. This will be the primary format for parsing and serialisation.
Private properties (those starting with an underscore) *SHOULD NOT* be
serialised (but recomputed at parsing). Implementations *MUST* assign arbitrary
identifiers where missing if and only if the instances are references from
elsewhere.

### JSON-LD / Turtle / RDF

Though STAM explicitly does not depend on RDF; when some extra constraints are
adhered to (that have been indicated throughout this specification), a STAM
model can be expressed in RDF terms. This opens up connectivity with the linked
open data world.  

### W3C Web Annotations

Conversion to the W3C Web Annotation model is up to specific tooling and
requires adherence to the same constraints as RDF.

### Binary

Optimized binary serialisations are conceivable. These are parsed and
serialised considerably quicker than any other and are the *RECOMMENDED* solution in
situations where quick reading/writing from/to disk is important. However, such
serialisations *SHOULD* be consider implementation-specific and *MUST NOT*
serve as interchange or archiving formats.

## Relation to other data models

In this section I'll draw some parallels with other data models. Rather than draw on existing data models, especially
those in the realm of Linked Open Data, I have opted to not adopt any of those. The reason is that I wanted a simpler and more
pragmatic stand-alone solution that has the right amount of expressivity that is precisely tailored to the task of stand-off
annotation, *and not much more*.

My arguments for this are:

* I don't want to burden the user with having to learn many different and often highly complex models as a
  prerequisite to understanding the actual one they are interested in.
* I don't want implementations to have to rely on huge (and not always mature) 3rd party dependencies for such
  data models. A STAM implementation should be realistic with one main code base, needing only some well-established libraries like a
  generic JSON/YAML parser/serialiser, but requiring no further infrastructure.
* Existing standards like Web Annotations (in turn making use of JSON-LD and RDF) contain features that go beyond
  what is needed for simple stand-off annotation, and are similarly still lacking certain features we need for full
  coverage.
* Existing models like RDF, Web Annotations tend to be very verbose and have more overhead, making performant
  processing more complicated. Though RDF is something we explicitly target as an export option, it is not a dependency.

STAM is more like a lowest common denominator, a pivot model if you will, that allows expression of a wide variety of
annotation paradigms. Exports of this simpler data model to more expressive and established standards like RDF and
WebAnnotations are encouraged whereever appropriate.

Comparisons can also be drawn with more specific-purpose text annotation formats or such as TEI, FoLiA (disclaimer: I'm also the author
of FoLiA), TCF, and NAF, all of which are XML-based formats which offer very specific annotation types. In STAM, all of those
would be user-defined, so the aim is to reformulate some of these data models (notably FoLiA) in terms of STAM.

(TODO: Text Fabric, LAF, Salt.)

## Functions



## Implementations

This specification does not define how the data model should be implemented in software. We refer to the following implementations:

* None exists yet


