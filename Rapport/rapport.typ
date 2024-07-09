#import "@preview/charged-ieee:0.1.0": ieee
#import "@preview/glossarium:0.4.1": make-glossary, print-glossary, gls, glspl
#show: make-glossary
#show link: set text(fill: blue.darken(60%))
#show: ieee.with(
  title: [Numerical sheet music analysis,\ L3 intership (CNAM / INRIA)\ 27/05 - 02/08],
  authors: (
    (
      name: "Sylvain Meunier",
      email :"sylvain.meunier@ens-rennes.fr",
    ),
    (
      name: "Florent Jacquemard",
      email :"florent.jacquemard@inria.fr",
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
  set heading(numbering: "A", supplement: [Appendix])
  counter(heading).update(0)
  body
}

#set cite(form: "prose")

= Introduction

We present here some results regarding the analysis of tempo curve of musical performances, with score-based and scoreless approaches extending previously existing models.

The @mir community focus on three ways to compute musical information. The first one is raw audio, either recorded or generated, encoded in .wav or .mp3 files. The computation is based on a physical understanding of signals, using audio frames and spectrum, and represents the most common and accessible type of data. The second is a more musically-informed format, that indicates mainly two parameters : pitch (ie the note that the listener hear) and duration, encoded within a .mid (or MIDI) file. Such a file can be displayed as a piano roll, that is a graph whose x-axis is time and y-axis is pitch (hence, the y-axis is discrete).
The last way to encode musical information is the computed counterpart of sheet music. A sheet music is a way to write down a musical score, that is usually computed as a .music_xml file, mainly for display purposes. It comes with a *symbolic* and abstract notation for time, that only describes the length of events in relation to a specific abstract unit, called a @beat, and the pitch of each event. This kind of data is actually the least common and accessible.\

To actually play a sheet music, one needs a given @tempo, usually indicated as the amoung of beat per minute (BPM). Therefore, the notion of tempo allows to translate symbolic notation (expressed in musical unit, eg : beats) to real time events (expressed in real time unit, eg : seconds). We will discuss later on a formal definition of tempo.
However, tempo itself is insufficient to describe an actual performance of a sheet music, ie the sequence of real time events. Indeed, @peter2023sounding present four parameters, among which tempo and @articulation appear the most salient in contrast with @velocity and timing. The latter represents the delay between the theorical real time onset according to the current tempo, and the actual onset heared in the performance. Even though such a delay is inevitable for neurological and biological reasons, those timings are usually overemphasized and understood as part of the musical expressivity of the performance.\

In this study, we shall focus mainly on tempo estimation for a given performance recorded as a MIDI file, on both a local and global level.

= State of Art

Even though the community studies the four parameters, the hierarchy #cite(<peter2023sounding>, form:"normal") exposed embodies quite well the importance within the litterature. @Kosta2016Mapping present results pointing that, although velocities don't help to meaningfully estimate tempo, the latter allows to marginally upgrade velocity-related predictions. Actually, velocity appears to be more of a score parameter rather than a performance one : automatic learning methods trained on performances of a single piece showed much better results when asked to predict velocities employed by another performer on the same piece than when trained on other performances of the same performer.\

Tempo and related works actually hold a prominent place in litterature. Direct tempo estimation was first computed based on probabilistic models (@raphael_probabilistic_2001 @nakamura_stochastic_2015 #cite(<nakamura_outer-product_2014>, form:"normal")), and physical / neurological models (@large_dynamics_1999 @schulze_keeping_2005) ; before the community tried neural network models #cite(<Kosta2016Mapping>, form:"normal") and hybrids approaches (@shibata_non-local_2021). As the majority of previous examples, we shall focus here on mathematically and/or musically explainable methods.\

Since tempo needs a symbolic representation to be meaningful, one can consider transcription as a tempo-related work. We will keep this discussion for section V and VI.\

However, note-alignement, that is matching each note of a performance with those indicated by a given score is a very useful preprocessing technique, especially for direct tempo estimation and further analysis, such as #cite(<kosta_mazurkabl:_2018>, form:"normal") #cite(<hentschel_annotated_2021>, form:"normal") #cite(<hu_batik-plays-mozart_2023>, form:"normal"). Two main methods are to be found in litterature : a dynamic programming algorithm, equivalent to finding a shortest path (@muller_memory-restricted_nodate), that can works on raw audio (.wav files) ; and a Hidden Markov Model (@nakamura_performance_2017) that needs more formatted data, such as MIDI files.

In this report, we will present a few contributions :
- a justified proposition for a formal definition of tempo based on @raphael_probabilistic_2001, @kosta_mazurkabl:_2018 and @hu_batik-plays-mozart_2023 ; and some direct consequences
- a modification of @large_dynamics_1999 and @schulze_keeping_2005
- an extension of @romero-garcia_model_2022, to fit tempo estimation



= Score-based approaches

Since we chose to focus on MIDI files, we will represent a performance as a strictly increasing sequence of events $(t_n)_(n in NN)$, each element of whose indicates the onset of the corresponding performance event. Such a definition is very close to an actual MIDI representation.\

For practical considerations, we will stack together all events whose distance in time is smaller than $epsilon = 20 "ms"$. This order of magnitude, calculated by @nakamura_outer-product_2014 represents the limits of human ability to tell two rythmic events appart, and is widely used within the field #cite(<shibata_non-local_2021>, form:"normal") 
  #cite(<kosta_mazurkabl:_2018>, form:"normal")
  #cite(<hentschel_annotated_2021>, form:"normal")
  #cite(<hu_batik-plays-mozart_2023>, form:"normal")
  #cite(<nakamura_performance_2017>, form:"normal")
  #cite(<romero-garcia_model_2022>, form:"normal")
  #cite(<foscarin_asap:_2020>, form:"normal")
  #cite(<peter_automatic_2023>, form:"normal").\

Likewise, a sheet music will be represented as a strictly increasing sequence of events $(b_n)_(n in NN)$. In both of those definition, the terms of the sequence do not indicate the nature of the event (@chord, single note, @rest...). Moreover, in terms of units, $(t_n)$ corresponds to real onset, thus expressed in seconds, whereas $(b_n)$ corresponds to theorical or symbolic onsets, expressed in beats.\

With those definitions, let us then formally define tempo $T(t)$ so that, for all $n in NN$, $integral_(t_0)^(t_n) T(t) dif t = b_n - b_0$.\
@ann1 shows that this definition is equivalent to : $forall n in NN, integral_(t_n)^(t_(n+1)) T(t) dif t = b_(n+1) - b_n$.
However, tempo is only tangible (or observable) between two events _a priori_. We will then define the canonical tempo $T^*(t)$ so that :\
$forall x in RR^+, forall n in NN, x in bracket t_n, t_(n+1) bracket => T^*(x) = (b_(n+1) - b_n) / (t_(n+1) - t_n)$.\
The reader can verify that this function is a formal tempo according to the previous definition. From now on, we will consider the convention : $t_0 = 0 "(s)"$ et $b_0 = 0 "(beat)"$.\

Even though there is a general consensus in the field as for the interest and informal definition of tempo, several formal definitions coexist within litterature : @shibata_non-local_2021 and @nakamura_stochastic_2015 take $1 / T^*$ as definition ; @raphael_probabilistic_2001, @kosta_mazurkabl:_2018 et @hu_batik-plays-mozart_2023 choose similar definitions than the one given here (approximated at the scale of a  @measure or a @section for instance).\

$T^*$ has the advantage to coincide with the tempo actually indicated on traditional sheet music (and therefore on .music_xml format), hence allowing a simpler and more direct interpretation of results.

== version naïve

  - données (n)ASAP d'alignement
  - tempo brute
  - médiane fenêtre glissante

== modèles physiques 

  - Large: oscillateurs amortis
  - TimeKeeper
  - boom : LargeKeeper

  

= Scoreless approaches

== principe: SoA quantification rythmique MIDI 
  2 papier
== approche estimateur
== approche quantifiée "spectrale" à la Gonzalo
  - LR
  - bidi (2 passes: LR + RL)
  - RT : avec valeur initiale de tempo
== résultats évaluation (comparaison avec 3)



= Applications

- previous : metronaut, antescofo

- génération de données "performance" : pour data augmentation ou test robustesse (fuzz testing)
  aplanissement de tempo
  démo MIDI?

- transcription MIDI par parsing : pre-processing d'évaluation tempo (approche partie 4)



- analyse "musicologique" quantitative de performances humaines de réf. (à la Mazurka BL)
  données quantitives de tempo et time-shifts



- accompagnement automatique RT
  avec approche 4 RT ?



= Conclusion & perspectives

- intégration pour couplage avec transcription par parsing (+ plus court chemin multi-critère)
- lien approche partie 4 "spectrale" avec Large (amortisseur)
  modification modèle Large : résultat théorique de convergence

#show : appendix
=  Appendix A <ann1>

== Equivalence of tempo formal definitions

Let $n in NN$.
$integral_(t_0)^(t_(n)) T(t) dif t = sum_(i = 0)^(n-1) integral_(t_i)^(t_(i+1)) T(t) dif t$\
Furthermore, $integral_(t_n)^(t_(n+1)) T(t) dif t = integral_(t_0)^(t_(n+1)) T(t) dif t + integral_(t_n)^(t_0) T(t) dif t = integral_(t_0)^(t_(n+1)) T(t) dif t - integral_(t_0)^(t_n) T(t) dif t$.\
We thus obtain the two implications, hence the equivalence.

== BeatKeeper
On cherche ici à déterminer une équation pour la période, en fusionnant les modèles @large_dynamics_1999 et @loehr_temporal_2011.
On reprend donc l'équation de la phase donnée par @large_dynamics_1999 : EQ1

On cherche à calculer : $T_n = 1 / p_n = (Phi_(n+1) - Phi_n) / (t_(n+1) - t_n)$
On considérant $Phi_n$ comme le déphasage entre l'oscillateur de période $p_n$ et un oscillateur extérieur...\
$"On a :" Phi_(n+1) - Phi_n &= (Delta t_n) / p_n - eta_Phi F(Phi_n) \
&= T_n Delta t_n - eta_Phi F(Phi_n) \
&= T_n (b_(n+1) - b_n) / T_n^* - eta_Phi F(Phi_n) \
&= Delta b_n T_n / T_n^* - eta_Phi F(Phi_n)$

= Annexe B <ann2>

= Annexe C <ann3>

Posons tout d'abord quelques fonctions utiles.\
On définit : $g : x |-> min(x - floor(x), 1 + floor(x) - x)$\
On peut vérifier que $g : x |-> cases(x  - floor(x) "si" x  - floor(x) <= 1/2, 1 - (x - floor(x)) "sinon")$ et que $g$ est 1-périodique continue sur $RR$.\

Ainsi, on a : $epsilon_T (a) = max_(t in T) g(t/a)$, donc en particulier, $epsilon_T$ est continue sur $R^*_+$.

On remarque de plus, pour $n in NN^*, T subset (RR^*_+)^n, a in R^*_+ : epsilon_T (a) = a epsilon_(T \/ a) (1)$

== Caractérisation des maximums locaux

== Caractérisation des minimums locaux



Par continuité de $epsilon_T$, on est assuré de l'existence d'exactement un unique minimum local entre deux maximums locaux, qui est alors global sur cet intervalle.\
Par la condition nécessaire précédente, il suffit donc, pour déterminer ce minimum local, de déterminer le plus petit élément parmi les points obtenus, contenus dans l'intervalle.\
On en déduit ainsi un algorithme en $cal(O)(\# T^2 t^* / tau log(\# T t^* / tau))$ permettant de déterminer tous les minimums locaux accordés par le seuil $tau$ fixé, sur l'intervalle $]2 tau, t_* + tau[$

= Glossary
#print-glossary(show-all:true,
    (
    (key: "mir", short: "MIR", long:"Music Information Retrieval", group: "Acronyms", desc:[#lorem(10)]),

    (key:"tempo",
    short: "tempo",
    desc:[\ Défini formellement p. 1 selon la formule : $T_n^"*" = (b_(n+1) - b_n) / (t_(n+1) - t_n)$. Informellement, le tempo est une mesure la vitesse instantanée d'une performance, souvent indiqué sur la partition. On peut le voir comme le rapport entre la vitesse symbolique supposée par la partition, et la vitesse réelle d'une performance. Le tempo est usuellement indiqué en @beat par minute, ou bpm],
    group:"Definitions"),

    (key:"beat", short:"beat",
    desc:[\ Unité de temps d'une partition, le beat est défini par une signature temps, ou division temporelle, rappelée au début de chaque système. Bien que sa valeur ne soit _a priori_ pas fixe d'une partition à une autre, ni même sur une même partition, la notion de beat est en général l'unité la plus pratique quant à la description d'un passage rythmique, lorsque la signature temps est adéquatement définie.],
    group:"Definitions"),
    (
      key: "tatum",
      short: "tatum",
      group:"Definitions",
      desc:[Résolution minimal d'une unité musicale, exprimé en beat. Bien que de nombreuses valeurs soit possible, la définition formelle d'un tatum serait la suivante : $sup {r | forall n in NN, exists k in NN : b_n = k r, r in RR_+^*}$. Pour des raisons pratiques, il arrive que le tatum soit un élément plus petit que la définition donnée, en particulier si cet élément est plus facilement expressible dans une partition, ou a plus de sens d'un point de vue musical. On notera dans la définition de l'ensemble donnée, k n'a pas d'unité, ce qui montre clairement que le tatum s'exprime en beat comme dit précédemment.]
    ),

    (
      key:"timesig",
      short:"time signature",
      desc:"",
      group:"Definitions"
    ),

    (
      key:"cadence",
      short:"cadence",
      desc:"",
      group:"Definitions"
    ),

    (
      key:"section",
      short:"section",
      desc:"",
      group:"Definitions"
    ),

    (
      key:"phrase",
      short:"phrase",
      desc:"",
      group:"Definitions"
    ),

    (
      key:"chord",
      short:"chord",
      desc:"",
      group:"Definitions"
    ),

    (
      key:"rest",
      short:"rest",
      desc:"",
      group:"Definitions"
    ),

    (
      key:"poly",
      short:"polyphonic",
      desc:"",
      group:"Definitions"
    ),

    (
      key:"mono",
      short:"monophonic",
      desc:"",
      group:"Definitions"
    ),

    (
      key:"articulation",
      short:"articulation",
      desc:"",
      group:"Definitions"
    ),

    (
      key:"velocity",
      short:"velocity",
      desc:"",
      group:"Definitions"
    ),

    (
      key:"measure",
      short:"measure",
      desc:[Une mesure est une unité de temps musicale, contenant un certain nombre (entier) de beat. Ce nombre est indiqué par la @timesig],
      group:"Definitions"
    ),
  )
)