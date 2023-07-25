# STAM API

This document describes the high-level STAM API, it is not normative and any implementation may decide to do things completely different. This document also does not cover the internal low-level implementation.

## Names and conventions

* All methods that return multiple items return iterators whenever they can; if some kind of buffering is needed they may return a set. For Python however, iterators are consumed before returning so both will be just lists. 
In this document such return types are just denoted as `[T]`.
* The name of the function should give a fair indication of what is returned and what is passed.
* In the Rust implementation, almost all return types are wrapped in `ResultItem<>`. Wherever I mention an implementation for `T` here or a result type `T` here, I mean `ResultItem<T>`. This distinguishes the high-level API from the low-level one. `TextSelection` needs special treatment and is wrapped as `ResultTextSelection` instead.

## Identifiers

Implemented on all types that *may* have a public identifier (implemented for `ResultItem<T>`):

```
id() -> Option<str>
```

Implemented on all types that have an internal identifier (implemented for `ResultItem<T>`):

```
handle() -> int
```

Note, TextSelection implements `handle() -> Option<int>` instead, as a handle
is only available for bound/known textselections, not arbitrary ones.

In the Rust implementation, we don't really return int but wrapped ints like AnnotationHandle, TextResourceHandle, etc. This ensures the compiler forces us never to mix up our handles (as their actual int value is not globally unique).

## Basic retrieval

### Resource 

implemented for AnnotationStore:

```
resource(handle_or_id) -> Option<TextResource>
```

TextSelection also has a `resource()` method (without parameters and outside of this trait), that returns the resource it belongs to.

### Resources 

implemented for AnnotationStore, Annotation:

```
resources() -> [TextResource]
```

### Dataset

implemented for AnnotationStore:

```
dataset(handle_or_id) -> Option<AnnotationDataSet>
```

### Datasets 

implemented for AnnotationStore, Annotation:

```
datasets() -> [AnnotationDataSets]
```

### Annotation 

Implemented for AnnotationStore:

```
annotation(handle_or_id) -> Option<Annotation>
```

### Annotations

Implemented for:

* AnnotationStore, 
* AnnotationDataSet, DataKey and AnnotationData where it is constrained to annotations found via the appropriate reverse indices:
* All *targetable nodes*: Annotation, TextSelection, AnnotationDataSet, TextResource, or aggregates thereof (ResultItemSet, TextSelectionSet), here it returns annotations *about* the target.


```
annotations() -> [Annotation]
```

The method id Other *targetable nodes* (Annotation, TextSelection, AnnotationDataSet, TextResource, or aggregates thereof (ResultItemSet, TextSelectionSet)) implement the following:

Which returns annotations *about* that target. TextResource has two more specific variants (`annotations()` will return both indiscriminately):

* `annotations_on_text() -> [Annotation]` - Annotations that target a text selection in the resource (follows back through a TextSelector)
* `annotations_as_metadata() -> [Annotation]` - Annotations that target the resource as a whole (follows back through a ResourceSelector)

### Targeted Annotations

This method is implemented for `Annotation` only, if follows annotations that are targeted via an `AnnotationSelector` (possibly via complex selectors):

* `annotations_in_targets(recursive?, track_ancestors?) -> [Annotation]`
    * `recursive?` - Apply recursively
    * `track_ancestors?` - Return the full path of ancestor annotations for each result
    * (this method returns an extra wrapper layer around the annotion to accommodate possible extra information)

### Key

implemented for AnnotationDataSet:

```
key(handle_or_id) -> Option<DataKey>
```

AnnotationData also has a `key()` method (without parameters and outside of this trait), that returns the key it belongs to.

### Keys 

implemented for AnnotationDataSet, Annotation, TextSelection:

```
keys() -> [DataKey]
```

### AnnotationData

implemented for AnnotationDataSet:

```
annotationdata(handle_or_id) -> Option<AnnotationData>
```

### trait GetTextSelections

implemented for TextResource, TextSelection, and Annotation:

```
textselection(offset) -> Option<TextSelection>
textselections(textual_order?) -> [TextSelection]
```

Note: `offset` is always relative to the container implementing it (and in the implementation for `Annotation` it only makes sense if it references a single textselection rather than multiple).

Enabling `textual_order` incurs only minimal performance cost here (there are indices available).

### trait Text

implemented for TextResource, TextSelection:

```
text() -> str
textlen() -> int
text_by_offset(offset) -> str
split_text(delimiter) -> [TextSelection]
trim_text(chars) -> [TextSelection]
utf8byte(charpos: int) -> int
utf8byte_to_charpos(bytepos: int) -> int
```

These are not implemented directly for Annotation because those *may* reference
no text at all, or multiple Text Selections, which *may* not be contiguous either. Annotations
do implement the following high-level method (outside of any trait):

```
text() -> [str]
```

## Search by Data 

### enum DataSearchPattern

The methods in this section all search for or by annotation data based on a search pattern `DataSearchPattern` that consist of some combination of:

1. a set
2. a key 
3. and value or value test. The value test is implemented in the `DataOperator` enum.

You can specify all kinds of combinations of these three. And you can omit any
of them (though if you omit one in this list, you must also omit all that come
after). Note that within some implementation context, `DataSearchPattern` may
already be constrained to certain values. Producing conflicting out-of-context
values will then simply not yield any results.

### enum DataOperator

Contains various comparison and logical operators to test values (equals, greater than, and, or, etc etc..). The test value is embedded as part of the operator.

### Find by data (entry methods)

There are high level entry methods implemented for AnnotationStore to search by data methods:

```
find_data(set, key, value_test) -> [AnnotationData]
resources_by_metadata(set, key, value_test) -> [(TextResource,AnnotationData)]
annotations_by_data(set, key, value_test, textual_order?) -> [(Annotation,AnnotationData)]
datasets_by_metadata(set, key, value_test) -> [(AnnotationDataSet,AnnotationData)]
text_by_data(set, key, value_test, textual_order?) -> [(TextSelection,AnnotationData)]
test_data(set, key, value_test) -> bool
```



### Find by data (owned data)

Implemented for:

* Annotation, where considers only the data directly owned by the annotations
* AnnotationDataSet, where it covers only the data directly owned by the set, completely independent of any annotations:
* DataKey, where it is constrained to data in the set that references the key
 
```
data() -> [AnnotationData]
find_data(key, value_test) -> [AnnotationData]
test_data(key, value_test) -> bool
```

### Find by data (about self)

Then there are the following implemented for all *targetable nodes*: Annotation, TextSelection, AnnotationDataSet, TextResource, or aggregates thereof (ResultItemSet, TextSelectionSet):

```
data_about() -> [(AnnotationData, Annotation)]
find_data_about(set, key, value_test) -> [(AnnotationData, Annotation)]
test_data_about(set, key, value_test) -> bool
```

In the second method, in addition to returning the actual data, the annotations that hold the data are also returned.

For Annotation, the data returned by `data_about()` does **NOT** overlap with `data()`.

For TextResource, this function has two specialised variants:

* `find_data_about_text() -> [Annotation]` - Annotations that target a text selection in the resource (follows back through a TextSelector)
    * `test_data_about_text() -> bool`
* `find_metadata_about() -> [Annotation]` - Annotations that target the resource as a whole (follows back through a ResourceSelector)
    * `test_metadata_about() -> bool`


### Find by Data (in targets)

Implemented for Annotation only, and only produces results if there are AnnotationSelectors:

```
annotations_by_data_in_targets(set, key, value_test, textual_order?) -> [Annotation]
find_data_in_targets(set, key, value_test, include_self?) -> [(AnnotationData, Annotation)]
test_data_in_targets(set, key, value_test) -> bool
```

For Annotation, the `data_in_targets()` from the `FindData` trait and the above methods do **NOT** overlap in their results unless `include_self` is set.

### Find given data/keys (reverse methods)

The following are implemented for `AnnotationData` and `DataKey`:

* `annotations() -> [Annotation]` - Returns annotations that make use of this data/key
* `resources() -> [TextResource]` - Returns text resources that make use of this data/key via annotations (either as metadata or as text)
* `resources_as_metadata() -> [TextResource]` - Returns resources that make use of this data/key as metadata (via annotation with a ResourceSelector)
* `resources_on_text() -> [TextResource]` - Returns resources that make use of this data/key for text (via annotations with a TextSelector)
* `datasets() -> [AnnotationDataSet]` - Returns datasets that annotations reference via a DataSetSelector (i.e. metadata)

## Search by Text Relations

Implemented on all types that can be reduced to TextSelection (or set thereof): TextSelectionSet, Annotation

```
related_text(TextSelectionOperator)  -> [TextSelection]
test_related_text(TextSelectionOperator, other)  -> bool
annotations_by_related_text(TextSelectionOperator)  -> [Annotation]
```

Then there is the following which effectively combined `related_text()` with `find_data_about()`/`test_data_about()` on its results. It is used to search related text that has annotation with specific data about that text.

```
related_text_with_data(TextSelectionOperator, key, value, value_test)  -> [(TextSelection, [(AnnotationData,Annotation)])]
related_text_test_data(TextSelectionOperator, key, value, value_test)  -> [TextSelection]
```

## Search by Textual Content

Implemented on all types that hold text (directly or indirectly): TextSelection, TextResource, Annotation (with TextSelectors somwhere)

```
find_text_regex(expressions) -> [TextSelection]
find_text(textfragment, case_sensitive) -> [TextSelection]
find_text_sequence([textfragment], skip_chars, case_sensitive) -> [TextSelection]
annotations_by_text(fragment, case_sensitive) -> [Annotation]
```

There are high-level entry methods implemented for AnnotationStore to search by text:

```
resources_by_text(textoperator, textfragment) -> [TextResource]
annotations_by_text(textoperator, textfragment) -> [Annotation]
```

Textoperator can be Equals or Contains.
