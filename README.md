<p align="center">
    <img src="https://github.com/annotation/stam/raw/master/logo.png" alt="stam logo" width="320" />
</p>

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

# STAM: Stand-off Text Annotation Model

## Introduction

STAM is a data model for **stand-off text annotation**. The underlying premise
is that any information on a text is represented as an *annotation*. We define
an annotation as any kind of remark, classification/tagging on any particular
portion(s) of a text, or on the resource or annotation set as a whole, in which
case we can interpret annotations as *metadata*. Additionally, rather than
referencing the text directly, annotations may point to other annotations
(higher-order annotations). Examples of annotation may be linguistic annotation,
structure/layout annotation, editorial annotation, technical annotation, or
whatever comes to mind. Our model does not define any vocabularies whatsoever.

The underlying resource is taken in its most bare form without further
information; e.g. plain text (an ordered sequence of unicode points). *Any*
additional information would be considered an annotation in our model.
Interpreting and supporting particular formats/encodings is up to the
implementations and opaque to the data model.

STAM does not depend on other more complex data models such as RDF, W3C Web
Annotations, TEI, FoLiA or whatever, but instead addresses the problem from a
more functional and pragmatic perspective. We separate pragmatics from
semantics and define a kind of lowest common denominator upon which further
solutions can be built. The user is free, and in fact encouraged, to use
vocabularies that are formalised elsewhere.

STAM is primarily intended as a model for data representation, and less so as a
format for data interchange. It is designed in such a way that an efficient
implementation (both speed & memory) is feasible. The form of such an
implementation either in a relational database, triple store, or directly modelled
in memory, is left open to the implementation. Our model should also be
reducible to a more generalised acyclic directed graph model without much
difficulty.

Goals/characteristics of STAM are:

* *Simplicity* - the data model must be easy to understand for a user/developer
  to use and only contain what is needed, not more. We provide a **minimal**
  foundation upon which other projects can build more complex solutions. These
  are deliberately kept out of STAM itself. The notion that *everything is an
  annotation* is at the core of STAM and one of the things that keeps it
  simple.

* *Separation from semantics* - The data model does not commit to any
  vocabulary or annotation paradigm. It must be flexible enough to express
  whatever annotation paradigm a researcher wants to use, yet provide the
  facilities to be specific enough for practical purposes. The model basically
  allows for any kind of directed or undirected graph.

* *Standalone* - No dependency on other data models (e.g. RDF) aside from
  Unicode and JSON for serialisation, no dependency on any software services.

* *Practical* - Rather than provide a theoretical framework, we primarily aim
  to provide a practical specification and actual low-level tooling you can get
  to work with right away.

* *Performant* - The data model is set up in such a way that it allows for
  efficient/performant implementations, with regard to processing requirements
  but especially memory consumption. The model should be suitable for big data
  (millions of annotations). We sit at a point where we deem to have an optimal
  trade-off between simplicity, flexibility and performance.

* *Import & Export* - Reads/writes a simple JSON format. But also designed with
  export to more complex formats in mind (such as W3C Web Annotations / RDF)
  and imports from common formats such as CONLL. Note that although STAM puts
  no constraints on annotation paradigms and vocabularies, higher data models
  may.

The name STAM, an acronym for *"Stand-off Text Annotation Model"*, is Dutch,
Swedish, Afrikaans and Frisian for *"trunk"* (as in the trunk of a tree), the
name itself depicts a solid foundation upon which more elaborate solutions can be built.

Large parts of this specification are normative:

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

## Extensions

We keep STAM simple and define only the bare minimum. Other functionality is
included in extensions. Extensions do one or more of the following: they extend
the data model, specify new serialisations, specify mappings/crosswalks to other
paradigms/formats, specify additional functionality.

The following are currently defined:

* [STAM-Vocab](extensions/stam-vocab) -  Allows expressing and validating against user-defined vocabularies.
* [STAM-Webannotations](extensions/stam-webannotations) - Models W3C Web Annotations using STAM and vice versa.
* [STAM-Textvalidation](extensions/stam-textvalidation) - Adds an extra redundancy layer that helps protecting data integrity and aids readability of serialisations 
* [STAM-CSV](extensions/stam-csv) - Defines an alternative serialisation format using CSV.
* [STAM-Baseoffset](extensions/stam-baseoffset) - allows splitting large monolithic text resources into multiple smaller text resources, whilst still retaining the ability the reference offsets as if they refer to the original/monolithic resource.

Implementations *SHOULD* explicitly state which extensions they support.

## Implementations

This specification does not define precisely how the data model should be
implemented in software, although the data model is designed in such a way as
to facilitate an efficient implementation. We refer to the following
implementations:

* [stam-rust](https://github.com/annotation/stam-rust) - A STAM library written in Rust, aims to be a *full STAM implementation* with high performance and *memory-based* storage model.
* [stam-python](https://github.com/annotation/stam-python) - A STAM Library for Python. This is not an independent implementation but it is a Python binding to the above Rust library.

Please read the [Functionality](#Functionality) section further down to see a
specification of requirements for implementations.

## Core Data Model

In this section, we will describe the STAM data model, note that the data model is detached from any specific
serialisation format, those will be discussed in a later section.

The below UML diagram expresses the core data model.

![UML diagram](coremodel.png)

Some notes to interpret the diagram:

*  A circled C stands for a Class (items listed are properties that must all be satisfied).
*  A circled A stands for a Abstract class (items listed are properties that must all be satisfied).
*  A circled E stands for an Enumeration (items listed are options in the enumeration)
   *  Enumerations may be parametrised (this could be written more verbosely as an abstract class (A) and concrete classes (C), and vice versa).
* Green edges denote a subclass relationship (for the various Selectors)
* Red edges point to references in the recommended memory model, black edges indicate ownership. Please ignore it on a first reading.
* The ampersand prefix (``&``) represent a reference/pointer and is merely a *RECOMMENDED* hint for a memory model for implementations.
* The ``?`` suffix represents optional properties. 
*  ``[]`` represents a collection (a list/vector/array/set, specifics are left to the implementation)
    *  The ``*`` suffix inside a list represents zero or more items of the preceding type
    *  The ``+`` suffix inside a list represents one or more items of the preceding type
    *  The ``++`` suffix inside a list represents two or more items of the preceding type

### Identifiers

Many of the items carry two identifiers. The first is an actual *public identifier* intended to be persistent and usable for data exchange, this
is an arbitrary string and is *OPTIONAL*.

The second is a *private identifier*, an internal numeric identifier which serves for particular implementations but should not be used outside of the context of a
particular implementation. We refer to this one as `_id`, starting with an underscore to indicate it's internal. It is part of the *extended model* rather than the *core model*.

Both identifiers, by definition, *MUST* be unique, though the private identifiers need only be unique within a certain local implementation context.

The following overriding constraints apply only for compatibility with RDF:

*  The public identifier *MUST* be an [IRI](https://datatracker.ietf.org/doc/html/rfc3987)
*  Each public identifier *MUST* be globally unique 
*  There *MUST* be a public identifier for each **Annotation**

### Offsets

Offsets are always in unicode codepoints (not byte offsets, though internally
implementations *MAY* convert from/to utf-8 byte offsets), the coordinate
system is zero-indexed and the end offset is non-inclusive.  An offset consists of two components:

1. `begin` - An cursor pointing to the begin of the selection
2. `end` - A cursor pointing to the end of the selection (non-inclusive)

The coordinate system is determined by whatever that the selector points at:
this can either be a `TextResource` via `ResourceSelector`, in which case we
are dealing with absolute coordinates in a text, or it can be an `Annotation`
via `AnnotationSelector` in which case we are dealing with relative coordinates
with respect to the target of the annotation.

The `begin` and `end` offsets are expressed via a `Cursor`, for either
component the cursor can be either begin-aligned or end-aligned. This is best
explained through an example on the string *"Hallå världen"* (Hello world in
swedish):

* ``BeginAlignedCursor(0), BeginAlignedCursor(1)`` - *"H"*
* ``BeginAlignedCursor(4), BeginAlignedCursor(5)`` - *"å"*
* ``BeginAlignedCursor(0), BeginAlignedCursor(5)`` - *"Hallå"*
* ``BeginAlignedCursor(0), BeginAlignedCursor(13)`` - *"Hallå världen"*
* ``BeginAlignedCursor(0), EndAlignedCursor(0)`` - *"Hallå världen"*
* ``BeginAlignedCursor(7), EndAlignedCursor(-2)`` - *"värld"*
* ``EndAlignedCursor(-7), EndAlignedCursor(0)`` -*"världen"*

Also take note of the following constraints:

* The `begin` and `end` offset *MAY* reference the very same point, in which case the length of the selection is ``0`` and the whole selector *SHOULD BE* interpreted as a single pointer/cursor rather than a selection of text.
* The `end` offset *MUST NOT* reference a point before the `begin` offset.
* The `begin` offset *MUST NOT* reference a point before the beginning of the resource's text.
* The `end` offset *MUST NOT* reference a point after the end of the resource's text, with the sole exception of first codepoint after the text's end (considering the end is always non-inclusive).

### Example A

Example A below shows an annotation example using this model, it shows a
textual resource with a small Swedish text *"Hallå världen"* with three annotations (shown in yellow).

![Example A (overview)](examples/example_a_overview.svg)

None of the vocabulary (keys/values) in the annotations is predefined by STAM.

After working this out in the STAM annotation model, we obtain the schema
below. Note that two annotations share the same data, illustrating how the
model leads to more memory efficiency.

![Example A](examples/example_a.png)

### Class: Annotation Store

An Annotation Store is an unordered collection of annotations, resources and
annotation data sets. It can be seen as the *root* of the *graph model* and the glue
that holds everything together.

Implementations themselves decide how to implement this (in memory, on disk,
database backed, etc). Being the class that holds the entire graph, this
typically means that implementations only have a single Annotation Store,
multiple annotations and resources can be loaded into it and *SHOULD* be
distinguished from eachother by other means (e.g. by the resource they are
referencing or any higher-order annotations that group things together).

### Class: TextResource

This holds the textual resource to be annotated. The text *SHOULD* be in
[Unicode Normalization Form C (NFC)](https://www.unicode.org/reports/tr15/) but
*MAY* be in another unicode normalization forms.

### Class: Annotation Data Set

An *Annotation Data Set* stores the keys (`DataKey`) and values
(`AnnotationData`) that are used by annotations. It effectively defines a
certain vocabulary, i.e. key/value pairs. How broad or narrow the scope of the
vocabulary is not defined by STAM but entirely up to the user. 

The `AnnotationDataSet` does not store the `Annotation`s themselves, those are in
the `AnnotationStore`.

An `AnnotationDataSet` *MUST* have a public identifier.

### Class: Annotation

This represents a particular *instance of annotation* and is the central
concept of the model. They can be considered the primary nodes of the graph model. The
instance of annotation is strictly decoupled from the *data* or key/value of the
annotation (``AnnotationData``). After all, multiple instances can be annotated
with the same label (multiple annotations may share the same annotation data).
Moreover, an Annotation can have multiple annotation data associated. The result is that multiple annotations with the exact same content require less storage
space, and searching and indexing is facilitated.  

Through the `data` property, multiple instances of `AnnotationData` *MAY* be
associated with an `Annotation`, when this is the case, a strong dependency
relation between the data *MUST* be assumed in the interpretation. Like
`AnnotationData` itself, the data is also assumed to be complete and immutable;
you *SHOULD NOT* add data to existing annotations at a later point. If these
conditions are not fulfilled, you *SHOULD* use multiple `Annotation`s instead,
including possibly an `Annotation` on the original `Annotation` (i.e. a
higher-order annotation via `AnnotationSelector`).

The `data` property and the `AnnotationData` instances can for example be used to express things like (non-normative!):

* The actual *value* of the annotation (what is the actual annotation's content?). For instance:
    * linguistic information such as a Part-of-Speech tag (noun, verb), a lemma, etc...
    * a textual correction (e.g. mississippi where the text had mississipi)
    * some remark or opinion on the content (e.g. "I like this part!")
* The *type* of the annotation (what kind of annotation is it? Like one of the above mentioned categories)
    * No need to have a type, you can also choose for key/value pairs that imply a type (like *pos*, *correction*, *remark*).
* The *purpose* of the annotation (why was it made?)
* The *creator* of the annotation (who made the annotation?)
* The *time* at which the annotation was made (when was it made?)

The italicized part in the above list would correspond to the keys. *None of
this vocabulary is predefined by STAM though!* It is the user-defined
`AnnotationDataSet` that determines the vocabulary used and you can use whatever
annotation paradigm you deem fit. 

Each annotation instance *MUST* have a single ``target``. The target is
selected using a ``Selector``. Annotation is a broad concept in STAM and almost
everything is an annotation, it explicitly includes metadata and not just annotations that
reference a text segment; the type of selector determines the nature of the annotation.

### Class: Selector

A `Selector` identifies the target of an annotation and the part of the
target that the annotation applies to. Selectors can be considered the labelled edges of the graph model, tying all nodes together.
There are multiple types of selectors:

* ``TextSelector`` - Selects a target resource and a text span within it. The text-span *MUST*  be contiguous and is is specified through an offset pairs consisting of a ``begin`` and ``end``.
  These ``begin`` and ``end`` attributes *MUST* describe the character position in unicode
  points in text of the resources that is being pointed at. Indexing *MUST* be zero-based and the end offset *MUST* be
  non-inclusive. Non-contiguous spans are expressed via multiple `TextSelector`s under a `CompositeSelector`.
* ``ResourceSelector``  - A selector pointing to a resource as whole. These type
  of annotation can be interpreted as *metadata*.
* ``DataSetSelector``  - A selector pointing to an annotation data set (`AnnotationDataSet`). These type
  of annotation can be interpreted as *metadata*.
* ``AnnotationSelector``  - A selector pointing to another annotation. This we call higher-order annotation and is very common in STAM models. If the annotation that is being targeted eventually refers to a text (`TextSelector`), then offsets **MAY** be specified that select a subpart of this text. These offsets are now *relative* to the annotation. Internally, the implementation can always efficiently resolve these to absolute offsets on the resource. The use of `AnnotationSelector` has one important constraint: the graph of all annotations referring to other annotations  *MUST* be acyclic; i.e. it can't end up in a recursive loop of annotations referencing each-other. Implementations *SHOULD* check this.
* ``MultiSelector``  - A selector that consists of multiple other selectors (subselectors) to select multiple targets. This *MUST* be interpreted as the annotation applying to each target *individually*, without any relation between the different targets. Leaving one out or adding one *MUST NOT* affect the interpretation of any of the others nor of the whole. This is a way to express multiple annotations 
as one, a more condensed representation. Do note that in STAM, even if you don't use a `MultiSelector` but use multiple annotations, you still benefit from the fact that these multiple annotations may share the same `AnnotationData`, and can therefore easily retrieve all annotations that share particular data. The order of the selectors is not significant, implementations *MAY* re-order at will and are *RECOMMENDED* to return results in textual order where applicable.
* ``CompositeSelector``  - A selector that consists of multiple other selectors (subselectors), these are used to select more complex targets that transcend the idea of a single simple selection. This *MUST* be interpreted as the annotation applying equally to the conjunction as a whole, its parts being inter-dependent and for any of them it goes that they *MUST NOT* be omitted for the annotation to make sense. The interpretation of the whole relies on all its parts. The order of the selectors *SHOULD* adhere to textual order if applicable (implementation *MAY* re-order to enforce this). For selectors not referring to text, the order is not significant (use a `DirectionalSelector` instead if you want a custom order). When there is no dependency relation between the selectors, you *MUST* simply use multiple `Annotation`s or a `MultiSelector` instead. When grouping things into a set, do use a `CompositeSelector`, as the set as a whole is considered a composite entity.
* ``DirectionalSelector``  - Another selector that consists of multiple other
  selectors, but with an explicit direction (from -> to), used to select more
  complex targets that transcend the idea of a single simple selection. The ordering (and interpretation thereof) is strictly user-determined and implementations *MUST* adhere to this.

The so-called complex selectors (`MultiSelector`, `CompositeSelector` and
`DirectionalSelector`) *MUST NOT* be nested, you *MUST* use one or more of the
simple selectors (`TextSelector`,`ResourceSelector`,
`DataSetSelector`,`AnnotationSelector`)  as subselector (or the internal
`RangedInternalSelector` which will be described later on as part of the
extended model).

### Class: AnnotationData

This class holds the actual content of an annotation; a key/value pair. (the
term *feature* is regularly seen for this in certain annotation paradigms).
Annotation Data is deliberately decoupled from the actual ``Annotation``
instances so multiple annotation instances can point to the same content
without causing any overhead in storage. Moreover, it facilitates indexing and
searching. The annotation data is part of an `AnnotationDataSet`, which
effectively defines a certain user-defined vocabulary.

Annotation data consists of a single key/value pair that *SHOULD* be immutable
(i.e. it shouldn't change after being set, just delete it and add another if
need be). A ``key`` *MUST* be unique *within* a dataset (and when using RDF it 
must be globally unique over all identifiers). The key is encapsulated in a separate ``DataKey`` type for
performance reasons, these too are held by the `AnnotationDataSet`.

An `Annotation` instance *MAY* reference multiple `AnnotationData` with the same `key` but different values.

The ``value`` property is a ``DataValue`` instance that holds the
actual value along with its data type. For a given key, value combination, there *SHOULD* be only 
one matching ``AnnotationData`` in a given set. There *MAY* be multiple only if given different explicit public identifiers, but this is *NOT RECOMMENDED*.

*Extended model:* The ``_referenced_by`` attribute of ``AnnotationData`` links back to all
annotations that instantiate this exact same content, this is effectively a
reverse index to facilitate search. It is *RECOMMENDED* for implementations to
do efficient querying. Read the section on reverse indices later on.

### Class: DataKey

This ``DataKey`` class encapsulates data keys for `AnnotationData`. It has an
``id`` property, which is the actual key, *MUST* be provided and  *MUST* be unique *within* the set. The
reason for this separate class is only to enable performant implementation with
a minimal memory footprint; allowing the full key ID to be stored in memory only once instead of for
each instance it is used.

It is *RECOMMENDED* for implementations to support an additional boolean
property `indexed`, which indicates whether implementations should or should
not compute an index for this key.

The following overriding constraints apply only for compatibility with RDF:

*  The public identifier *MUST* be an [IRI](https://datatracker.ietf.org/doc/html/rfc3987) identifying a property.
*  Each public identifier *MUST* be globally unique.

### Enum: DataValue

This ``DataValue`` class encapsulates data values along with their data types, as well as some collection types.
It can be set to one of the following:

* ``Null()`` - No value
* ``Id(value: str)`` - A public identifier (when used with RDF, this *MUST* be an IRI). This *SHOULD NOT* be used to refer to annotations in the STAM model.
* ``String(value: str)``- String
* ``Int(value: int)`` - Integer number
* ``Bool(value: bool)`` - Boolean
* ``Float(value: float)`` - Fractional number
* ``Datetime(value: datetime)`` - A date/time representation, compatible with ``xsd:datetime``.
* The following are recursive collection types:
    * ``List(value: [DataValue])`` - An ordered list of multiple ``DataValue`` instances

Note that there is no ``Map`` type to associate further nested key/value pairs. If
you want to express nested relations, you *MUST* use `Annotation`s on
`Annotation`s (i.e. using `AnnotationSelector`).

## Extended Data Model

The classes in this next section are all part of the *extended data model* and are auxiliary
structures used by implementations to delivered specific functionality rather
than the core structure to model the actual data. These are taken
as *RECOMMENDED* but *NOT REQUIRED*. They are typically not part of any
serialisation. 

In the UML diagram, they are drawn in blue. Implementations *MAY*
deviate from these and implement things in another matter. Although STAM does prescribe
what functionality must be implemented (see the [functionality](#Functionality)
section), it leaves flexibility to implementations to determine how that should be accomplished.

The below UML diagram expresses the extended data model, it includes and builds upon all of the core model:

![UML diagram - STAM Extended Data Model](model.png)

Some notes to interpret the diagram, as it may quickly become overwhelming:

*  A circled C stands for a Class (items listed are properties that must all be satisfied).
*  A circled A stands for a Abstract class (items listed are properties that must all be satisfied).
*  A circled E stands for an Enumeration (items listed are options in the enumeration)
   *  Enumerations may be parametrised (this could be written more verbosely as an abstract class (A) and concrete classes (C), and vice versa).
* Blue classes/enumerations are *dependency relations* part of the extended model, and provide *RECOMMENDATIONS* for implementations in order to provide certain functionality. Please ignore it on a first reading.
* Dashed edges follow private/*RECOMMENDED* properties for the recommended memory-model or come from classes in the extended model. Please ignore it on a first reading.
* Green edges denote a subclass relationship (for the various Selectors)
* Red edges point to references in the recommended memory model, black edges indicate ownership. Please ignore it on a first reading.
* Blue edges denote a functional relationship (used with).  Please ignore it on a first reading.
* The ampersand prefix (``&``) represent a reference/pointer and is merely a *RECOMMENDED* hint for a memory model for implementations.
* The ``?`` suffix represents optional properties. 
*  ``[]`` represents a collection (a list/vector/array/set, specifics are left to the implementation)
    *  The ``*`` suffix inside a list represents zero or more items of the preceding type
    *  The ``+`` suffix inside a list represents one or more items of the preceding type
    *  The ``++`` suffix inside a list represents two or more items of the preceding type
* Properties starting with an underscore are *NOT REQUIRED* but *RECOMMENDED* for implementation to facilitate quick lookups, they suggest a memory model. Implementations could implement them as private properties.

### Class: TextSelection

A `TextSelection` is a precisely defined slice of the text of a given `TextResource`.
It typically refers to the exact absolute offsets of a text. This structure *SHOULD* be produced
as the result of a selection (e.g. by an annotation via a `TextSelector`) and *SHOULD*
be added to a reverse index to facilitate search. A `TextSelection` *MUST NOT* be serialized to file.


Instances of `TextSelection` make up the (reverse) for a `TextResource`. The job of the reverse index, is to link
text offsets back to annotations. Usage of the reverse
index and this  `TextSelection` class is a *RECOMMENDATION*, implementations
*MAY* decide to implement this differently.

To facilitate search, implementations are *RECOMMENDED* to keep all
`TextSelection`s in the reverse index in sorted order, where the order is based
on the offsets. We do not prescribe how to implement this, but a boundary index
that independently tracks begin offsets and end offsets would function best.

### Enum: TextSelectionOperator

This operator expresses a binary relation between two text selections (`A TextSelectionOperator B`, in which `A` and `B` are both a `TextSelection`). The way we define
this and other operators in the extended STAM model, is more like currying, as
the right part is included, effectively turning a binary operator into a unary
one. This follows a certain implementation logic, but implementations *MAY*
choose to implement this differently.

We distinguish the following variants for this operator, they are to be considered *RECOMMENDED*:

* `Equals(B)` - A equals B, both text selections reference the exact same offset (i.e. same begin, same end).
* `Before(B, mindistance: int? , maxdistance: int?)` - A comes before B entirely, there is no overlap (alternative name: *ends before*)
    * The `mindistance`, when set, defines a minimum distance in unicode points (default = 0)
    * The `maxdistance`, when set, defines a maximum distance in unicode points (default, unset = infinite)
* `After(B, mindistance: int?, maxdistance: int?)` - A comes after B entirely, there is no overlap.
* `Overlaps(B)` - A overlaps with B.
* `Embeds(B)` - A embeds or contains B. This may sometimes be interpreted as a parent-child relationship. Consider for instance A being a sentence and B a word in that sentence. Also note that `A Equals(B)` entails `A Embeds(B)` (but not the other way round).
* `Precedes(B, spacing: bool?, punct: bool?)` - A comes right before B, it ends just when B begins
    * The `spacing` parameter, when set to true, allows whitespace between the offsets and still considers the text selection sets adjacent
    * The `punct` parameter, when set to true, allows punctuation between the offsets and still considers the text selection sets adjacent
* `Succeeds(B, spacing: bool?, punct: bool?)` - A comes right after B< it begins just when A ends
* `SameBegin(B)` - A and B have the same begin cursor.
* `SameEnd(B)` - A and B have the same end cursor.

We also introduce some logical operators which take other operator(s) (`P`) as parameters:

* `Not(P)` - Inverts any operator
* `And([P++])` - Logical conjunction. All operators must pass
* `Or((P++]` - Logical disjunction. One of the operators must pass.

There is already some redundancy in operators as some are the inverse of one or more others. The following even add more redundancy but *MAY* also be implemented as convenient shortcuts:

* `Near(B, mindistance: int?, maxdistance: int?) ` - A `Precedes` B or A `Succeeds` B, there is no overlap
* `SameRange(B)` - Combination of `SameBegin` and `SameEnd`.
* `Embedded(B)` - B embeds A (inverse of `Embeds`)

Rather than operate on individual text selections, implementations *MAY* operate on entire *sets* of text selections instead, but this is left to an extension.

### Enum: DataOperator

This binary operator is used on `DataValue` instances (i.e. the value of an `AnnotationData` instance)
to test the value.  Consider `A DataOperator B`, where `A` is often the data in the model,
and `B` some value the user wants to test for. The operator *MUST* evaluate to
a boolean. It can also be used `AnnotationData` and even on `Annotation`, in this last case it is simply
applied to all `AnnotationData` instances in data. It *MUST* then returns true
if *any* of the data matches, except if `Not` is used, then *all* *MUST* match.

We discern the following variants, they are to be considered *RECOMMENDED*:

 * `Equals(other: DataValue)` - Test whether two values are equal
 * `GreaterThan(other: DataValue)`
 * `LessThan(other: DataValue)`
 * `GreaterThanOrEqual(other: DataValue)`
 * `LessThanOrEqual(other: DataValue)`
 * `HasElement(other: DataValue)` - Applies only when applied to annotation data with `DataValue::List()` , tests if the element is in the list.
 * `And([DataOperator++])` - Conjunction combining multiple tests
 * `Or([DataOperator++])` - Disjunction combining multiple tests
 * `Not(DataOperator)` - Unary operator that inverts the logic.


### Class: RangedInternalSelector

This selector is used internally as subselector under one of the so-called complex selectors (i.e. `MultiSelector`, `DirectionalSelector`, `CompositeSelector`). It point to two targets via two selectors, a begin target and an end target. Both selectors under this selector *MUST* be of the exact same type and *MUST* be a `TextSelector`, `ResourceSelector`, `AnnotationSelector` or `DataSetSelector`, complex selectors are not allowed.

The begin selector and end selector effectively mark *a range over internal identifiers*. It has to be noted that this *MUST NOT* be interpreted as a range in text ordering, it is merely a range over an arbitrary internal memory layout and carries no inherent meaning. The only function of this selector is to safe memory. Say you have a MultiSelector pointing to 100,000 targets, i.e. via 100,000 subselectors. If those targets are consecutive with respect to their internal identifier, then a single `RangerInternalSelector` suffices as subselector.

It is not expressed in canonical serialisation.  Implementations can choose to implement this selector differently as they see fit. Implementations *SHOULD* automatically create `RangedInternalSelector`s when parsing data, if possible.

There are situations in which a `RangedInternalSelector` can not be used. For a begin/end `TextSelector` (pointing to a `TextSelection`) it only works if offset information is already in the `TextSelection`, which is the case if and only if `BeginAlignedCursor`s are used. An `AnnotationSelector`may also carry offset information, but these are relative offsets and can therefore not be compacted to a `RangedInternalSelector`. 

### Reverse indices

The extended model defines various relations like `_referenced_by` and
`_part_of` that point *back* (hence the term 'reverse') at items from which
nodes are referenced. In the schema these are represented by red dashed lines,
whereas the solid red lines can be interpreted as the *forward* index.  All of
these combined (including 'forward' solid black lines indicating ownership)
constitute the edges of a search graph and enables quick lookups.

It may help to enumerate the reverse indices in a more stand-off fashion as follows:

* An index mapping annotations to all annotations that select it:  `Annotation -> [Annotation]`
    * This would be the reverse index for annotations that use `AnnotationSelector`
* An index mapping textselections (pertaining to a resource) to all annotations :  `TextResource -> [TextSelection -> [Annotation]]`
    * This would be the reverse index for annotations that use `TextSelector`
    * It is *RECOMMENDED* to store TextSelections in some kind of ordered map, whereas all the other items in this section need only an unordered map.
* An index mapping annotation data (pertaining to a set) to all annotations that use that data:   `AnnotationDataSet [AnnotationData -> [Annotation]]`
* An index mapping resources to all annotations that select that resource:   `TextResource -> [Annotation]`
    * This *MAY* be limited annotations that point at the resource as a whole. This would then be the reverse index for annotations that use `ResourceSelector`.
* An index mapping annotation data sets to all annotations select the set:   `AnnotationDataSet -> [Annotation]` 
    * This *MAY* be limited annotations that point at the dataset as a whole. This would then be the reverse index for annotations that use `DataSetSelector`.
* An index mapping datakeys (pertaining to an annotationset) to annotationdata that makes use of the key
* An index mapping annotation data sets to all annotations select the set:   `AnnotationDataSet -> [DataKey -> [AnnotationData]]` 

Implementations *SHOULD* implement these or similar indices, facilitating quick lookup in search. 

## Searching

The ability to search or query the data is essential functionality that a STAM
implementation needs to offer. The *extended data model* described above offers
the basic building blocks needed to implement efficient low-level search
functions. This specification does not prescribe an API for these low-level
functions, that is left up entirely to the implementation.

The formulation of a higher-level query language is not part of the core specification
either, it is instead left to an extension.

## Serialisation Formats

### STAM JSON

The canonical JSON serialisation (STAM JSON) is the primary format for parsing
and serialisation. It follows the model to the letter, and *completeness* and
*explicitness* is the main aim of the serialisation. It is not intended to be
concise, minimal or even easily readable. JSON is chosen as it is an ubiquitous
a widely-accepted format for which many implementations are available. The
serialisation *MUST* adhere exactly to the property names introduced in this
document (case sensitive). 

* Private properties (those starting with an underscore) *SHOULD NOT* be serialised (those can be recomputed at parsing). 
* All STAM classes serialised as JSON objects *MUST* carry a ``@type`` attribute that denotes the STAM class as laid out in this specification. This helps readability prevents errors at the cost of some slight redundancy. Parser implementations *SHOULD* use this property to validate the data structure.
* All public IDs are serialised through the ``@id`` attribute.

For a complete serialisation, you *SHOULD* start with `AnnotationStore`, which is the root level. 

In Example A1, shown below, we see the serialisation of the Example A that was shown before, 


```json
{
    "@type": "AnnotationStore",
    "@id": "Example A",
    "resources":  [{
        "@type": "TextResource",
        "@id": "hello.txt",
        "text": "Hallå världen"
    }],
    "annotationsets": [{
        "@type": "AnnotationDataSet",
        "@id": "exampleset",
        "keys": [
            {
                "@type": "DataKey",
                "@id": "type"
            },
            {
                "@type": "DataKey",
                "@id": "function"
            }
        ],
        "data": [
            {
                "@id": "WordType",
                "@type": "AnnotationData",
                "key": "type",
                "value": {
                    "@type": "String",
                    "value": "word"
                }
            },
            {
                "@id": "GreetingFunction",
                "@type": "AnnotationData",
                "key": "function",
                "value": {
                    "@type": "String",
                    "value": "greeting"
                }
            }
        ],
    }],
    "annotations": [{
            "@type": "Annotation",
            "data": [{
                "@type": "AnnotationData",
                "@id": "WordType",
                "set": "exampleset",
            }],
            "target": {
                "@type": "TextSelector",
                "resource": "hello.txt",
                "offset": {
                    "begin": {
                        "@type": "BeginAlignedCursor",
                        "value": 0 
                    },
                    "end":  {
                        "@type": "BeginAlignedCursor",
                        "value": 5 
                    },
                },
            }
        },
        {
            "@type": "Annotation",
            "data": ["WordType"],
            "target": {
                "@type": "TextSelector",
                "resource": "hello.txt",
                "offset": {
                    "begin": {
                        "@type": "BeginAlignedCursor",
                        "value": 6 
                    },
                    "end":  {
                        "@type": "BeginAlignedCursor",
                        "value": 13
                    },
                },
            }
        },
        {
            "@type": "Annotation",
            "data": ["WordType"],
            "target": {
                "@type": "TextSelector",
                "resource": "hello.txt",
                "offset": {
                    "begin": {
                        "@type": "BeginAlignedCursor",
                        "value": 0 
                    },
                    "end":  {
                        "@type": "EndAlignedCursor",
                        "value": 0 
                    },
                },
            }
        },
    ]
}
```

Serialisation relies on the availability of public identifiers. When identifiers are
not assigned by the user, implementations *MUST* assign arbitrary identifiers if and only
if the instances are referenced from elsewhere.

Fields that are references (denoted by the & and red edges in the UML schema
shown earlier), simply take the public identifier as value. However, you *MAY*
also specify the target in-line as if it were not a reference. This provides
some extra flexibility and can help readability. Parser implementations *MUST*
support this. Consider an excerpt of the first annotation, functionally
identical to before, but `data` and `key` have now been specified in-line:

```json
{
    "@type": "Annotation",
    "data": [
        {
            "@id": "WordType",
            "@type": "AnnotationData",
            "set": "my-example",
            "key": {
                "@type": "DataKey",
                "@id": "type",
            },
            "value": {
                "@type": "String",
                "value": "word"
            }
        },
    ],
    "target": {
        ...
    }
}
```

There are two important points to notice for in-line use:

1. It is *RECOMMENDED* to add an additional `set` property to the `AnnotationData` to
   specify what Annotation Data Set is to be used to store the annotation data
   and the keys. Implementations *SHOULD* create the set on-the-fly as part of the `AnnotationStore`.
   If the `set` property is missing, implementations *SHOULD* 
   just create a single `AnnotationDataSet` and reuse it for all 'orphaned' inline annotation data.
   In the pictured schemas, this property is named `_part_of_set`.
2. Inline data leads to redundancy/unnecessary duplication, it *SHOULD* only be
   used in cases where a reference is not needed. However, parser
   implementations *MUST* accept redundancy if and only if there are no
   collisions (a thing with the same ID described differently than before), if
   there are collisions, implementations *MUST* produce an error.

Serialisation implementations *MAY* reproduce inline annotations as read during parsing, but this is
*NOT REQUIRED*. It is in fact much easier not to do so.

#### Multiple files and the @include statement

Rather than have one big json file with the entire annotation store and all it
references, serialisations *SHOULD* be split over multiple files, it is
*RECOMMENDED* to have separate files for each annotation set and it is *RECOMMENDED* to keep the
text resources in external files. Annotation instances *MAY* also be split over
one or more external files. References to files are made by using the special key
``@include``, consider the Example A2 where the annotation store references
external files.


```json
{
    "@type": "AnnotationStore",
    "@id": "Example A",
    "resources":  [{
        "@type": "TextResource",
        "@include": "hello.txt"
    }],
    "annotationsets": [{
        "@type": "AnnotationDataSet",
        "@include": "my.annotationset.json"
    }],
    "annotations": [{
        ...
    }]
}
```

These ``@include`` statements *MUST* be `json` files *except* when used inside
`resources`; in that case plain-text files *SHOULD* be used and plain-text
*MUST* be assumed if the filename does not carry a ``json`` extension. All
included files (json or plain text) *MUST* be encoded as UTF-8. 

If plain text files are included, this translates to a `TextResource` with the
filename as ID. The filenames for `@include` adhere to the following constraints:

* Relative filenames in `@include` statements are interpreted as
  the implementation sees fit, usually relative to the current working directory
  or some document root directory. 
* Absolute filenames (stating with a slash) *MUST* be absolute on the
  filesystem but *MAY* be rejected by implementations (for example on security grounds).
* URLs *MAY* be used, but implementations are *NOT REQUIRED* to
  implement networking logic and *MAY* reject this (it again has security
  implications). Implementations *SHOULD* make clear whether they support
  fetching remote URLs or not. 
* At the same level of the `@include`, an `@id` field is allowed to set or *override*
  the inferred public identifier. If not set, the public `@id` equals the `@filename` exactly as specified.o
* Consistent with earlier rules, at the same level of the `@include`, there *MUST* be a `@type` field.

An example of the latter is shown below:


```json
{
    "@type": "AnnotationStore",
    "@id": "Example A",
    "resources":  [{
        "@type": "TextResource",
        "@id": "https://somewhere.over.the.rainbow/hello.txt",
        "@include": "hello.txt"
    }],
    "annotationsets": [{
        "@type": "AnnotationDataSet",
        "@id": "https://somewhere.over.the.rainbow/myannotationset",
        "@include": "my.annotationset.json"
    }],
    "annotations": [{
        ...
    }]
}
```

The ``@include`` statements can only be used  at the level of the
`AnnotationStore` for `resources` or `annotationsets`. It *MUST NOT* be used in
other place. Annotations themselves *MUST NOT* not be split from the
AnnotationStore using separate `@include` statements, as they by definition
require the context of both resources and annotation sets and can not stand on
their own. They only make sense within an AnnotationStore context.

How to deal with annotations across multiple files then? It may be desirable
not to keep all annotations in one basket, but have multiple. You *MAY* simply
define multiple annotation stores in multiple STAM JSON files. Implementations
*SHOULD* be able to load multiple annotation stores, although internally they
*MAY* likely keep only a single one and effectively merge everything. When data
is in conflict, e.g. annotation store A defines a text with id X and annotation
store B defines the same text with ID X *but with a different text* content,
then an error *SHOULD* be raised.

For resources, annotation datasets, as well as the merging of multiple
annotation stores, implementations *SHOULD* implement the necessary bookkeeping
logic in their parsers to serialize to the same separate stand-off files as
were parsed. Implementations *SHOULD* also serialize in the same order as items
were parsed, this is for reproducibility purposes, even though order is not
significant. STAM, however, does not prescribe how either of these should be
done.

When parser implementations encounter any JSON keys in the STAM JSON that are
not defined in this specification, they *SHOULD* issue a warning to the user
and proceed parsing, ignoring the particular key. Specifications *MUST NOT*
produce a hard failure when encountering unknown keys, as these may be keys
defined by STAM extensions.

**Note:** Some readers will notice that the use of ``@type`` and ``@id`` are
similar to their usage in JSON-LD. It has to be noted though that the default
STAM JSON serialisation is not proper JSON-LD. However, if certain constraints are
met it can be easily made to be valid JSON-LD, see the next section:

### JSON-LD / Turtle / RDF

Though STAM explicitly does not depend on RDF; when some extra constraints are
adhered to (that have been indicated throughout this specification), a STAM
model can be expressed in RDF terms. This opens up connectivity with the linked
open data world. Implementations that export to RDF *MUST* check whether the
constraints for RDF export are adhered too, and *MUST NOT* blindly assume so.

An RDF model and JSON-LD context will be formulated for STAM. Including this
JSON-LD `@context` in the STAM JSON files (assuming constraints are adhered
too) will then make it JSON-LD and therefore RDF. 

### W3C Web Annotations

Some STAM models can be expressed as W3C Web Annotations, and vice versa: some Web Annotation models can be expressed as STAM.
In any case, all of the RDF constraints have to be satisfied. But that may not be enough, there are
certain things in STAM that are not easily expressed in web annotations  (or not as concisely).
The reverse also holds, there are things in web annotations that can not be expressed in STAM.

Conversion from/to the W3C Web Annotation model is not part of the STAM itself
but is to be formulated in a separate extension.

### Binary

JSON is verbose and parsing and serialisation is fairly slow. Optimized binary
serialisations for STAM are conceivable. These are parsed and serialised considerably
quicker than any other and are the *RECOMMENDED* solution in situations where
quick reading/writing from/to disk is important. However, such serialisations
*SHOULD* be considered implementation-specific and *MUST NOT* serve as
interchange or archiving formats.

### STAM CSV

Though STAM is a simple minimalistic model, the JSON serialisation still has a
verbosity and complexity that makes it hard to work with for the less-technical
researcher or for larger datasets.

A CSV format is proposed that can represent all of STAM. It is considered a separate extension so its implementation is *OPTIONAL*.
See [STAM CSV](extensions/stam-csv/).

## Examples

Please consult [our examples](examples/) for various examples of STAM. This
will greatly aid in understanding the model and assessing its potential. These examples
*MAY* also be used by implementations for test and validation purposes.

## Functionality

This sections specifies, at a high-level, what functionality a core STAM
implementation offers. A core STAM implementation is a software library or
service offering some sort of API (which we will refer to as *interface* below). The precise nature of the API is not
prescribed and up to the implementation:

A core STAM implementation adheres to the following requirements:

* *MUST* model all the classes of the core specification.
    * This entails that it *MUST* model `AnnotationStore`, `Annotation`, `AnnotationData`, `AnnotationDataSet`, `DataKey`, `DataValue`. 
    * This entails that it *MUST* support all the selectors (`Selector`)
    * This entails that it *MUST* support offsets (`Offset`) and cursors (`Cursor`) as prescribed
    * Implementations are *NOT REQUIRED* to follow an objected-oriented programming paradigm and may model all of these as they see fit.
 * *MUST* support public identifiers
    * They *MUST* also support the absence of such identifiers when parsing input and *SHOULD* allow generating IDs automatically when needed (for serialisation).
* *MUST* offer an interface to manipulate annotations:
    * *MUST* offer an interface to add new annotations with new annotation data and data keys
    * *MUST* offer an interface to add new keys and annotation data to annotation sets
    * *MUST* offer an interface to remove annotations, annotation data, data keys
    * Annotations, once made, *SHOULD* be considered immutable. Implementations needn't offer an interface to edit existing annotations. It is instead *RECOMMENDED* to delete the old one (if need be) and make a new one. (see more in next section on model constraints).
* *MUST* offer an interface to search and retrieve annotations:
    * *MUST* offer an interface to retrieve all annotations
    * *MUST* offer an interface to retrieve all annotations with data that uses a specific key (`DataKey`).
    * *MUST* offer an interface to retrieve all annotations that carry the given data (`AnnotationData`) (entails and extends the previous point).
        * *SHOULD* support most or all of the comparison tests as expressed by `DataOperator`
    * *MUST* offer an interface to retrieve all annotations that point to a given annotation
    * *MUST* offer an interface to retrieve all annotations that are pointed at by a given annotation
    * *MUST* offer an interface to retrieve all annotations that point to a given text selection (in a given resource)
    * *MUST* offer an interface to retrieve all annotation data sets
    * *MUST* offer an interface to retrieve all resources
    * *MUST* offer an interface to retrieve all annotation data in an annotation data set
    * *MUST* offer an interface to retrieve all data keys in an annotation data set
* *MUST* offer an interface to retrieve the target text for any annotation
    * *MUST* offer an interface to retrieve all text selections a given annotation references
* *MUST* offer an interface to retrieve any arbitrary queried text ranges (even if there are no annotations)
* *MUST* offer an interface to test/compute relationships with regard to text selections:
    * *SHOULD* support most or all of the textual relations as expressed by `TextSelectionOperator`
* *MUST* offer an interface to test/compute relationships in higher-order annotations:
    * *MUST* offer an interface that tests whether an annotation A points to another annotation B (A parent of B)
    * *MUST* offer an interface that tests whether an annotation A is pointed at by another annotation B (A child of B)
    * *MUST* offer an interface that tests whether an annotation A points to another annotation B indirectly (A ancestor of B)
    * *MUST* offer an interface that tests whether an annotation A is pointed at by another annotation B  (A descendant of B)
    * *MUST* offer an interface that tests the common ancestor of two or more annotations (if any)
    * *MUST* offer an interface that tests the depth of higher-order annotation
    * *MUST* ensure that higher-order annotations are acyclic (see more in next section on model constraints)
* *MUST* be able to parse from STAM JSON
    * Parser implementations *MUST* also support both the normal stand-off form, as well as the inline form of specifying `AnnotationData` for annotations.
* *MUST* be able to serialise to STAM JSON

If any of requirements are not met, the implementation is not a *core* STAM implementation but a *partial* one.

Moreover, the following are *RECOMMENDED*, a STAM implementation:

* *SHOULD* implement reverse indices as described in the extended model (e.g. via `TextSelection`)
* *SHOULD* implement indices at the `DataKey` level

If these recommendations are also met, we speak of a *full* STAM implementation.

Last, some guidelines that are entirely optional but worth mentioning, a STAM implementation:

* *MAY* implement a binary serialisation
* *MAY* also implement any of the STAM extensions, it *SHOULD* indicate exactly which ones it implements.
* *MAY* offer an interface to redact text resources (i.e. add/edit/remove text at any point), and *MUST* subsequently update all affected `TextSelector`s.


## Model Constraints

Though STAM is designed in a way that allows researchers and developers to
model their annotations as they see fit, it does impose some important constraints
that should be kept in mind:

1. Annotations, including their selectors and their annotation data, *SHOULD* be
   regarded as *immutable* once created. It is bad practice to edit an existing annotation.
   If an annotation, its data or its selector is to be changed in any way, the old one *SHOULD* be removed and a new one made, carrying a different identifier (if any).
2. Higher-order annotations, i.e. annotations that reference other annotations via an `AnnotationSelector`, *MUST*
   only reference annotations that were chronologically defined before it. It can not make reference to
   an annotation that does not exist yet. From this follows that:
    * The order of annotations in the serialisation (e.g. STAM JSON) matters (only) to the extend that an annotation X that is referenced by another annotation Y, *MUST*
      be defined before Y is. The order of resources, annotation sets, data keys and data in an annotation set is not significant.

This may seem inflexible at first, but there is a good reason for this. From a
semantic perspective annotations are essentially a commentary about something
else. You can only comment on something if the thing you comment on already
exists. Furthermore, if that what you comment on is subject to change,
possibly unbeknownst to you, then such a change might invalidate your
commentary, as it is no longer the same thing as what you based your comment on!
The STAM model prevents these pitfalls.

Unlike models such as RDF, STAM is specialized in annotations on text, it
is not a means to express a generic knowledge graph.

From a technical perspective, these constraints reduce the annotation graph to
an annotation tree: it removes the risk of cyclic references and in doing so 
it makes a lot of computations easier.

The fact that higher-order annotations only point in one direction does not
imply you can't follow the links in the reverse direction during search. This is
accomplished by the various reverse indices in STAM and a core feature.

## Relation to other data models & motivations

In this final section I'll draw some parallels with other data models. Rather
than draw on existing data models, especially those in the realm of Linked Open
Data, I have opted to not adopt any of those. The reason is that I wanted a
simpler and more pragmatic stand-alone solution that has the right amount of
expressivity that is precisely tailored to the task of stand-off annotation,
*and not much more*.

My arguments for this are:

* I don't want to burden the user with having to learn many different and often highly complex models as a
  prerequisite to understanding the actual one they are interested in.
* I don't want implementations to have to rely on huge (and not always mature) 3rd party dependencies for such
  data models. A STAM implementation should be realistic with one main code base, needing only some well-established libraries like a
  generic JSON parser/serialiser, but requiring no further infrastructure.
* Existing standards like Web Annotations (in turn making use of JSON-LD and RDF) contain features that go well beyond
  what is needed for simple stand-off annotation, and are similarly still lacking certain features we do need for certain annotation scenarios.
* Existing models like RDF, Web Annotations tend to be very verbose and have more overhead, making performant
  processing more complicated. Though RDF is something we explicitly target as an export option, it is not a dependency.

STAM is more like a lowest common denominator, a pivot model if you will, that
allows expression of a wide variety of annotation paradigms. Exports of this
simpler data model to more expressive and established standards like RDF and
WebAnnotations are encouraged wherever appropriate.

The best comparisons can be drawn with annotation models such as [Web
Annotations](https://www.w3.org/TR/annotation-model/),  [Text
Fabric](https://annotation.github.io/text-fabric/tf/),
[Salt](https://corpus-tools.org/salt/) and LAF. Comparisons can also be
made with more specific-purpose text annotation formats or such as
[TEI](https://tei-c.org/), [FoLiA](https://proycon.github.io/folia) (disclaimer: I am the author of FoLiA),
[TCF](https://github.com/weblicht/tcf-spec), and
[NAF](https://github.com/newsreader/NAF), all of which are XML-based formats
which unlike STAM offer very specific annotation types. In STAM, all of those
would be user-defined, but it should be possible to reformulate some of these
data model in terms of STAM.

In designing STAM, inspiration has been drawn from all the above. 

## Acknowledgements

This work is conducted at the [KNAW Humanities Cluster](https://huc.knaw.nl/)'s [Digital Infrastructure department](https://di.huc.knaw.nl/), and funded by the [CLARIAH](https://clariah.nl) project (CLARIAH-PLUS, NWO grant 184.034.023) as part of the FAIR Annotations track.
