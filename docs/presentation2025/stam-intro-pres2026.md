---
title: "STAM: Stand-off annotatie op tekst -- een intro"
author: Maarten van Gompel
date: "February 2026"
institute: KNAW Humanities Cluster
fontsize: 11pt
urlcolor: blue
titlegraphic: ../presentation/logo.png
---

## Inleiding

1. **Wat is STAM?**
2. **Hoe gebruiken we STAM in Team Text?**
3. **Hoe kan STAM voor anderen nuttig zijn?**

## Wat is STAM?

1. Een **data model** voor het representeren van **annotatie** op **tekst**
    * op een **stand-off** manier
2. Een verzameling fundamentele **software tools** om met **stand-off annotatie** op **tekst** te werken

*Theorie* & *Praktijk* gaan hand in hand, STAM biedt de fundering waar je verder op kan bouwen.

**Project website: <https://annotation.github.io/stam>**

--------

![STAM ecosystem](stam-ecosystem.png)

--------

## Eigenschappen van het datamodel

* STAM is een **op-zichzelf-staand** model om annotatie op tekst uit te drukken.
* Het model is redelijk **minimalistisch** en uitbreiding zijn apart geformuleerd als **extensies**
    * Het kernmodel en extensies zijn vastgelegd in technische **specificaties** (onafhankelijk van implementatie)
    * Daarnaast zijn ze **geïmplementeerd** in onze tooling
* Het model is niet gebonden aan bepaald **vocabulaire** (de inhoud van de annotaties)
* Het is niet gebonden aan één bepaald bestandsformaat.

## Motivatie

Er was behoefte aan een simpel model met tooling om allerlei basale berekeningen te doen
die bij annotatie op tekst komen kijken.

* Hoe verhouden verschillende annotaties zich tot elkaar in de ruimte? (bv overlap)
* Hoe kan je snel en efficiënt zoeken in annotaties en in tekst?
* Omrekenen tussen verschillende relatieve en absolute coordinatensystemen
* Hoe implementeer je dit met efficiënt geheugengebruik

**Inspiratie:**

* *Text Fabric* (Dirk Roorda)
* *W3C Web Annotations*
* *FoLiA XML*

## Het kernmodel

--------

![Annotaties staan centraal](../presentation/slide1.png)

--------

![Annotatiedata en selectoren](../presentation/slide3b.png)

----

## Implementaties & Interfaces

**Implementaties en interfaces**:

* `stam-rust`: een Rust library die het kernmodel en alle extensies implementeert.
* `stam-tools`: command line tools om met STAM te werken
    * unix principe:  één tool (subcommand) voor één ding
* `stam-python`: een Python-binding om `stam-rust` en `stam-tools`
    * handig voor ontwikkelaars en data scientists
* `stamd`: een webservice laag om `stam-rust` en `stam-tools`

**Voor wie?** Alle tools fungeren als **bouwstenen** voor een technisch publiek.

Alle implementaties zijn in Rust geschreven

![STAM ecosystem](stam-ecosystem.png)

## Wat doet Team Text ermee?

STAM vervult een belanrijke rol aan het begin van onze data-conversie pipeline:

met STAM tools ....

* ... **untanglen** we corpusdata in bv TEI of PageXML naar *plain text* en *stand-off annotaties* (`stam fromxml`)
* ... **normaliseren** we teksten (denk aan hyphenatie) (`stam translatetext`)
* ... **herberekenen** we annotaties op oorspronkelijke teksten naar annotaties op genormaliseerde teksten (`stam translate`)
* ... **exporteren** we annotaties naar **W3C Web Annotaties** voor *Annorepo* (`stam export`)
    * (de plain text gaar naar *Textsurf*)

-------------

In projecten als Globalize:

* ... **aligneren** we varianten van teksten (`stam align`)

-----

![A translation resulting from alignment, given two similar texts](../../extensions/stam-translate/translation3.png)

## Wat kan je er verder mee?

* Import en exportfunctionaliteit vanuit verschillende dataformaten
* Zoeken in tekst (`stam grep`) en tagging (`stam tag`)
* Uitgebreide query taal om te zoeken (**STAMQL**):

![A STAMQL query for adjective-noun word pairs](query3.png)

* Simpele HTML **visualisaties**:

![STAM HTML visualisation (``stam query -F html``)](stamvis.png)

* Validatie

## Conclusie

**STAM** ...

* ... biedt een **sterke generieke basis** waarom je verdere applicaties kan bouwen
        die iets doen met annotatie op tekst.
* ... is **modulair**; kies en gebruik de delen die je nodig hebt voor je taak
* ... is **flexibel**; jij kiest hoe je je data modelleert en brengt je **eigen vocabulaire** mee.
* ... regelt al **het rekenkundige basiswerk** zodat jij dat niet hoeft te doen
* ... biedt **interfaces** voor diverse *technische* **gebruikersgroepen**
* ... heeft een focus op **performance**, implementaties zijn in Rust geschreven
* ... is **open source software** (GNU General Public License v3) 
* ... > 40k regels Rust code, > 1500 ontwikkeluren, sinds january 2023
      (funding grotendeels via CLARIAH)

## Fin

**Verdere informatie:** Project website -- <https://annotation.github.io/stam>

* STAM Specificatie & Extensie specificaties
* Library API References (Rust & Python)
* Python tutorial "Standoff Text Annotation for Pythonistas"  (Jupyter Notebook)
* Screencast video voor stam-tools
* Poster
* Deze slides

![Project website - https://annotation.github.io/stam](qr.png)
