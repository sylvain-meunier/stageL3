#import "@preview/lemmify:0.1.5": *

#let th = counter("theorem")
#th.update(1)

#let (
  theorem, lemma, corollary,
  remark, proposition, example,
  proof, definition, rules: thm-rules
) = default-theorems("thm-group", lang: "en", thm-numbering: a => [#th.step() #th.display()])

#show: thm-rules

= 
== a

== b

=
==

#definition[Coucou]
#definition[Coucou]
#definition[Coucou]
#definition[Coucou]
#definition[Coucou]