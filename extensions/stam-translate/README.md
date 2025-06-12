# STAM-Translate: Linking related text selections

## Introduction

This is an extension on top of STAM that allows linking arbitrary textual parts
(including across resources), which we call *translation*. This extension defines a
vocabulary and prescribes functionality enabled through this vocabulary. This
extension does not alter the underlying core data model.

This is a simpler and more generic variant of the [STAM transpose](../stam-transpose/) extension.
Whereas, transposition defines an exact mapping between any text selections, translations
are texts that are somehow related but where the textual content is not identical.
We use this term in a wide definition, so it covers not just natural language translation, but also things like
transliteration, text normalisation, spelling correction, etc.. 

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in RFC 2119.

## Vocabulary

A **translation** is, like everything in STAM, just an annotation. Annotations
that describe translations are explicitly marked as being a translation by
the following key in the annotation dataset with identifier
``https://w3id.org/stam/extensions/stam-translate/``:

* `Translation` (type: `Null`) - Marks an annotation as being a translation. A translation *MUST* use a `DirectionalSelector` or `CompositeSelector`, with underneath an `TextSelector` to target two or more text selections directly. 

In case the translation is a natural language translation, this extension
*RECOMMENDS* the use of the following key to identify the language:

* `lang` (type: `String`) - The value *MUST* be an [iso-639-3 language code](https://iso639-3.sil.org/code_tables/639/data).

## Functionality

STAM implementations implementing this extension do not need to provide any specific functionality.

## Limitations

Translations do not hold the same properties as transpositions do, i.e. you can not use them to transpose annotations over.
If you want to map equal text in different places, then use [transposigions (STAM-transpose extension)](../stam-transpose/README.md) instead.
