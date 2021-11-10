# STand-off Annotation Model

## Introduction

STAM is a data model for **stand-off annotation**. The underlying premise is that any information on a text/audio/video
is represented as an *annotation*. We define an annotation as any kind of remark, classification/tagging on any
particular portion(s) of a text/audio/video, or to the resource as a whole, in which case they can be interpreted as *metadata*.
Examples of annotation may be linguistic annotation, structure/layout annotation, editorial annotation, technical annotation,
or whatever comes to mind. Our model does not define any vocabularies, but does define a mechanism to validate data
against custom vocabularies.

The underlying resource is taken its most bare form without further information; e.g. plain text (a sequence of unicode
points), an audio/video stream or an image canvas (a matrix of pixels). Any additional information would be considered
an annotation in our model. Interpreting and supporting particular formats/encodings is up to the implementations and
opaque to the data model.

We aim for a *simple* model; the data model must be easy to understand for a user/developer and use only define what is needed, not
more. We allow ourselves certain abstractions and shortcuts to this end. This model does not rely on any more complex
undelrying data formalism such as RDF, nor more specific annotaiton models such as Web Annotations, TEI, FoLiA, or
whatever. We approach the model from a more functional and pragmatic perspective and define a certain lowest common
demoninator that may serve to express more specific models.

STAM is primarily intended as a model for data representation, and less so as a model for data interchange.
It is designed in such as way that an efficient implementation (both speed & memory) is feasible. The form of such an
implementation either in a relational database,  directly modelled in memory, is left open to the implementation.
Our model should also be reducible to a more generalised acyclic directed graph model without much difficulty.

Goals/Features:

 * Stand-off annotation on plain text
 * A fairly Simple model
 * No commitment to any annotation paradigm aside from stand-off annotation, the model basically allows for any kind of directed or
   undirected graph.
 * Interoperability without dependency:
    * Self-sustained; STAM does not rely on other data models (e.g. RDF) that introduce additional complexity.
    * Exportable to webannotations (subject to some constraints)
    * Import from webannotations (within various constraints)
 * Separation from semantics: the data model does not commit to any vocabulary or annotation paradigm.
 * Semantics: the data model allows expressing (simple) semantics and checking compliance against user-defined
   vocabularies.
 * Validation: The ability to validate annotations of the data and basic correctness is one of the core goals of the
     model: Users (and systems) make mistakes, correctness of the data has to be ensured.

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
*  The ampersand (``&``) represent a reference/pointer. The details of the implementation are not prescribed though.
*  ``Option<>`` represents optional properties. ``Map<>`` represents a key/value map/dictionary.
*  ``[]`` represents a list/vector/array.
*  Properties starting with an underscore are *NOT REQUIRED* but *RECOMMENDED* in implementation to facilitate quick
    lookups.

### Identifiers

Many of the items carry two identifiers. The first is a *private identifier*, an internal numeric identifier (starting
with an underscore) which serves for particular implementations but should not be used outside of the context of a
particular implementation.

The second main identifier is an actual *public identifier* intended to be persistent and usable for data exchange, this
is an arbitrary string and is *OPTIONAL*.

Both identifiers, by definition, *MUST* be unique.

The following overriding constraints apply only for compatibility with Web Annotations:

*  The public identifier *MUST* be an [IRI](https://datatracker.ietf.org/doc/html/rfc3987)
*  There *MUST* be a public identifier for each **Annotation**

### Class: Annotation Set

An Annotation Set is a collection of annotations. There is no intrinsic meaning in them being grouped together.  The
actual data of the annotation is also held by the AnnotationSet. When serialising all annotations in the data model to
file, it usually takes place at this level.

### Class: Annotation

This represents a particular instance of annotation and is the central concept of the model. The instance of annotation
is decoupled from the *data* or value/label of the annotation (``AnnotationData``). After all, multiple instances may be annotated with the same
label.

Each annotation *MUST* have at least one ``target``, multiple targets are possible. The target points to that which is
annotated. The target is selected using a ``Selector``. It identifies the target and the part of
the target that the annotation applies to.  There are multiple types of selectors:

* ``TextSelector`` - Selects a target resource and a text span within it. The text span *MAY* be noncontiguous. The span
    is specified through one or more offset pairs consisting of a ``begin`` and ``end``.
  These ``begin`` and ``end`` attributes *MUST* describe the character position in NFC-normalised unicode
  points, in text of the resources that is being pointed at. Indexing *MUST* be zero-based and the end offset *MUST* be
  non-inclusive.
* ``ResourceSelector``  - A selector point to a resource as whole. These type of annotation can be interpreted as *metadata*.
* ``AnnotationSelector``  - A selector pointing to one or more other annotations (enables higher-order annotation).

An annotation *MAY* have multiple targets, this *MUST* be interpreted as the annotation as a whole applying equally to
each of the targets individually. It would be functionally equivalent to having multiple annotations with the same data,
each with one of the targets.

In contrast, if the annotation has a selector that references multiple spans/resources/annotations, then this *MUST* be
interpreted as the annotation applying to the conjunction as a whole. (Note for Web Annotation compatibility: Web
Annotation can not express this, multiple selectors there means something different)

In addition to the ``target`` attribute, there may also be a ``source`` attribute. If both source and target are set,
the annotation is expressing a *relation* between the two selectors; in a graph sense it can be considered a label on a
directed edge, whereas only having a target can be interpreted as a node label.

As said, the actual contents/value/body of the annotation (e.g. the tag/label/comment) is stored in a separate
``AnnotationData`` instance. This is done so multiple annotations with the exact same content require less storage
space, and to facilitate search.  We make no distinction between data and metadata here. Let's look into this:

### Class: AnnotationData

This stores the actual content of an annotation. It is decoupled from the actual ``Annotation`` instances so multiple
instances can point to the same content.

Annotations data consists of a single key/value pair. The ``key`` *MAY* for instance denote the
annotation type (none are predefined). The key can be assigned to a ``namespace`` to make explicit what vocabulary the
key is drawn from, and prevent clashes with possibly identical keys. Using a ``key`` is *RECOMMENDED* but *NOT REQUIRED*.  Key
uniqueness also *RECOMENDED* but *NOT REQUIRED*, i.e. there *MAY* be multiple annotations on the same data with
identical keys.

The ``value`` property is a ``DataValue`` instance that holds the
actual value along with its data type. Additionally, a ``vocabulary`` property may refer to a ``Vocabulary`` that
defines what values are allowed.

The *OPTIONAL* ``_referenced_by`` attribute of ``AnnotationData`` links to all annotations that
instantiate this exact same content, this is effectively a reverse index to facilitate search.

For compatibility with Web Annotations, the use of the following *keys* is *RECOMMENDED* with the namespace
``http://www.w3.org/ns/anno.jsonld``. See the [web annotation
model](https://www.w3.org/TR/annotation-model/#other-properties) for further details, such as the cardinality for each
of these metadata items.

* ``body`` - The body of the annotation (encapsulated the actual value in the Web Annotation model)
* ``creator`` - The data value represents the agent responsible for creating the resource. This may be either a human, an organization or a software agent.
* ``created`` - The time at which the resource was created.
* ``generator`` - The agent responsible for generating the serialization of the Annotation.
* ``generated`` - The time at which the Annotation serialization was generated. The
* ``modified`` - The time at which the resource was modified, after creation.
* ``audience`` - The intended audience for the annotation
* ``accessibility`` - The accessibility of the annotation
* ``motivation`` - The reason why the annotation was created
* ``rights`` - The license for the annotation


### Enum: DataValue

This ``DataValue`` class encapsulates data valus along with their data types, as well as some collection types.
It can be set to one of the following:

* ``Id(v: str)`` - A public identifier (when used with Web Annotations, this *MUST* be an IRI)
* ``String(v: str)``
* ``Int(v: int)``
* ``Float(v: float)``
* ``Datetime(v: datetime)`` - A datetime representation, compatible with ``xsd:datetime``.
* ``Annotation(annotation: &Annotation)`` - A reference to another annotation
* The following are recursive-types:
    * ``Map(v: Map<DataKey,DataValue>)`` - A key, value map; this enables arbitrarily nested key/value pairs. The values are ``DataValue`` instances,
        the keys are arbitrary strings.
    * ``List(v: [DataValue])`` - A list of multiple ``DataValue`` instances

### Class: Vocabulary

The vocabulary class expresses a set of possible value ``options`` along with human-readable labels. Options is
expressed as a list of ``(value: DataValue, label: Option<str>)`` pairs. The labels are *OPTIONAL*.  It can be used
either for data values in an annotation, or for the data keys themselves. In the latter case, we speak of the vocabulary
as a namespace.

A vocabulary has a property ``open`` (boolean) that determines whether any ad-hoc values are allowed, the available
options then merely act as suggestions. If the vocabulary is closed, however, a value *MUST* be chosen that is in the
vocabulary options.

The vocabulary has an associated ``datatype``, and is most typically used with strings. However, it can also be used
with numerical values. In such cases the ``min_value`` and ``max_value`` property can be used instead of ``options``, to
constrain the vocabulary to a numerical range.

## Serialisation

At the moment, no canonical serialisation is defined yet. A simple JSON serialisation will be formulated shortly.

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
  generic JSON/YAML parser, but requiring no further infrastructure.
* Existing standards like Web Annotations (in turn making use of JSON-LD and RDF) contain features that go beyond
  what is needed for simple stand-off annotation, and are similarly still lacking certain features we need for full
  coverage.
* Existing standards like RDF, Web Annotations tend to be very verbose and have more overhead, making performant
  processing more complicated.

STAM is more like a lowest common denominator, a pivot model if you will, that allows expression of a wide variety of
annotation paradigms. Exports of this simpler data model to more expressive and established standards like RDF and
WebAnnotations are encouraged whereever appropriate.

Web annotations are probably the closest to STAM when it comes to annotations, and an excellent export option. Web
annotations themselves offer more expressivity (e.g. all the different selectors and target types they support) than we
need for our purposes. On the other hand, Web Annotations themselves do not cover certain areas that we do cover with
STAM, such as the expression of vocabulary, constraints and focus of the validation. Being Linked Data, such options
are of course available for Web Annotations and RDF too, but you quickly need to turn to full-blown OWL ontologies to accomplish
that. This I consider a dependency with considerable overhead and a steep learning curve.

Comparisons can also be drawn with more specific-purpose text annotation formats or such as TEI, FoLiA (disclaimer: I'm also the author
of FoLiA), TCF, and NAF, all of which are XML-based formats which offer very specific annotation types. In STAM, all of those
would be user-defined, so the aim is to reformulate some of these data models (notably FoLiA) in terms of STAM.

(TODO: Text Fabric, LAF, Salt.)


## Implementations

This specification does not define how the data model should be implemented in software. We refer to the following implementations:

* None exists yet

