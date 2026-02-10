
# v1.3.0 - 2025-09-08

* **STAM Translate** -  This extension (introduced in v1.2.0) got expanded to be much more powerful:   
   * New `translate()` function.
   * Added example figures
* **STAM Transpose**
   * Minor rephrasing





# v1.2.0 - 2025-07-18

* **STAM Core**
   * Added `Map` type for data values. Arbitrary nested maps are now supported but should *NOT* be used as a substitute for annotations on annotations [#34](https://github.com/annotation/stam/issues/34)
   * Removed the constraint "Any String value that is a valid IRI SHOULD be interpreted as such in conversion from/to RDF", actual interpretation of IRIs vs string literals can now be delegated to the JSON-LD context.
* **STAM Query Language**
   * Added a `.` operator to get keys from maps (note that as an operator in STAMQL, is requires whitespace both left an right)
* **STAM Web Annotations**
   * Hierarchical structures can be mapped used the new `Map` type. Web Annotation targets and selectors that have no counterpart in STAM can now be encoded in this way.
   * JSON-LD context determines interpretation of IRIs vs string literals. The specification now makes clear how you can link to external resources using IRIs.
* **STAM Translate**
  * This is a minor new extension used to relate any texts, even if the text are not identical. It is a more generic and more limited form of the STAM transpositions.





# v1.1.1 - 2024-09-22

* Stricter definition of relative paths in `@include` mechanism, don't leave it to the implementation.





# v1.1.0 - 2024-08-29

* STAM Core:
         * Allow adding other annotations stores as dependencies (aka substores) [#29](https://github.com/annotation/stam/issues/29) 
         * Removed DataValue::Id (was never used)
         * Better documentation for public identifiers
* STAM Query Language:
         * Allow multiple subqueries [#28](https://github.com/annotation/stam/issues/28) 
         * Added LIMIT keyword [#25](https://github.com/annotation/stam/issues/25)
         * documented ADD and DELETE statements [#23](https://github.com/annotation/stam/issues/23) 
         * documentation improvements [#23](https://github.com/annotation/stam/issues/23)
* STAM Validation:
         * recommend either checksum or text based on text length
* STAM Transpose: Added "regsegmentation"
* STAM Web Annotations: updated and rephrased





# v1.0.0 - 2024-02-05

Formal first release of the STAM specification.

Implemented in stam-rust 0.9.0, stam-python 0.4.0, stam-tools 0.4.0.


