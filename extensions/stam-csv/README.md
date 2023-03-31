# STAM-CSV: Serialisation and deserialisation to/from comma separated values

This extension defines an alternative serialisation format instead of STAM JSON, based on CSV. 

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Introduction

STAM JSON is a notably verbose serialisation format, as is JSON in general. All
field names are verbosely repeated throughout the serialisation, leading to a
lot of redundancy and leading to big file sizes. Of course, if file size is the
issue, you can just applying a compression algorithm and that will already make
a huge impact. However, we want to define an alternative to serialise STAM data in a more
tabular form.

We introduce STAM CSV: a tabular forms offers users another option of storage
and exchange of STAM data. CSV (comma separated values) is another ubiquitous
and even archaic serialisation format. It is more condensed than JSON and
offers a different perspective; one of rows and columns. This makes it a good
candidate for import in spreadsheets and relational databases. Which may be
useful in some use cases.

Neither JSON nor CSV are particularly optimised formats, and they each have
plenty of issues. We aim for easy interoperability here, not performance or
some ideal encoding. Our main criterion to opt for these formats is that they
are so simple and widespread. We just want to have easy ways to get STAM data
in and out of systems.

Both serialisations are capable of encoding the full core model of STAM.

## Comparison

The following table draws a comparison between STAM JSON and STAM CSV:

|                        | STAM JSON | STAM CSV |
|------------------------|-----------|----------|
| File size              |    Bigger | Smaller  |
| Redundancy             |     Large | Small    |
| Flexibility            |      More | Less     |
| Single file possible?  |       Yes | No       |
| Incorporated text?     |  Possible | Never    |
| Hierarchical data?     |  Suitable | Challenging  |
| Compressibility        |      Good | Good       |
|------------------------|-----------|----------|

Although all of the STAM core model is support with STAM CSV, it does add some additional constraints:

* Public identifiers *MUST NOT* contain a semicolon
* Public identifiers for `AnnotationData` are *REQUIRED* 

## Specification

STAM CSV splits the STAM model over several CSV files. Text resources *MUST* be
separate plain text files, they can not be included in the CSV unlike in STAM
JSON. For each type of CSV files, STAM CSV defines what columns *MUST* be used.
The order of the columns *SHOULD* be free (defined by the header), and unknown
columns *SHOULD* be ignored, they *MAY* be used by extensions.

STAM CSV *SHOULD* use ``,`` as delimiter and it *SHOULD* use quoting only when
necessary (i.e. because there is a comma or newline in the value itself).
Literal quotes in side a quote can be denoted by escaping with a backslash,
i.e. ``\"`` Newlines in cells *MUST* be permitted and *SHOULD* be unix-style
(i.e. without carriage return). The first line of each STAM CSV file *MUST* be
the header defining the columns, exactly as defined in this specification, and
differing per CSV file.

We represent hierarchical information in two ways; first by splitting various
items over multiple CSV files, and having a STAM public identifier to link
them. But, even though this is not ideal and already stretches the limits of
CSV, we do also use arrays in cells for certain columns, in those cases it is
*REQUIRED* to use a semicolon (`;`) as a subdelimiter (i.e. within a cell).
This is only possible for certain columns.

### Annotation Store

The annotation store *MUST* be represented by a file `$basename.store.stam.csv`, where `$basename` is replaced with whatever name you want to give to your store. It *MAY* correspond with the ID of the store. It *MAY* also contain periods.

The CSV file for the Annotation Store is effectively a small manifest that
lists what Annotation Datasets and Text Resources are part of the store. The
annotations themselves are stored in a separate CSV file.

This manifest is the root file from which all others can be found, it is therefore the file that is passed to systems for reading an entire STAM model. We call this CSV file the `StoreManifest` table.

The store manifest table has the following *REQUIRED* columns. 

* **Type** - Defined the type of the item on the row, can be `AnnotationStore`,
  `AnnotationDataSet` or `TextResource`.
* **Id** - The public Id of the item on the row. It is *REQUIRED* for
  `AnnotationDataSet` and `TextResource`
* **Filename** - The filename to include.
    * The filename is a full filename including extension. 
      A path component *MUST* be allowed, in which case it *MUST* be assumed to be
      relative if it does not start with a slash, and absolute if it does. Implementations may look for relative files
      as they see fit.  Even URLs *MAY* be used (as long as the mandatory extension
      is not included), but implementations are *NOT REQUIRED* to implement
      networking logic and *MAY* reject this (it has security implications).
      Implementations *SHOULD* make clear whether they support fetching remote URLs
      or not. 
    * Implementations *MAY* allow mixed formats, in which case the filenames may also refer to STAM JSON files rather than STAM CSV.

The first row (aside from the mandatory header) *MUST* be of type `AnnotationStore` and table `Annotation`. It effectively the stand-off file containing the actual annotation as well as the of the Id of the store as a whole.

Example:

```csv
Type,Id,Filename
AnnotationStore,mystore,mystore.annotations.stam.csv,
AnnotationDataSet,myset,myset.dataset.stam.csv
TextResource,myresource,myresource.txt,
```

The annotations pertaining to the store are stored in a separate CSV file. This file is *REQUIRED* even if there are no annotations yet (it *MAY* consist of only a header though). It has the following columns:

* **Id** - The public Id of the annotation (*OPTIONAL*) 
* **AnnotationData** - The public Id(s) of the `AnnotationData` used for this
  annotation. If there are multiple, they *MUST* be separated with a semicolon
  (the subdelimiter) without any no extra spacing. The actual annotationdata that is referenced here is
  defined in another CSV file.
* **AnnotationDataSet** - The public Id(s) of the annotation set of the annotation data in the previous column. If there are multiple DataId entires, you *SHOULD* also have multiple SetId values (separated with a semicolon). If you have less SetIds than DataIds, than the last defines SetId will be taken as applying to all later DataIds. In practise this means if you have multiple DataIds but they are all in one set (a common scenario), you can just get away with specifying only one SetId here.
* **SelectorType** - The Selector type that selects the target of the annotation. *MUST* correspond exactly to one of the defined selector types in the STAM core model.
    * If and only if complex selectors are used (`CompositeSelector`, `MultiSelector`, `DirectionalSelector`), this cell *MUST* contain multiple entries separated by a semicolon. The first item is always the complex selector, the remainder are the subselectors.
* **TargetResource** - The ID of the resource that is the selection target, if any. This applies to `TextSelector` and `ResourceSelector` only, or to complex selectors having such selector types as subselectors. In that case this cell contains an array of elements (semicolon delimited)
* **TargetAnnotation** - The ID of the annotation that is the selection target, if any. This applies to ``AnnotationSelector`` only, or to complex selectors having such selector types as subselectors. In that case this cell contains an array of elements (semicolon delimited)
* **TargetDataSet** - The ID of the annotation data set that is the selection target, if any. This applies to ``DataSetSelector`` only, or to complex selectors having such selector types as subselectors. In that case this cell contains an array of elements (semicolon delimited)
* **BeginOffset** - The begin offset in unicode points (0-indexed) , applies to `TextSelector` (*REQUIRED*) and to `AnnotationSelector` (*OPTIONAL*). Positive values represent a ``BeginAlignedCursor``, negative values ``EndAlignedCursor``. The syntax ``-0`` is used to encode ``EndAlignedCursor(0)``. If the selector is a complex selector, then this cell *MUST* be an array (semicolon delimited) of equal size or larger than `SelectorType`, if it is larger, the latest selector type applies to all remaining offsets. The first element is always empty for complex selectors.
* **EndOffset** - The end offset in unicode points (0-indexed, non-inclusive end). Follows the same syntax as `BeginOffset`. If ``BeginOffset`` contains multiple offsets (complex selector), then this cell *MUST* contain the exact same number of offsets, they will be interpreted in pairs corresponding to their index in the array. The first element is always empty for complex selectors.

Example:

```csv
Id,AnnotationData,AnnotationDataSet,SelectorType,TargetResource,TargetAnnotation,TargetDataSet,BeginOffset,EndOffset
A1,D1;D2,myset,TextSelector,myresource,,,6,11
A2,D3,myset,CompositeSelector;TextSelector;TextSelector,;myresource;myresource,,;0;6,;5;11
```

### AnnotationDataSet

An AnnotationDataSet  defines the keys (`DataKey`) and actual data (`AnnotationData`) used by annotations.

The CSV file for has the following *REQUIRED* columns:

* **Id** - The public ID of the `AnnotationData` reconstructed.
* **Key** - The public ID of the `DataKey`
* **Type** - The type of the `DataValue`. This *SHOULD* be left empty usually as it can be auto-detected. Set it only if you want to force a type.
* **Value** - The `DataValue`.

Example:

```csv
Id,Key,Type,Value
D1,pos,,noun
D2,pos,,verb
```

The keys are implicitly derived from the data, but they *MAY* also be explicitly defined. In that case the Id, Type and Value columns *MUST* be left empty. The following example defines only a key, without actual data:

```csv
Id,Key,Type,Value
,pos,,
```

Both types of rows may be mixed in a single CSV file.

