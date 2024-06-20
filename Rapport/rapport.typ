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
Nous présentons ici quelques résultats obtenus autour de la notion de #gls("tempo") en informatique musicale, ou @mir, notamment dans le domaine d'estimation du #gls("tempo"). En ce qui concerne le temps réel, l'une des problèmatiques les plus saillante est celle de l'accompagnement automatique d'un soliste @raphael_probabilistic_2001 @antescofo. L'objectif d'un tel modèle est alors de synchroniser la lecture d'une partition par une machine avec le jeu d'au moins un humain. Récemment, une approche reprenant @antescofo a été développé pour un usage commercial. #footnote[https://metronautapp.com/]


= Estimation du tempo

== Présentation du formalisme utilisé

On dispose de deux façons principales de représenter une performance informatiquement : un fichier audio brute en format .wav par exemple, ou bien un fichier midi plus symbolique. Afin de simplifier les algorithmes, nous ne considèrerons ici que des entrées sous forme de fichiers midi. On modélise alors une performance comme une suite strictement croissante d'évènements $(t_n)_(n in NN)$, dont chaque élément indique la date de l'évènement associé. Cette modélisation coïncide presque avec le contenu d'un fichier midi.
Pour des considérations pratiques, on regroupera ensemble les évènements distants dans le temps de $epsilon = 20 "ms"$, ordre de grandeur calculé par @nakamura_outer-product_2014 dont la valeur correspond à la limite de la capacité humaine à distinguer deux évènements rythmiques. Cet ordre de grandeur est largement utilisé dans le domaine @nakamura_performance_2017 @foscarin_asap:_2020 @peter_automatic_2023 @hu_batik-plays-mozart_2023 @kosta_mazurkabl:_2018 @hentschel_annotated_2021 @romero-garcia_model_2022 @shibata_non-local_2021.
De façon similaire, on modélise une partition comme une suite strictement croissante d'évènements $(b_n)_(n in NN)$. On notera que dans ces deux définitions, les éléments de la suite indique certes un évènement, mais pas sa nature. Il peut donc notamment s'agir d'un accord, d'une note seule, ou d'un silence. En termes d'unité, on notera que $(t_n)$ désigne des dates réelles, en secondes par exemple ; alors que $(b_n)$ désigne des dates théoriques, exprimées en @beat, unité de temps musicale.
On peut alors définir formellement le tempo $T(t)$ de sorte que, pour tout $n in NN$, $integral_(t_0)^(t_n) T(t)"dt" = b_n - b_0$.\
On montre en @ann1 que cette définition est équivalente à : $forall n in NN, integral_(t_n)^(t_(n+1)) T(t) "dt" = b_(n+1) - b_n$.\
Or, le tempo n'est tangible (ou observable) qu'entre deux évènements _a priori_. On définira donc le tempo canonique $T^*(t)$ de sorte que :\
$forall x in RR^+, forall n in NN, x in bracket t_n, t_(n+1) bracket => T^*(x) = (b_(n+1) - b_n) / (t_(n+1) - t_n)$.\
On peut alors s'assurer que cette fonction respecte bien la condition énoncée précédemment. Par convention, on prendra dans la suite de ce rapport : $t_0 = 0$ et $b_0 = 0$.\

Si le domaine présente un consensus global quant à l'intérêt et la définition informelle de tempo, de multiples définitions formelles coexistent dans la littérature : @shibata_non-local_2021 et @nakamura_stochastic_2015 prennent pour définition $1 / T^*$ ; @raphael_probabilistic_2001, @kosta_mazurkabl:_2018 et @hu_batik-plays-mozart_2023 choisissent des définitions proches de celle donnée ici (plus ou moins approximée à l'échelle d'une @mesure ou d'une @section par exemple). $T^*$ a l'avantage de coïncider avec le tempo indiqué sur une partition, et donc de permettre une interprétation plus directe des résultats. Par ailleurs, nous avons déjà présenté une justification de la formule permettant de calculer le tempo canonique.

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

Si ce modèle se comporte très bien en pratique, a été validé par l'expérience dans @large_dynamics_1999, et reste encore utilisé dans la version présentée ici @large_dynamic_2023, l'étude théorique du comportement du système n'en est pas aisée @schulze_keeping_2005, même dans des cas simples, notamment en raison de l'expression de la fonction $F$.

=== TimeKeeper

Dans un soucis de simplification du modèle, @schulze_keeping_2005 présente TimeKeeper, qui peut être perçu comme une simplification de l'approche précédente, valide dans le cadre théorique d'un métronome présentant de faibles variations de tempo. On peut toutefois voir une presque équivalence entre les deux modèles @loehr_temporal_2011. On montre en figure XXX une comparaison dans différents contextes des trois approches citées jusqu'à présent, où on note une stabilité saillante du modèle d'oscillateur. 

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
      key: "tatum",
      short: "tatum",
      group:"Définitions",
      desc:[Résolution minimal d'une unité musicale, exprimé en beat. Bien que de nombreuses valeurs soit possible, la définition formelle d'un tatum serait la suivante : $sup {r | forall n in NN, exists k in NN : b_n = k r, r in RR_+^*}$. Pour des raisons pratiques, il arrive que le tatum soit un élément plus petit que la définition donnée, en particulier si cet élément est plus facilement expressible dans une partition, ou a plus de sens d'un point de vue musical. On notera dans la définition de l'ensemble donnée, k n'a pas d'unité, ce qui montre clairement que le tatum s'exprime en beat comme dit précédemment.]
    ),

    (
      key:"timesig",
      short:"signature de temps",
      desc:"",
      group:"Définitions"
    ),

    (
      key:"cadence",
      short:"cadence",
      desc:"",
      group:"Définitions"
    ),

    (
      key:"section",
      short:"section",
      desc:"",
      group:"Définitions"
    ),

    (
      key:"phrase",
      short:"phrase",
      desc:"",
      group:"Définitions"
    ),

    (
      key:"mesure",
      short:"mesure",
      desc:[Une mesure est une unité de temps musicale, contenant un certain nombre (entier) de beat. Ce nombre est indiqué par la @timesig],
      group:"Définitions"
    ),
  )
)