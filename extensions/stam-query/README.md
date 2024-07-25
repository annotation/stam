# STAM Query Language (STAMQL)

## Introduction

This STAM extension defines a query language, STAMQL, that allows end-users to formulate
and subsequently execute searches on a STAM model.

This documentation is in part descriptive, explaining end-users how to use the language,
and in part normative, allowing other developers to implement the language:

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and
"OPTIONAL" in this document are to be interpreted as described in
RFC 2119.

## Formal Specification

We start with a formal specification of the query language. In the section
after we will explain the language by example to make things clearer. You may skip this
section and move to that one if you want to just get an impression.

* The query language is case sensitive, all STAMQL keywords *MUST* be in upper-case.
* Whitespace *MUST* be be interpreted leniently, newlines, consecutive spaces and tabs are all allowed outside of literals.
* String literals *MUST* be wrapped in double quotes if they contain any whitespace (space, tabs, newlines) or certain punctuation (i.e. semicolons). Quotes inside the literal *MUST* be expressed by escaping them with a backslash. Quotes are *OPTIONAL* for simple strings without whitespace or such punctuation.
* Numeric literals *MUST NOT* be not quoted. Both integers and floating point values are supported, including `-` sign for negative values.
* Variable binds and references *MUST* start with a `?`. (like in SPARQL)

### Grammar

Casual readers may want to skip this section as it is largely normative and aimed at implementors of the language.

A STAM query follows the syntax as laid out below in [Extended Backus-Naur form](https://www.w3.org/TR/REC-xml/#sec-notation) (as redefined by the W3C). This is formal grammar is still a work in progress and not finished:

```ebnf
query ::= selectQuery | addQuery | deleteQuery

selectQuery ::= "SELECT" resultType bindVariable? whereClause? subQueryBlock
resultType ::= "ANNOTATION" | "DATA" | "TEXT" | "RESOURCE" | "KEY" | "DATASET" modifier?
whereClause ::= "WHERE" (constraint ";")+
subQueryBlock ::= "{" subQueries "}"
subQueries ::= query | subQueries "|" query
bindVariable ::= "?"[a-zA-Z0-9_]+
literal = simpleLiteral | quotedLiteral 
simpleLiteral ::= [a-zA-Z0-9_]
quotedLiteral ::= '"' [^(\")]+ '"'             #quotes may be use for litera 

addQuery ::= "ADD" resultType whereClause? subQuery

--- TODO! NOT FINISHED! ----
```

### Data Model

Implementations of this extension are *RECOMMENDED* to add an extra
**Query** class that lives alongside the STAM data model. However, this STAMQL
specification does not prescribe how this should be implemented.

## STAMQL by Example 

The query language draws inspiration from query languages like SQL, SPARQL, FQL
(FoLiA Query Language), and more functionally rather than syntactically, from
Text Fabric.

We distinguish three types of queries, they are introduced via one of the following keywords:

* `SELECT` - A select query is a read-only query that returns queried data (data is meant in the broadest sense here and includes annotations, their annotation data, resources, text, etc.).
* `ADD` - An add query adds new data to the annotation store.
* `DELETE` - Deletes data from the annotation store

### Select query

A select query follows the following syntax (simplified, the formal grammar shown earlier will be more precise). We show three forms, each adds some further optional components:

* `SELECT` *type* *name*?
* `SELECT` *type* *name*? `WHERE` (*constraint*`;`)+
* `SELECT` *type* *name*? `WHERE` (*constraint*`;`)+ `{` *subqueries* `}`

*type* denotes what the result type of the query is, the type of data it
returns, and is set by one of the following keywords:

* `ANNOTATION` - query for annotations
* `DATA` - query for annotation data
* `TEXT` - query for text selections
* `RESOURCE` - query for entire resources
* `KEY` - query for data keys
* `DATASET` - query for annotation datasets

*name* is an *OPTIONAL* parameter and binds a variable name to hold the
query results matching this query. This parameter is needed when you want to refer to the results of a
query from a later *subquery*. The variable name **MUST** start with a `?`
(like in SPARQL).

We can now formulate a first example query:

```sparql
SELECT ANNOTATION ?a
```

The above query simply returns all annotations in the model (and refers to them
using the variable `a`), or with an other type keyword it would return all
resources, annotation data, text selections, keys, datasets, etc..

This is a pretty wide query and not very useful, usually you want to
*constrain* your query based on one or more criteria, which we call
*constraints*. These constraints *MUST* be introduced by the `WHERE` keyword,
and each *MUST* end with a semicolon:

Example: *select all annotations that have the exact text "fly"*

```sparql
SELECT ANNOTATION ?a WHERE
    TEXT "fly";
```

Note that the newline is conventional rather than normative. In this
documentation we place each constraint on one indented line for clarity, but
STAMQL *MUST* be lenient in handling whitespace (including newlines) outside of
literals.  String literals are typically double-quoted (and *MUST* be so if
they contain whitespace or certain punctuation like esemicolons). Quotes inside
such a literal may be escaped which a backslash.

We can add multiple constraints:

Example: *select all annotations that have the exact text "fly" and which are nouns*

```sparql
SELECT ANNOTATION ?a WHERE
    TEXT "fly";
    DATA "myset" "part-of-speech" = "noun";
```

This states that the exact text of the annotation must be *"fly"*, but also that
the annotation must have annotation data in set *"myset"* with key
*"part-of-speech"* and a value equal to *"noun"*. This effectively allows us to
select the occurrences of fly that are nouns (as opposed to, say, the verb). Of
course the sets, keys and values we use here are completely fictitious and
depend on whatever vocabulary you adopt.

The order of the constraints matters unless explicitly specified by your
implementation. We call this *executable form*. This means that first a search
for occurrences of the text "fly" will be executed, and then for each of the
results found, a check will be done whether the data constraint holds.
Constraints are evaluated in the exact order specified. Especially the first
constraint of a statement is important as that determines the initial selection
of items (and what path to follow in which reverse index). Further constraints
are then typically tests on these results, pruning the resultset along the way.
The ordering has direct, and sometimes drastic, performance implications.

In contrast, in *free form*, the order of constraints is free. A **query
optimiser** then has to parse the query and re-order it (effectively building a
dependency tree) so that can be *executed*. This form is much more difficult to
implement. Implementations *SHOULD* specify whether they support free form or
only executable form (currently only the latter exists and there are no free
form implementations yet).

### Constraints (Introduction)

We will now explain the various constraint there are in STAMQL. Each *MUST* be
introduced by a keyword that identifies the nature of the constraint, then it has a set of parameters, which
*MUST* be separated by whitespace.

We distinguish constraints listed below and describe their parameters and the
contexts in which they can be used. When we things like say *in context of
`ANNOTATION`*, we refer to the result type of the query the constraint pertains
to.

### Constraints by ID

* **Syntax:** `ID` *id* 

Constrain based on a public identifier, this effectively selects a single exact
item. It usually occurs as first and only constraint, as any further
constraints make little sense in this case. 

Example: *select a single annotation by identifier*

```sparql
SELECT ANNOTATION WHERE
    ID "my-annotation";
```

### Constraints by Data

* **Syntax (1):** `DATA` *set* *key*
* **Syntax (2):** `DATA` *set* *key* *operator* *value*

The first form constrains based on a key, regardless of its value. In contexts where this could be ambiguous (like `RESOURCE`), it is about annotation that target the text in some way. Parameters are:
 
* *set* - The annotation dataset which holds the key (next parameter) to test against
* *key* - The data key to test for.

The second form expands this and adds an actual test on the data value. 

* *operator* - The operator, may be one of `=`, `!=`,`>`,`<`, `>=`,`<=`. The operator and next value parameter are *optional*, if omitted, then all data pertaining to a datakey is selected (as shown in the previous item)
* *value* - The data value to test against. Numeric values (integers, floats) *MUST NOT* be quoted for them to be recognised as such. Multiple values may be specified and separated by a pipe character. If you want a literal pipe character in a value, you *MUST* escape it with a backslash.

**Example:** *select all annotations that have the exact text "fly" and which are nouns*

```sparql
SELECT ANNOTATION ?a WHERE
    TEXT "fly";
    DATA "myset" "part-of-speech" = "noun";
```

**Example:** *select all annotations with data 'part-of-speech' = 'noun' AND made by a certain annotator (ad-hoc vocab!)*

```sparql
SELECT ANNOTATION WHERE
    DATA "myset" "part-of-speech" = "noun";
    DATA "myset" "annotator" = "John Doe";
```

**Note:** the data here *MUST* pertain to the same annotation. Compare this with the following:

**Example:** *select all text with annotations with data 'part-of-speech' = 'noun' made by a certain annotator (ad-hoc vocab!)*

```sparql
SELECT TEXT WHERE
    DATA "myset" "part-of-speech" = "noun";
    DATA "myset" "annotator" = "John Doe";
```

Unlike the previous example, here the two data constraints may be satisfied by
*different* annotations, both targeting the *same* text selection. STAMQL makes use of
the fact that annotation data is never directly associated with text selections, but always mediated by annotations, so
the `DATA` constraint here automatically assumes this intermediate layer and allows for more concise formulation without needing
to resort to more complex query composition (see later).

There are two more forms, using the qualifier `AS METADATA`:

* **Syntax (3):** `DATA AS METADATA` *set* *key*
* **Syntax (4):** `DATA AS METADATA` *set* *key* *operator* *value*

Whereas forms 1 and 2 test data that pertains to text (following a *TextSelector*), 3 and 4 test against data associated with annotations that target the (result type) `RESOURCE`,  `KEY` or `DATA` item *as metadata* via respectively a *ResourceSelector*, *DataKeySelector*, or *AnnotationDataSelector*. It does not make sense in other contexts.

**Example:** *select all resources where "John Doe" is the author*

```sparql
SELECT RESOURCE ?res WHERE
    DATA AS METADATA "myset" "author" = "John Doe";
```

Compare this to this following example, which would instead select resources that have any annotation on its text, and that annotation is authored by "John Doe":

```sparql
SELECT RESOURCE ?res WHERE
    DATA "myset" "author" = "John Doe";and aim
```

The last form is used with a variable, the variable must come from a `DATA` or `KEY` context here. This is explained in *Query Composition*.

* **Syntax (5):** `DATA` *variable*
* **Syntax (6):** `DATA AS METADATA` *variable*

### Constraints by Data Value only

* **Syntax (1):**: `VALUE` *operator* *value*

Constraint based on a data test, like `DATA` above, but this is used in contexts where the key is already a given and specifying again would be redundant, like in `SELECT KEY` queries.

### Constraints by Text

* **Syntax (1):**: `TEXT` *text* 
* **Syntax (2):**: `TEXT AS NOCASE` *text* 
* **Syntax (3):**: `TEXT AS REGEX` *regex* 

This tests the text, it is valid only in `ANNOTATION` and `TEXT` contexts. It
comes in three flavours. The first is an exact text match (case sensitive), the
second case insensitive, and the third is a regular expression [this
syntax](https://docs.rs/regex/latest/regex/#syntax). The latter is not yet normative
but it is what current implementations use.

There are also forms used with variables, the variable must come from a `TEXT` or `ANNOTATION` context here. This is explained in *Query Composition*:

* **Syntax (4):**: `TEXT` *variable* 
* **Syntax (5):**: `TEXT AS NOCASE` *variable* 

### Constraints by Annotation

* **Syntax (1):** `ANNOTATION` *id* - 

Constrain based on pertaining to a particular annotation, this applies in contexts `DATA`, `TEXT`, `RESOURCE` or `ANNOTATION`. In order words, the item from the context is annotated by an annotation with the specified ID. When applied to annotations, this constrains based on having specific annotation as annotation, which is is a newer/higher annotation in the hierarchy formed by *AnnotationSelector*.

* **Syntax (2):** `ANNOTATION` *id* `OFFSET` *begin* *end*

In a `TEXT` context, you can further specify `OFFSET` *begin* *end* to select a particular text selection by offset. The parameters *begin* and *end* *MUST* be specified in unicode points (0-indexed, non-inclusive end). A negative sign is used to express end-aligned cursors (including `-0` to represent the end aligned cursor `0`). Omitting the *end* argument *MUST* be interpreted as if it was set to `-0`.

* **Syntax (3):** `ANNOTATION AS TARGET` *id* 
* **Syntax (4, equivalent to 3):** `ANNOTATION AS METADATA` *id* 

The above two constraints are equivalent and are only used in `ANNOTATION` context. This is the inverse of the above `ANNOTATION` constraint. It constrains an annotation based on having a specific annotation as target. That annotation is an older/lower annotation in the hierarchy formed by *AnnotationSelector*. 

**Note:** An extra qualifier `RECURSIVE` can be added (before the identifier), to search recursively in the annotation hierarchy rather than just one level.

There are also forms used with variables, the variable must come from a `TEXT` or `ANNOTATION` context here. This is explained in *Query Composition*:

* **Syntax (5):**: `ANNOTATION` *variable* 
* **Syntax (6):**: `ANNOTATION AS TARGET` *variable* 
* **Syntax (7, equivalent to 6):**: `ANNOTATION AS METADATA` *variable*

And in `TEXT` context only:

* **Syntax (8):**: `ANNOTATION` *variable*  `OFFSET` *begin* *end*   
* **Syntax (9):**: `ANNOTATION AS TARGET` *variable* `OFFSET` *begin* *end-users*
* **Syntax (10, equivalent to 9):**: `ANNOTATION AS METADATA` *variable*  `OFFSET` *begin* *end*

### Constraints by Resource

* **Syntax (1):** `RESOURCE` *id*
* **Syntax (2):** `RESOURCE` *id* `OFFSET` *begin* *end*

Constrain based on pertaining to a particular annotation. The first can be used in `ANNOTATION` and `TEXT` context, the latter only in `TEXT` context where it selects a particular text selection by offset. The parameters *begin* and *end* *MUST* be specified in unicode points (0-indexed, non-inclusive end). A negative sign is used to express end-aligned cursors (including `-0` to represent the end aligned cursor `0`). Omitting the *end* argument *MUST* be interpreted as if it was set to `-0`.

**Example:** *select all annotations on a particular resource*

```sparql
SELECT ANNOTATION WHERE
    RESOURCE "helloworld.txt";
```

**Example:** *select the first five characters of a particular (fictitious) resource*

```sparql
SELECT TEXT WHERE
    RESOURCE "helloworld.txt" OFFSET 0 5;
```

* **Syntax (3):** `RESOURCE AS METADATA` *id*

Form 3 is only used with return type `ANNOTATION`. This selects annotations that target the resource via a *ResourceSelector*, i.e. to provide metadata on the resource as a whole.

**Example:** *select the first five characters of a particular (fictitious) resource*

```sparql
SELECT ANNOTATION WHERE
    RESOURCE AS METADATA "helloworld.txt";
```

Comparing the two last examples, the first returns annotations on some part of the text of the resource, the latter returns annotation that target the resource as a whole, and may for instance yield metadata annotations, for instance about authorship or licensing.

There are variants with variables as well for all of the above:

* **Syntax (4):** `RESOURCE` *variable*
* **Syntax (5):** `RESOURCE` *variable* `OFFSET` *begin* *end*
* **Syntax (6):** `RESOURCE AS METADATA` *variable*

 
### Union Constraint 

* **Syntax**: `[` *constraint* ` OR ` *constraint* `]`

This groups constraints in a union (disjunction), meaning that only one of the constraints needs to be satisfied.

**Example**: *select all annotations with data 'part-of-speech' = 'noun' or 'syntactic-unit' = 'noun-phrase'*

```sparql
SELECT ANNOTATION WHERE
    [ DATA "myset" "part-of-speech" = "noun" OR DATA "myset" "syntactic-unit" = "noun-phrase" ];
```

### Limit Constraint

* **Syntax (1)**: `LIMIT` *items*
* **Syntax (2)**: `LIMIT` -*items*
* **Syntax (3)**: `LIMIT` *begin* *end*

This selects a subpart of a sequence, it comes in three forms. 

* With a positive integer (`LIMIT` *n*), it returns the first *n* items.
* With a negative integer (`LIMIT` *-n*), it returns the last *n* items.
* With two integers (`LIMIT` *begin* *end*), it returns the items *begin* to *end* (0-indexed, non-inclusive end).
  * The integers may be signed
  * And `end` value of 0 is interpreted as *until the very end*.

* **Example:** *Return the first sentence*

```sparql
SELECT ANNOTATION ?sentence WHERE
    DATA "myset" "type" = "sentence";
    LIMIT 1;
```

* **Example:** *Return the last two sentences*

```sparql
SELECT ANNOTATION ?a WHERE
    DATA "myset" "type" = "sentence";
    LIMIT -2;
```

* **Example:** *Return the second, third and fourth sentence*

```sparql
SELECT ANNOTATION ?a WHERE
    DATA "myset" "type" = "sentence";
    LIMIT 1 4;
```

* **Example:** *Return all sentences except the first*

```sparql
SELECT ANNOTATION ?a WHERE
    DATA "myset" "type" = "sentence";
    LIMIT 1 0;
```

* **Example:** *Return all sentences except the last*

```sparql
SELECT ANNOTATION ?a WHERE
    DATA "myset" "type" = "sentence";
    LIMIT 0 -1;
```

### Query Composition

A single query is not always expressive enough to retrieve the data you a
looking for. STAMQL solves this by allowing for each query statement to have
*subqueries*. A *subquery* is evaluated in the context of its parent query.
Subqueries *MUST* be in a subquery block marked by curly braces, i.e. it that
starts with `{` and ends with `}`. If such a block is used, there *MUST* be one
or more subqueries in it. Multiple subqueries are separated by a `|`.
Subqueries can in turn have subqueries of their own.

Programmatically, a subquery can be interpreted as a nested `for` loop. When
using subqueries, we need the ability to name our query results (which we have
hitherto neglected in the examples) and refer back to them via *variables*.
Subqueries *MUST* have at least one constraint that links it to its parent (by means of a variable).

Consider the following example (the whitespace and indentation is mere
convention), the curly braces signal the subquery.

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
Implementations *MUST* explicitly return both variables in the query's result rows.

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
    RESOURCE ?book;
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

#### Multiple subqueries

Multiple subqueries are allowed at the same level and are then separated by a
pipe character (`|`). This will lead to a combinatorial explosion though if
deeply nested. In the query results only one of the subqueries is returned in a
result row at a time. In other words, subqueries at the same level (siblings)
always behave as a disjunction.

Subqueries *MUST NOT* reference any variables made in sibling-subqueries.

### Context variables

In addition to the context variables from parent queries, STAMQL implementations
*SHOULD* support programatically injecting variables from the context from which the query engine
is called. Unlike variables explicitly mantioned in the queries, these need
then not be returned again in the result sets.

### Relation Constraint

This constraint imposes a spatial relationship between two texts selections. It is used in 
a `TEXT` context or an `ANNOTATION` context where the text can be derived. We
already saw some examples in the section on *Query Composition*, as this
constraint is used exclusively with variables and therefore often demands a subquery.

Even though we mention it last, it is one of the most essential constraints of
the query language from which a lot of expressive power is derived.

* **Syntax:** `RELATION` *reference-variable* *relation-keyword*

The relation keyword determines the nature of the relation, the following are defined:

* `EMBEDS` - The references text selection embeds the current candidate text selection. So the subject is wider and entirely subsumes the candidate.
* `OVERLAPS` - The references text selection overlaps with current candidate text selection. 
* `PRECEDES` - The referenced text selection precedes the current candidate, they are directly adjacent. So the current candidate comes after the mentioned variable.
* `SUCCEEDS` - The references text selection succeeds the current candidate, they are directly adjacent. So the current candidate comes before the mentioned variable.
* `BEFORE` - The referenced text selection comes before the current candidate. 
* `AFTER` - The referenced text selection comes after the current candidate. 
* `SAMEBEGIN` - The referenced text selection has the same begin offset as the candidate
* `SAMEEND` - The referenced text selection has the same end offset as the candidate
* `EQUALS` - The referenced text selection is equal to the candidate (this is pretty much useless) 

The subject variable refers to a variable from a parent/ancestor query, or an injected context variable.

* **Example**: *Select adjective-noun word pairs*

```sparql
SELECT TEXT ?noun WHERE
    DATA "myset" "type" = "word";
    DATA "myset" "pos" = "noun"; {

    SELECT TEXT ?adj WHERE
        RELATION ?noun SUCCEEDS;
        DATA "myset" "type" = "word";
        DATA "myset" "pos" = "adj";
}
```

For ease of interpretation, you could read the word *this* or the variable from the current subquery after the relation keyword:
*`RELATION ?noun SUCCEEDS this`* or *`RELATION ?noun SUCCEEDS ?adj`* . The fact that it is not explicitly written out like that is because it is a given and would be redundant.

### Delete Query

A query to delete anything (annotations, resources, annotation data, etc..) from the model is introduced with the `DELETE` keyword.

* **Syntax:** `DELETE` *type* *variable* `{` *subqueries* `}`

Each subquery *SHOULD* be a `SELECT` statement that selects the items to be deleted. It may itself also consist of deeper subqueries. The variable from the `DELETE` statement *MUST* refer to the variable that is bound to in any of the subqueries.

**Example:**  *Delete a single annotation with a specific ID*

```sparql
DELETE ANNOTATION ?a { 
    SELECT ANNOTATION ?a 
        WHERE ID "A1"; 
}
```

The types in the `DELETE` query and the subquery must typically correspond, but where possible implementations *SHOULD* derive them if they don't match (e.g. `ANNOTATION` from `TEXT`).

A `DELETE` query does not return any results itself.

### Add Query

Adding anything (annotation, resources, annotation data, etc..) to the model is accomplished with an `ADD` query.

* **Syntax:** `ADD` *type* *result-variable*? `WITH` (assignment`;`) `{` *subqueries* `}`

The optional result-variable expresses the variable that will be used in
returning the results, i.e. the added items. The *type* expresses both the
result type and, by definition, the type of what is added.

`SELECT` queries take a `WHERE` clause followed by constraints, `ADD` queries,
on the other hand, take a `WITH` clause followed by *assignments*.

The following assignments exist, multiple are allowed, each *MUST* end with a semicolon. 

* `DATA` *set* *key* *value*?  - Associates annotation data with the new annotation. Usable in `ANNOTATION` context. If no *value* is provided, it will be set to NULL.
* `ID` *identifier* - Assigns an identifier to the new item. Usable in `ANNOTATION`, `RESOURCE`, `DATASET` context.
* `TARGET` *variable* - The variable refers to a single variable in the subquery (or any subqueries thereof). It determines what it being annotated. A target is *REQUIRED* in `ANNOTATION` context.
* `COMPOSITE`  - This assignment, if used, *MUST* come *prior* to any `TARGET` assignments, and indicates that a Composite Selector will be created over *multiple* targets. If multiple `TARGET` items are encountered, this is the default unless any of the below are encountered.
* `MULTI`  - This assignment, if used, *MUST* come *prior* to any `TARGET` assignments, and indicates that a Multi Selector will be created over *multiple* targets. Applying to each individually and independently.
* `DIRECTIONAL`  - This assignment, if used, *MUST* come *prior* to any `TARGET` assignments, and indicates that a Directional Selector will be created over *multiple* targets. Applying to all in the exact order specified.

A subquery is *REQUIRED* in an `ANNOTATION` context and selects the items that are to be annotated:

**Example:**  *Tag all instances of the word 'electrocution' as noun*

```sparql
ADD ANNOTATION ?a WITH 
    DATA "myset" "part-of-speech" "noun"; 
    DATA "myset" "author" "me"; 
    TARGET ?x; 
{
    SELECT TEXT ?x WHERE 
        TEXT "electrocution";
};
