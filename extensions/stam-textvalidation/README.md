# STAM-Textvalidation

## Introduction

This is an extension for STAM that adds extra redundancy information to a STAM model to safeguard the integrity of the data.

Validation is an important aspect of annotation, it is often too easy to have
erroneous input pollute the annotation data. Stand-off annotation in particular
is very sensitive to annotations and the resource running out of sync. This
extension protects against that.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Vocabulary

This extension defines an annotation dataset with ID `https://w3id.org/stam/extensions/stam-textvalidation/`.
In this set we define the following keys, the use of `checksum` over `text` is *RECOMMENDED* by this extension:

* ``checksum``: The SHA-1 checksum of the text of the annotation. We use SHA-1 because it is *fast* and *small enough* (40 bytes). It does not offer strong cryptographic security though.
* ``text``: The exact text of the current annotation
* ``delimiter``: The delimiter to use to concatenate text selections in case the current annotation has a complex selector. If this key is not supplied, concatenation *MUST* proceed without delimiter.

The advantage of `text` over `checksum` is that it is directly interpretable
and facilitates readability of a serialisation. For any other purposes, 
the overhead quickly becomes a nuisance and a `checksum` is appropriate, the latter is therefore *RECOMMENDED*.

## Functionality

Parser implementations, whenever encountering a `text` or `checksum` key in an annotation's data,
*MUST* verify if the text of the annotation matches the `text`
property or the SHA-1 checksum in the `checksum` property. If not,
implementations *SHOULD* raise a hard validation failure. 
