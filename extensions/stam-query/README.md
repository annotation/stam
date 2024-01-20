# STAM Query Language (STAMQL)

## Introduction

This STAM extension defines a query language that allows end-users to formulate
and subsequently execute searches on a STAM model.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Data Model

Implementation of this extension is *RECOMMENDED* to result in an extra
**Query** class that lives alongside the data model. However, this STAMQL
specification does not prescribe how this should be implemented.

## Language specification

The query language draws inspiration from query languages like SQL, SPARQL, FQL
(FoLiA Query Language), and more functionally rather than syntactically, from
Text Fabric.

A query consists of one or more *statements*, at this stage, each statement is
introduced by a *keyword* which *MUST* be in upper-case. Only a single
statement exist currently: the `SELECT` statement, but in later versions we
envision there will also be statements to modify the STAM model.

A select statement has the following syntax

* `SELECT` *type* *name* `WHERE` *constraint*`;` `{` *subquery* `}`
    * *type* denotes what the return type of the query is and is one of the following keywords:
        * `ANNOTATION` - query annotations
        * `DATA` - query annotation data
        * `TEXT` - query text selections
        * `RESOURCE` - query resources
        * `KEY` - query data keys
    * *name* is an *OPTIONAL* parameter and associates a variable name to store the query results in. This is needed when you want to refer to the results of a query from a later *subquery*. The name **MUST** start with a `?` (like in SPARQL).
    * The `WHERE` keyword introduces a series of one or more *constraints*. Each constraint *MUST* end with a semicolon.
        * The `WHERE` statement (and constraints) may be omitted entirely if there are no constraints. These are then simply queries for all annotations, data, text or resources in the model.
        * All constraints must be satisfied.
    * A query *MAY* have one *subquery*, it *MUST* be scoped inside curly braces, if there is no subquery, the curly braces *MUST* be omitted too.

A constraint starts with a *type* keyword which identifies the nature of the
constraint. Each constraint type takes a set of parameters, which *MUST* be
separated by one or more spaces, newlines or tabs. Double quotes *MUST* be used
when you want parameters to span over whitespace, literal double quotes inside
that scope *MUST* be escaped by a preceding backslash character. We distinguish
the following constraints and parameters:

* `ID` *id* - Constrain based on a public identifier, this effectively selects a single exact item. It usually occurs as first and only constraint, as any further constraints make little sense in this case.
* `DATA` *set* *key* - Constrain based on a key, regardless of its value. In contexts where this could be ambiguous, it is about annotation that target the text in some way. If you are interested in the other interpretation, use qualifier `AS METADATA` (see next item).
    * *set* - The annotation dataset which holds the key (next parameter) to test against
    * *key* - The data key to test for.
* `DATA` *set* *key* *operator* *value* - Constrain based on annotation data. In contexts where this could be ambiguous, it is about annotation that target the text in some way. If you are interested in the other interpretation, use qualifier `AS METADATA` (see next item).
    * *set* - The annotation dataset which holds the key (next parameter) to test against
    * *key* - The data key to query.
    * *operator* - The operator, may be one of `=`, `!=`,`>`,`<`, `>=`,`<=`. The operator and next value parameter are *optional*, if omitted, then all data pertaining to a datakey is selected (as shown in the previous item)
    * *value* - The data value to test against. Numeric values (integers, floats) *MUST NOT* be quoted for them to be recognised as such. Multiple values may be specified and separated by a pipe character. If you want a literal pipe character in a value, you *MUST* escape it with a backslash.
* `DATA AS METADATA` - Like above, but this constrains data associated with annotations that target the `RESOURCE`,  `KEY` or `DATA` item *as metadata* via respectively a *ResourceSelector*, *DataKeySelector*, or *AnnotationDataSelector*. It does not make sense in other contexts.
* `VALUE` *operator* *value* - Constraint based on a data test, like `DATA`, but this is used in contexts where the key is already a given, like `SELECT KEY` queries.
* `TEXT` *text* - Constrain based on textual content
    *  *text* - Literal text to match (case sensitive)
* `TEXT AS NOCASE` *text* - Constrain based on textual content
    *  *text* - Literal text to match (case insensitive)
* `TEXT AS REGEX` *text* - Constrain based on textual content
    *  *regex* - Regular expression following [this syntax](https://docs.rs/regex/latest/regex/#syntax). This is not yet normative but it is what current implementations use.
* `RESOURCE` *id* - Constrain based on the resource
    * *id* - A resource identifier 
* `RESOURCE AS METADATA` *id* - Only used with return type `ANNOTATION`. This selects annotations that target the resource via a *ResourceSelector*, i.e. to provide metadata on the resource as a whole.
    * *id* - A resource identifier
* `ANNOTATION` *id* - Constraint based on pertaining to a particular annotation (in case of data, text or resources). When applied to annotations, this constrains based on having specific annotation as annotation. That annotation is a newer/higher annotation in the hierarchy formed by *AnnotationSelector*.
    * *id* - An annotation identifier
* `ANNOTATION AS TARGET` *id* - Only used with return type `ANNOTATION`, this is the inverse of the above `ANNOTATION` constraint. This constrains annotation based on having a specific annotation as target. That annotation is an older/lower annotation in the hierarchy formed by *AnnotationSelector*.
    * *id* - An annotation identifier
* `UNION` *constraint* `OR` *constraint* ... - Constrain based on a union of constraints, meaning that only one of the constraints needs to be satisfied (disjunction). You can not just combine any constraints, constraints *MUST* have the same constraint type if they are to be used in a union.

The above was a rather formal specification, let's consider some examples, note
that the indentation in the examples is conventional and not normative:

*select all occurrences of the text "fly"*

```sparql
SELECT TEXT WHERE
    TEXT "fly";
```

*select all resources that contain the text "fly"*

```sparql
SELECT RESOURCE WHERE
    TEXT "fly";
```

*select all annotations that contain the text "fly"*

```sparql
SELECT ANNOTATION WHERE
    TEXT "fly";
```

*select all annotations with data 'part-of-speech' = 'noun' (ad-hoc vocab!)*

```sparql
SELECT ANNOTATION WHERE
    DATA "myset" "part-of-speech" = "noun";
```

*select all annotations with any 'part-of-speech' tag (ad-hoc vocab!)*

```sparql
SELECT ANNOTATION WHERE
    DATA "myset" "part-of-speech";
```

*select all annotations with data 'part-of-speech' = 'noun' made by a certain annotator (ad-hoc vocab!)*

```sparql
SELECT ANNOTATION WHERE
    DATA "myset" "part-of-speech" = "noun";
    DATA "myset" "annotator" = "John Doe";
```

Note: the data here *MUST* pertain to the same annotation. Compare this with the following:

*select all text with annotations with data 'part-of-speech' = 'noun' made by a certain annotator (ad-hoc vocab!)*

```sparql
SELECT TEXT WHERE
    DATA "myset" "part-of-speech" = "noun";
    DATA "myset" "annotator" = "John Doe";
```

Note: Unlike the previous example, here the two data constraint may be
satisfied by different annotations, both targeting the same text selection.

*select all annotations of the text "fly" with data 'part-of-speech' = 'noun' or `verb`*

```sparql
SELECT ANNOTATION WHERE
    DATA "myset" "part-of-speech" = "noun|verb";
    TEXT "fly";
```

*select all annotations with data 'part-of-speech' = 'noun' or 'syntactic-unit' = 'noun-phrase'*

```sparql
SELECT ANNOTATION WHERE
    UNION DATA "myset" "part-of-speech" = "noun" OR DATA "myset" "syntactic-unit" = "noun-phrase";
```

*select a single annotation by identifier*

```sparql
SELECT ANNOTATION WHERE
    ID "my-annotation";
```

## Query form

A query can be in one of two forms:

* *executable form* - The query is formulated strictly in executable order. It can be interpreted procedurally:
    * Statements, including subqueries, are executed in the exact order specified. 
    * Constraints are evaluated in the exact order specified. Especially the first constraint of a statement is important as that determines the initial selection of items (and what path to follow in which reverse index). Further constraints are then typically tests on these results, pruning the resultset along the way. The ordering has direct performance implications.
    * Subqueries *MUST* have at least one constraint that references a variable from a parent/ancestor statement (query has to be complete).
    * Constraints *MUST NOT* reference variables from later statements.
* *free form* - The order of both the statements and constraints within a statement is free. A **query optimiser** has to parse the query and re-order it (effectively building a dependency tree) so that can be *executed*. This form is much more difficult to implement. Implementations *SHOULD* specify whether they support free form or only executable form (currently only the latter exists and there are no free form implementations yet).

All example queries in this specification are in *executable form*.

## Query composition

A single query is not always expressive enough to retrieve the data you a
looking for. STAMQL solves this by allowing for each query statement to have a
*subquery*. A subquery is evaluated in the context of its parent query.
Programatically, a subquery can be interpreted as a nested `for` loop. When
using subqueries, we need the ability to name our query results (which we have
hitherto neglected in the examples). Subqueries *MUST* have at least one
constraint that links it to its parent.

Consider the following example:

```sparql
SELECT TEXT ?sentence WHERE
    DATA "myset" "type" = "sentence"; 
{
    SELECT TEXT ?fly WHERE
        RELATION ?sentence EMBEDS;
        DATA "myset" "part-of-speech" = "noun";
        TEXT "fly";
}
```

Here we explicitly select sentences with a particularly annotated text in it.
Both named variables *MUST* be explicitly returned in the query's result rows.



We can also make use of explicit hierarchical relationships between annotations
if these are modelled via an *AnnotationSelector*. The following query
illustrates an alternative to the above if sentences are modelled as an
explicit annotation (composite selector with annotation selectors) on
words.

```
SELECT ANNOTATION ?sentence WHERE
    DATA "myset" "type" = "sentence"; {

    SELECT ANNOTATION ?word WHERE 
        ANNOTATION ?sentence;
        DATA "myset" "type" = "word";
        DATA "myset" "part-of-speech" = "noun";
        TEXT "fly";

}
```

Given the same model, you can invert the two queries by using `ANNOTATION AS TARGET` instead of `ANNOTATION`:

```

SELECT ANNOTATION ?word WHERE 
    DATA "myset" "type" = "word";
    DATA "myset" "part-of-speech" = "noun";
    TEXT "fly"; {

    SELECT ANNOTATION ?sentence WHERE
        ANNOTATION AS TARGET ?word;
        DATA "myset" "type" = "sentence";

}
```

The next example shows a complex query where we select a particular noun
followed by a verb, the combination occurring in a particular context (book,
chapter, sentence). Details depend a bit on how things are modelled. We assume
the books are modelled as separated resources, with annotations naming them:

```sparql
SELECT RESOURCE ?book WHERE
    DATA AS METADATA "myset" "name" = "Genesis|Exodus"; {

SELECT TEXT ?chapter WHERE 
    RESOURCE ?book
    DATA "myset" "type" = "chapter";
    DATA "myset" "number" 2; {

SELECT TEXT ?sentence WHERE 
    DATA "myset" "type" = "sentence";
    RELATION ?chapter EMBEDS; {

SELECT TEXT ?nn WHERE
    RELATION ?sentence EMBEDS;
    DATA "myset" "type" = "word";
    DATA "myset" "pos" = "noun";
    DATA "myset" "gender" = "feminine";
    DATA "myset" "number" = "singular"; {

SELECT TEXT ?vb WHERE
    RELATION ?nn PRECEDES;
    RELATION ?sentence EMBEDS;
    DATA "myset" "type" = "word";
    DATA "myset" "pos" = "verb";
    DATA "myset" "gender" = "feminine";
    DATA "myset" "number" = "plural";

}}}}
```

The above needn't be the most efficient way and, as said, it depends on how
things are modelled exactly, but this one reads easily in a top-down fashion. 

    

### Constraints in query composition

Let us formalize the new constraints we have seen that are used in query
composition, defining a relationship between a parent query and a subquery:

* `DATA` *?x* - Constrain data based on a parent query. The referenced parent query *MUST* have type `DATA`.
* `TEXT` *?x* - Constrain text based on a parent query. The referenced parent query *MUST* have type `TEXT`.
* `KEY` *?x* - Constrain text based on a parent query. The referenced parent query *MUST* have type `KEY`.
* `RELATION` *?x* *relation* - Constrains based on a textual relationship
    * *relation* is a keyword of: `EMBEDS`, `OVERLAPS`, `PRECEDES`, `SUCCEEDS`, `BEFORE`, `AFTER`, `SAMEBEGIN`, `SAMEEND`, `EQUALS`
      Read this as, for instance: "X embeds Y", where X is the explicit variable in the constraint, which comes from a parent query, and Y is (implicitly) the variable selected in the current select statement.
* `RESOURCE` *?x* - Constrain text based on a resource. The referenced parent query *MUST* have type `RESOURCE`.
* `ANNOTATION` *?x* - Constrain annotations based on explicit hierarchical relationships between annotations (following `AnnotationSelector`), Read this as "X is an annotation on Y" or "Y annotates X", where X is the explicit variable in the constraint that comes from a parent query, and Y the variable selected in the current select statement. Annotation Y *MUST* have been made before annotation X. The referenced parent query *MUST* have type `ANNOTATION`.
* `ANNOTATION AS TARGET` *?x* - Constrain annotations based on explicit hierarchical relationships between annotations (following `AnnotationSelector`), Read this as "X is an annotation target of Y" or "X annotates Y" or "Y is an annotation on X", where X is the explicit variable in the constraint that comes from a parent query, and Y the variable selected in the current select statement.Annotation X *MUST* have been made before annotation Y. The referenced parent query *MUST* have type `ANNOTATION`.
