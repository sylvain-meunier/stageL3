#import "@preview/charged-ieee:0.1.0": ieee
#import "@preview/glossarium:0.4.1": make-glossary, print-glossary, gls, glspl
#show: make-glossary
#show link: set text(fill: blue.darken(60%))
#show: ieee.with(
  title: [Analyse de partitions musicales numériques\ Rapport de stage L3\ 27/05 - 02/08],
  authors: (
    (
      name: "Sylvain Meunier",
      email :"sylvain.meunier@ens-rennes.fr",
    ),
  ),
  index-terms: ("Computer Science", "CS", "MIR", "Music Information Retrieval"),
  bibliography: bibliography("refs.bib"),
)

#let nb_eq(content) = math.equation(
    block: true,
    numbering: "(1)",
    content,
)

#let appendix(body) = {
  set heading(numbering: "A", supplement: [Annexe])
  counter(heading).update(0)
  body
}

= Introduction
Nous présentons ici quelques résultats obtenus autour de la notion de #gls("tempo") en informatique musicale, ou @mir, notamment dans le domaine d'estimation du #gls("tempo") [INSERT HERE OTHER CONTRIBUTIONS]


= Estimation du tempo

== Présentation du formalisme utilisé

On dispose de deux façons principales de représenter une performance informatiquement : un fichier audio brute en format .wav par exemple, ou bien un fichier midi plus symbolique. Nous avons choisi de ne considérer que des fichiers midi par simplicité. On modélise alors une performance comme une suite strictement croissante d'évènements $(t_n)_(n in NN)$, dont chaque élément indique la date de l'évènement associé. Cette modélisation coïncide presque avec le contenu d'un fichier midi.
Pour des considérations pratiques, on regroupera ensemble les évènements distants dans le temps de $epsilon = 20 "ms"$, constante utilisée dans le domaine cf asap. La valeur obtenue par [CITER ICI LE PAPIER QUI LA CALCULE (NAKAMURA)] correspond à la limite de la capacité à distinguer deux évènements rythmiques par un être humain.
De façon similaire, on modélise une partition comme une suite strictement croissante d'évènements $(b_n)_(n in NN)$. On notera que dans ces deux définitions, les éléments de la suite indique certes un évènement, mais pas sa nature. Il peut donc notamment s'agir d'un accord, d'une note seule, ou d'un silence. En termes d'unité toutefois, on notera que $(t_n)$ désigne des dates réelles, en secondes par exemple ; alors que $(b_n)$ désigne des dates théoriques, exprimées en @beat, unité de temps musicale.
On peut alors définir formellement le tempo $T(t)$ de sorte que, pour tout $n in NN$, $integral_(t_0)^(t_n) T(t)"dt" = b_n - b_0$.\
On montre en @ann1 que cette définition est équivalente à : $forall n in NN, integral_(t_n)^(t_(n+1)) T(t) "dt" = b_(n+1) - b_n$.\
Or, le tempo n'est tangible qu'entre deux évènements _a priori_. On définira donc le tempo canonique $T^*(t)$ de sorte que :\
$forall x in RR^+, forall n in NN, x in bracket t_n, t_(n+1) bracket => T^*(x) = (b_(n+1) - b_n) / (t_(n+1) - t_n)$.\
On peut alors s'assurer que cette fonction respecte bien la condition énoncée précédemment.\
Par convention, on aura dans la suite de ce rapport : $t_0 = 0$ et $b_0 = 0$.\

== Approche naïve
Etant donné ce formalisme, on peut alors construire un algorithme glouton calculant le #gls("tempo") entre les instants $n$ et $n+1$ d'une performance lorsque la partition est connue, selon la formule : $T_n^* = (b_(n+1) - b_n) / (t_(n+1) - t_n)$, dont le lecteur peut s'assurer de l'homogénéité.\
On donne en figure 1 quelques résultats donnés par cette approche dans différentes situations :
- situation théorique parfaite
- situation réelle approchant une situation théorique, par l'ajout de perturbations
- situation réelle (sur Mozart, nom_de_loeuvre)

== Approches existantes
=== Large et Jones

L'approche de Large et Jones @large_dynamics_1999 considère un modèle neurologique simplifié, dans lequel l'écoute est fondamentalement active, et implique une synchronisation entre des évènements extérieurs (la performance) et un oscillateur interne, plus ou moins complexe selon la forme supposée de ces premiers. Le modèle consiste en deux équations pour les paramètres internes :\
#let eq1 = nb_eq[$Phi_(n+1) = [Phi_n + (t_(n+1) - t_n) / p_n - eta_Phi F(Phi_n)] mod 1$];
#eq1 <large1>
#nb_eq[$p_(n+1) = p_n (1 + eta_p F(Phi_n))$] <large2>
Ici, $Phi_n$ correspond à la phase, ou plutôt ou déphasage entre l'oscillateur et les évènements extérieurs, et $p_n$ désigne sa période.\
Ce modèle initial est ensuite revu pour y incorporer une notion d'attention _via_ le paramètre $kappa$, non constant au cours du temps. Les formules restent alors les mêmes, en remplaçant $F$ par $F : Phi, kappa -> exp(kappa cos(2pi Phi)) / exp(kappa) sin(2pi Phi)/(2 pi)$\

Si ce modèle se comporte très bien en pratique, a été validé par l'expérience dans @large_dynamics_1999, et reste encore utilisé dans la version présentée ici @large_dynamic_2023, l'étude théorique du comportement du système n'en est pas aisée, même dans des cas simples, notamment en raison de l'expression de la fonction $F$.

=== TimeKeeper

@loehr_temporal_2011

== Contributions
=== BeatKeeper

Un premier objectif a été de fusionner les approches de @large_dynamics_1999 et @loehr_temporal_2011 afin d'essayer d'obtenir des garanties théoriques sur le modèle résultant. On montre en @ann1 que l'on obtient alors le système composé des deux équations suivantes :\
#eq1
#nb_eq[$p_(n+1) = p_n 1 / (1 - (p_n eta_Phi F(Phi_n, kappa_n)) / (t_(n+1) - t_n))$] <beattracker>\
On remarque que, pour $Delta_t = t_(n+1) - t_n >> p_n eta_Phi F(Phi_n, kappa_n)$ dans @beattracker, on obtient :
$p_(n+1) = p_n (1 + p_n / Delta_t eta_Phi F(Phi_n, kappa_n))$. Quitte à poser $eta_p = p_n / Delta_t eta_Phi$ on retrouve @large2.\
Les modèles sont donc équivalents sous ces conditions. En pratique (voir @ann2), on obtient des résultats très similaires à @large_dynamics_1999, avec un paramètre constant en moins. Cependant, ce modèle n'offre guère plus de garanties _a priori_ que @large_dynamics_1999.

=== TempoTracker

Après l'approche précédente, 

= Applications

#show : appendix
= Annexe A <ann1>

== Equivalence des définitions du tempo

Soit $n in NN$, on a :\
$integral_(t_0)^(t_(n)) T(t) "dt" = sum_(i = 0)^(n-1) integral_(t_i)^(t_(i+1)) T(t)"dt"$\
De plus, $integral_(t_n)^(t_(n+1)) T(t) "dt" = integral_(t_0)^(t_(n+1)) T(t)"dt" + integral_(t_n)^(t_0) T(t) "dt" = integral_(t_0)^(t_(n+1)) T(t)"dt" - integral_(t_0)^(t_n) T(t) "dt"$.\
On obtient ainsi les deux implications.

== BeatKeeper
On cherche ici à déterminer une équation pour la période, en fusionnant les modèles @large_dynamics_1999 et @loehr_temporal_2011.
On reprend donc l'équation de la phase donnée par @large_dynamics_1999 :
#eq1

On cherche à calculer : $T_n = 1 / p_n = (Phi_(n+1) - Phi_n) / (t_(n+1) - t_n)$
On considérant $Phi_n$ comme le déphasage entre l'oscillateur de période $p_n$ et un oscillateur extérieur

= Annexe B <ann2>

= Glossaire
#print-glossary(show-all:true,
    (
    // minimal term
    (key: "mir", short: "MIR", long:"Music Information Retrieval", group: "Acronymes", desc:[#lorem(10)]),

    // a term with a short plural 
    (
      key: "potato",
      short: "potato",
      // "plural" will be used when "short" should be pluralized
      plural: "potatoes",
      desc: [#lorem(10)],
    ),

    (key:"tempo",
    short: "tempo",
    desc:[\ Défini formellement p. 1 selon la formule : $T_n^"*" = (b_(n+1) - b_n) / (t_(n+1) - t_n)$. Informellement, le tempo est une mesure la vitesse instantanée d'une performance, souvent indiqué sur la partition. On peut le voir comme le rapport entre la vitesse symbolique supposée par la partition, et la vitesse réelle d'une performance. Le tempo est usuellement indiqué en @beat par minute, ou bpm],
    group:"Définitions"),

    (key:"beat", short:"beat",
    desc:[\ Unité de temps d'une partition, le beat est défini par une signature temps, ou division temporelle, rappelée au début de chaque système. Bien que sa valeur ne soit _a priori_ pas fixe d'une partition à une autre, ni même sur une même partition, la notion de beat est en général l'unité la plus pratique quant à la description d'un passage rythmique, lorsque la signature temps est adéquatement définie.],
    group:"Définitions"),

    (
      key: "dm",
      short: "DM",
      long: "diagonal matrix",
      // "longplural" will be used when "long" should be pluralized
      longplural: "diagonal matrices",
      desc: "Probably some math stuff idk",
    ),
  )
)