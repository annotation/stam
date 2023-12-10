# STAM-Vocab: Vocabularies and simple validation

## Introduction

This is an extension on top of STAM that allows expressing and validating against user-defined vocabularies. The extension is itself a vocabulary and prescribes functionality enabled through this vocabulary. This extension does not alter the underlying data model.

Validation is an important aspect of annotation, it is often too easy to have erroneous input pollute the annotation data.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Vocabulary

This extension defines an annotation dataset with ID `https://w3id.org/stam/extensions/stam-vocab/`.
In this set we define the following keys:

* `closed` - (type `Bool`) - This key is used on annotations on `DataKey` (via `DataKeySelector`)  or `AnnotationDataSet` (via `DataSetSelector`). It takes a boolean value. When targeting a `DataKey` if and only if `closed` is set to true, this indicates that the key is part of a closed vocabulary and that modellers *MUST* choose one of the already existing values (`AnnotationData`) in the set. In these cases, new values *MUST* be rejected by the implementation. When targeting an `AnnotationDataSet` and if and only if `closed` is set to true, this indicates that the dataset  s a closed vocabulary and that modellers *MUST* choose one of the already existing keys (`DataKey`) in the set. In these cases, new keys *MUST* be rejected by the implementation.
* `type` - (type `String`) - This key is used on annotations on `DataKey` (via `DataKeySelector`). It takes one of the following values. Implementations *MUST* reject any values (`DataValue`) for the targeted key if and only if the type doesn't match:
    * ``Any`` - No constraints, all values *MUST* be accepted. This is the default behaviour you also get without STAM-Vocab).
    * ``Null`` - Value *MUST* be null.
    * ``String`` - Not just the type is constrained, but the value must be exactly this
    * ``Bool`` - Value *MUST* be true or false.
    * ``Int`` - Value *MUST* be an integer.
    * ``Float`` - Value *MUST* be a floating point number.
    * ``List`` - Value *MUST* be a list (no further subtyping supported yet).
    * *(note that all of the above values except `Any` is defined in identical terms to `DataValue` itself)*
* ``label`` - (type: ``String``) - This key is used on annotations on `DataKey` (via `DataKeySelector`) or `AnnotationData` (via `AnnotationDataSelector`) and defines a preferred human readable label for respectively the key or the value. 
* The following are keys used by annotations on `DataKey` (via `DataKeySelector`) which pose further constraint on the use of the targeted key and its value:
* ``maxcountconstraint`` - (type: ``Int``) -  Signals how many times the targeted key may occur within the same annotation. If this exceeded new `AnnotationData` *MUST* be rejected.
* ``maxint`` - (type: ``Int``) - Signals the maximum value of an integer range, lower values *MUST* be rejected.
* ``minint`` - (type: ``Int``) - Signals the minimum value of an integer range, higher values *MUST* be rejected.
* ``maxfloat`` - (type: ``Float``) - Signals the maximum value of a float range, lower values *MUST* be rejected.
* ``minfloat`` - (type: ``Float``) - Signals the minimum value of a float range, higher values *MUST* be rejected.
* ``testpattern`` - (type: ``String``) - A regular expression pattern used to validate a string value (annotation on `DataKey` via `DataKeySelector`). Non-matching values *MUST* be rejected. (Note: At this point in the time the precise syntax regular expression is not predefined yet and left to implementations).

Implementations implementing this extension *MUST* validate whether `AnnotationData` associated with `Annotation`s is valid. They *MUST NOT* serialize or otherwise publish annotations if they violate any constraints. Implementations *MAY* choose to allow invalid states only temporarily when editing/parsing is not complete yet.

