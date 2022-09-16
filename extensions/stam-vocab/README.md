# STAM-Vocab: Vocabularies and simple validation

## Introduction

This is an extension on top of STAM that allows expressing and validating against user-defined vocabularies.

Validation is an important aspect of annotation, it is often too easy to have erroneous input pollute the annotation data.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Data Model

Vocabularies *MAY* be defined, these are defined at the key-level (``DataKey``). A vocabulary is either closed or open, as indicated by a boolean parameter.
For closed vocabularies, valid `AnnotationData` instances *MUST* be part of the predefined `vocabulary`.

Irrespective of whether vocabularies are used or not, constraints may also be posed on the type of the data value, and even on its value.

Implementations implementing this extension *MUST* validate whether `AnnotationData` associated with `Annotation`s is valid. They *MUST NOT* serialize or otherwise publish annotations if they violate the constraints.  Implementations *SHOULD* allow invalid states only temporarily when editing/parsing is not complete yet.

### Class: DataKey

This extensions introduces three new properties:

* ``vocabularies`` (type: ``[&AnnotationData*]``) - Links to all predefined values for this key.
* ``typeconstraint`` - Signals that values must be of the specified type. This takes an enum `TypeConstraint` with the following options:
    * ``NoConstraint`` - The default
    * ``StaticConstraint(&AnnotationData)`` - Not just the type is constrained, but the value must be exactly this
    * ``StringConstraint(minlength?,maxlength?,regex?)``
    * ``BoolConstraint``
    * ``IntConstraint(minvalue?, maxvalue?)``
    * ``FloatConstraint(minvalue?, maxvalue?)``
    * ``ListConstraint(TypeConstraint)`` - Type must be a list, all members must adhere to the wrapped constraint
    * ``OrConstraint([TypeConstraint+])`` - Allow any of multiple constraints
    * ``NotConstaint([TypeConstraint+])`` - Allow none of one or more constraints
* ``relationconstraint`` -  
* ``closed`` (type: ``bool``) - Signals that the vocabulary is closed and one of the values predefined values in vocabularies must be set, otherwise it can be either one of the predefined values or any other.

