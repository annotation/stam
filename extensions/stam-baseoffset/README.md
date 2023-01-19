# STAM-Baseoffset: Splitting large text resources into multiple 

## Introduction

This is a minor extension on top of STAM that allows splitting large monolithic text resources into multiple smaller text resources, whilst still retaining the ability the reference offsets as if they refer to the original/monolithic resource.

Say you have a corpus `corpus.txt` which is of a substantial size that may be prohibitive to load into memory at once (which is what certain STAM implementation would do). You could use some mechanism (which STAM does not define) to split it into parts (`part1.txt`,`part2.txt`..) and then reference the parts. However, without this extension, each part would start at offset 0, and that may not be how you want to model things. With this extension enabled, you can express offsets as-if they'd refer to the pre-splitted resource.

The parts that you actually reference in your model needn't be contiguous if you are only interested in some limited specific views on the data.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Data Model

### Class: TextResource

This extension extends the data model for TextResource with a single new property:

* ``baseoffset`` - (type: int) - Offset in unicode-points at which the resource starts. If unset, this *MUST* default to 0 (which is the same as if this extension were not enabled).

## Linking resources together

This extension does not define a mechanism to link resources together, e.g. to express that `part1.txt` is a part of a larger `corpus.txt`. This can, however, already by accomplished in STAM by creating an annotation with a `DirectionalSelector` and multiple `ResourceSelector`s underneath. Vocabulary for this is not prescribed by STAM nor by this extension, but you can imagine typing such an annotation as a collection, book, chapter, section, verse, or however you see fit.

## Limitations

A limitation of this type of modelling is that no annotation can be expressed that references a single text span that crosses the boundaries of two resources (e.g. parts).
