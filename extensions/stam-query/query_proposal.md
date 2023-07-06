# Brainstorming towards a STAM Query language

This is an informal proposal for the query language which I have in mind for querying STAM.
The actual language syntax should be considered a pseudo-language at this point and may take other form,
emphasis instead is on the underlying structure.

I'm writing this very much from a practical implementation perspective, so the
pseudo-language is fairly verbose as its parts map directly to constructs I can
implement. Inspiration was mainly the query language for Text Fabric, which is functionally very comparable, but inspiration was also
drawn form existing query languages like SQL, SPARQL and my own FQL (FoLiA Query Language).

* A query consists of one or more statements, at the moment I describe only the
  `SELECT` statement, but in a later phase statement can be added for
  adding/manipulating/deleting data. This can be interpreted similar as in SQL.
* A `SELECT` statement is made up of:
    * a target type (`TextSelection`,`TextResource`, `Annotation`); determines the type of node that is returned. All of these are existing fundamental concepts in the STAM model.
    * a variable to bind to (`?x`,`?y`).
    * the keyword `WHERE` followed by one or more **constraints**  (or zero constraints and without the `WHERE` keyword, but that is rare)
* The constraints consist of:
    * a constraint type:
        * `AnnotationData` to filter on data, it selects on set, key and value, where the value selection is mediated by a `DataOperator`.
        * `TextResource` to filter on resources.
        * `TextRelation` to filter on relations with other text selections, this includes a `TextSelectionOperator` (embeds,overlaps,etc) describing the nature of the relation.
        * `Text` to filter on textual content, mediated by a `TextOperator`
        * The constraint type may also be a logical operator grouping multiple sub-constraints: `OPTION` (disjunction, or) or `UNION` (conjunction, and)
    * Certain constraint types may only combine with certain statement return types, but the idea is to allow use of the constraints liberally on many return types. For example an `AnnotationData` constraint used with a return type of `TextSelection` is interpreted as: *give me text selections that have annotations with annotationdata X*. The path via annotations is often implicit.
    * A constraint can be preceded by a qualifier:
        * `ALL`, which means that the constraint must hold for everything that is under consideration, if a single candidate doesn't meet the constraint the whole statement is considered not to match.
        * `ANY`, which means that the constraint must hold for only one item under consideration, if a single candidate meets the constraint, than all others that do not match are returned as well.
* A query must be *complete*; meaning that all statements in it must bear a relation to another (i.e. the query graph must be connected); it can not contain unconnected subgraphs (that would simply amount to two separate independent queries).
* A query can be in two forms:
    * *executable form* - The query is formulated strictly in executable order. It can be interpreted procedurally:
        * Statement are executed in the exact order specified. 
        * Constraints are evaluated in the exact order specified. Especially the first constraint of a statement is important as that determines the initial selection of items (and what path to follow in which reverse index). Further consstraints are then typically tests on these results, pruning the resultset along the way.
        * All statements except the first need to have at least one constraint that references a variable from an earlier statement (query has to be complete).
        * Constraints may not reference variables from later statements.
    * *free form* - The order of both the statements and constraints within a statement is free. A **query optimiser** has to parse the query and re-order it (effectively building a dependency tree) so that can be *executed*. I will only implement this in a much later stage as this is another big project to accomplish right.

## Query examples

All queries in this section are in executable form (no query optimiser needed):

*select all occurrences of the text "fly"*

```sparql
SELECT TextSelection ?fly WHERE
    TextString TextOperator::Equals("fly")
```

*select all resources that contain the text "fly"*

```sparql
SELECT TextResource ?resource WHERE
    TextString TextOperator::Contains("fly")
```

*select all text selections that have an annotation 'pos' = 'noun' (ad-hoc vocab)

```sparql
SELECT TextSelection ?noun WHERE
    AnnotationData "someset","pos",DataOperator::Equals("noun")
```

*select all text selections that are annotated as a sentence ('type' = 'sentence', ad-hoc vocab)

```sparql
SELECT TextSelection ?sentence WHERE
    AnnotationData "someset","type",DataOperator::Equals("sentence")
```

Adding constraints already allows for more powerful queries: *select all text selections that are annotated as a sentence and which contain the text "fly"*

```sparql
SELECT TextSelection ?sentence WHERE
    AnnotationData "someset","type",DataOperator::Equals("sentence")
    TextString TextOperator::Contains("fly")
```

But what if we only want sentences with the word "fly" where it was annotated as noun (as opposed to a verb which it can be as well)? Here we need multiple statements:

```sparql
SELECT TextSelection ?sentence WHERE
    AnnotationData "someset","type",DataOperator::Equals("sentence")

SELECT TextSelection ?fly WHERE
    TextRelation ?sentence TextSelectionOperator::Embeds
    AnnotationData "someset","pos",DataOperator::Equals("noun")
    TextString TextOperator::Equals("fly")
```

Here we have to consider the execution order, the above is likely not the most
efficient as it will iterate over all sentences (remember, first constraint is
most important, it determines what is looped over). The following is better, as
select on instances of the word "fly" first:

```sparql
SELECT TextSelection ?fly WHERE
    TextString TextOperator::Equals "fly"
    AnnotationData "someset","pos",DataOperator::Equals("noun")

SELECT TextSelection ?sentence WHERE
    TextRelation ?fly TextSelectionOperator::Embedded
    AnnotationData "someset","type",DataOperator::Equals("sentence")
```

Next, consider a complex Text Fabric query:

```
book name=Genesis|Exodus
   chapter number=2
      sentence
          vb:word pos=verb gender=feminine number=plural
          nn:word pos=noun gender=feminine number=singular
nn < vb
```

Here we select a particular noun followed by a verb combination, occurring in a particular context (book, chapter, sentence). We can translate this to a query as follows (details depend a bit on how things are modelled). We assume the books are modelled as separated resources, with annotations naming them:

```sparql
SELECT TextResource ?book WHERE
    AnnotationData "someset","name" DataOperator::Any(DataOperator::Equals("Genesis"), DataOperator::Equals("Exodus"))

SELECT TextSelection ?chapter WHERE 
    TextResource ?book
    AnnotationData "someset","type" DataOperator::Equals("chapter")
    AnnotationData "someset","number" DataOperator::EqualsInt(2)

SELECT TextSelection ?sentence WHERE 
    AnnotationData "someset","type" DataOperator::Equals("sentence")
    TextRelation ?chapter TextSelectionOperator::Embeds

SELECT TextSelection ?nn WHERE
    TextRelation ?sentence TextSelectionOperator::Embeds
    AnnotationData "someset","type" DataOperator::Equals("word")
    AnnotationData "someset","pos" DataOperator::Equals("noun")
    AnnotationData "someset","gender" DataOperator::Equals("feminine")
    AnnotationData "someset","number" DataOperator::Equals("singular")

SELECT TextSelection ?vb WHERE
    TextRelation ?nn TextSelectionOperator::LeftAdjacent
    TextRelation ?sentence TextSelectionOperator::Embeds
    AnnotationData "someset","type" DataOperator::Equals("word")
    AnnotationData "someset","pos" DataOperator::Equals("verb")
    AnnotationData "someset","gender" DataOperator::Equals("feminine")
    AnnotationData "someset","number" DataOperator::Equals("plural")
```

Again, this needn't be the most efficient way and it also depends how things
are modelled exactly, but this one reads easily in a top-down fashion. 

At this point our pseudo-language is much more verbose than
the Text Fabric equivalent, but that is so we it is more evident what
constructs we need in implementation. We can always think of more concise
higher-level syntax to translate into these lower-level constructs.

I want to illustrate another example from Text Fabric that selects sentences
that do not contain a word with a frequency (as an annotation) of less than
100, i.e. all words in a sentence are more frequent:

```
sentence
/without/
  word freqLex<100
/-/
```

```sparql
SELECT TextSelection ?sentence WHERE
    AnnotationData "someset","type" DataOperator::Equals("sentence")

SELECT TextSelection ?word WHERE
    TextRelation ?sentence TextSelectionOperator::Embeds
    AnnotationData "someset","type" DataOperator::Equals("word")
    ALL AnnotationData "someset","freqLex" DataOperator::Not(DataOperator::LessThan(100))
```

This one adds the `ALL` qualifier to one of the constraints, which makes it
stronger. Rather than selecting only items matching the constraint (normal behaviour), it bails out
on the entire statement with no matches if the encounters an item that does not match the constraint.

Similarly, there is the `ANY` qualifier doing that makes a constraint weaker, and returns items that most match the constraint as long as it was matched once.

Constraints may also be combined with logical operators, `OPTION` for a disjunction (or) and `UNION` for a conjunction (and). 

```sparql
SELECT Annotation ?x WHERE 
    AnnotationData "someset","pos" DataOperator::Equals("noun")
    OPTION
        AnnotationData "someset","author" DataOperator::Equals("John Doe")
        AnnotationData "someset","datetime" DataOperator::GreaterThanDate(2021-01-23)
```

This selects annotations *(pos=noun)* either authored by John Doe or after a certain date (ad-hoc vocab). Note that here we select Annotations instead of Text Selections, that means the data must pertain to a single annotation. If we use `TextSelection` then the constraints may match distinct annotations, which is what we usually want but not in this case.

