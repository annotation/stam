# STAM-Textvalidation

## Introduction

This is an extension on top of STAM that adds extra information to STAM serialisations that safeguard the integrity of the data.
It can also help make serialisations more readable upon introspection, as it adds a layer of redundancy.

Validation is an important aspect of annotation, it is often too easy to have erroneous input pollute the annotation data.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Data Model

This extensions adds two properties to ``TextSelector``, using either one of them is *RECOMMENDED* by this extension:

* ``text``: The exact text of the annotation that is being pointed to. 
* ``checksum``: The SHA-1 checksum of the text of the annotation. We use SHA-1 because it is *fast* and *small enough* (40 bytes). It does not offer strong cryptographic security though.

The advantage over `text` over `checksum` is that it is directly interpretable
and facilitates readability of a serialisation. However, for very large texts
this may become a nuisance and a `checksum` may be more appropriate.

It is *NOT REQUIRED* for implementations to keep these properties throughout the lifetime of the model. Implementations *SHOULD* merely consult them at parse-time and *SHOULD* recompute them at serialisation time. 

## Functionality

Parser implementations, whenever encountering a `text` or `checksum` property,
*SHOULD* verify if the text of the selector matches the text in the `text`
property or the SHA-1 checksum in the `checksum` property. If not,
implementations *SHOULD* raise a hard validation failure. 





