#import "@preview/charged-ieee:0.1.0": ieee
#import "@preview/glossarium:0.4.1": make-glossary, print-glossary, gls, glspl
#show: make-glossary
#show link: set text(fill: blue.darken(60%))
#set page(numbering: "1")
#show: ieee.with(
  title: [Numerical sheet music analysis,\ L3 intership (CNAM / INRIA)\ 27/05/24 - 02/08/24],
  authors: (
    (
      name: "Sylvain Meunier (intern)",
      email :"sylvain.meunier@ens-rennes.fr",
    ),
    (
      name: "Florent Jacquemard (supervisor)",
      email :"florent.jacquemard@inria.fr",
    ),
  ),
  index-terms: ("Computer Science", "CS", "MIR", "Music Information Retrieval"),
  bibliography: bibliography("refs.bib"),
  paper-size:"a4",
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
- a justified proposition for a formal definition of tempo based on @raphael_probabilistic_2001, @kosta_mazurkabl:_2018 and @hu_batik-plays-mozart_2023 ; and some immediate consequences
- a modification of @large_dynamics_1999 and @schulze_keeping_2005
- an extension of @romero-garcia_model_2022, to fit tempo estimation
- generated data based on @foscarin_asap:_2020 and @peter_automatic_2023



= Score-based approaches

== Formal considerations

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

With those definitions, let us formally define tempo $T(t)$ so that, for all $n in NN$, $integral_(t_0)^(t_n) T(t) dif t = b_n - b_0$.\
@ann1 shows that this definition is equivalent to : $forall n in NN, integral_(t_n)^(t_(n+1)) T(t) dif t = b_(n+1) - b_n$.
However, tempo is only tangible (or observable) between two events _a priori_. We will then define the canonical tempo $T^*(t)$ so that :\
$forall x in RR^+, forall n in NN, x in bracket t_n, t_(n+1) bracket => T^*(x) = (b_(n+1) - b_n) / (t_(n+1) - t_n)$.\
The reader can verify that this function is a formal tempo according to the previous definition. From now on, we will consider the convention : $t_0 = 0 "(s)"$ et $b_0 = 0 "(beat)"$.\

Even though there is a general consensus in the field as for the interest and informal definition of tempo, several formal definitions coexist within litterature : @shibata_non-local_2021 and @nakamura_stochastic_2015 take $1 / T^*$ as definition ; @raphael_probabilistic_2001, @kosta_mazurkabl:_2018 et @hu_batik-plays-mozart_2023 choose similar definitions than the one given here (approximated at the scale of a  @measure or a section for instance).\

$T^*$ has the advantage to coincide with the tempo actually indicated on traditional sheet music (and therefore on .music_xml format), hence allowing a simpler and more direct interpretation of results.

== Naive use of formalism

As said in introduction, the more formatted data, the less accessible it is ; and the field contains only a few datasets containing both sheet music and corresponding audio, more or less anotated with various labels #cite(<kosta_mazurkabl:_2018>, form:"normal")
#cite(<hentschel_annotated_2021>, form:"normal")
#cite(<hu_batik-plays-mozart_2023>, form:"normal")
#cite(<foscarin_asap:_2020>, form:"normal")
#cite(<peter_automatic_2023>, form:"normal").\

In our study, we chose to rely on the (n)-ASAP dataset #cite(<peter_automatic_2023>, form:"normal") that presents a vast amount of performances, with over 1000 different pieces of classical music, all note-aligned with the corresponding score. From there, we can easily compute our definition of tempo. @naive_curve presents the results for a specific piece of the (n)-ASAP dataset with a logarithmic y-scale, that contains a few brutal tempo change, whilst maintaining a rather stable tempo value in-between.

\
#figure(
  image("../Figures/naive_version.png", width: 100%),
  caption: [
    Tempo curve for a performance of Islamey, Op.18, M. Balakirev with naive algorithm
  ],
) <naive_curve>

In this graph, one can notice how $T^*$ (plotted as little dots) appears noisy over time; even though allowing to distinguish a tempo change at $t_1 = 130$ s and $t_2 = 270$ s. Both the sliding window average (dotted line) and median (full line) of $T^*$ seem unstable, presenting undesirable peaks, whereas the "feeled" tempo is quite constant for the listener, although the median line is a bit more stable than the average line, as expected. There are two explanation for those results. First, fast events are harder to play exactly on time, and the very definition being a ratio with a small theorical value as the denominator explains the deviation and absurd immediate tempo plotted. In fact, we can read that about 10 points are plotted over 400 BPM (keep in mind that usual tempo are in the range 40 - 250 BPM). Second, the notion of timing and tempo are mixed together in this computation, hence giving results that do not match the listener feeling of a stable tempo.  Actually, timing can be seen as little modifications to the "official" score, and using the resulting score would allow for curves that fit better the listener feeling, though needing an actual transcription of the performance first.

== Physical models

Among the tasks needing tempo estimation, the problem of real time estimation to allow a dedicated machine to play an accompagnement by following at least one real musician has been tackled by various approaches in litterature. @raphael_probabilistic_2001 started with a probabilistic model, but those methods have found themselves replaced by a more physical understanding of tempo _via_ the notion of internal pulse, as explained by @large_dynamics_1999. In fact, their method has recently been developped to a commercial form #footnote[https://metronautapp.com/], based on an a previous adaption by @antescofo.\ \

The approach developped by @large_dynamics_1999 consider a simplified neurological model, where listening is a fundamentally active process, implying a synchronization between external events (those of the performance) and an internal oscillator, whose complexity depends of hypothesis on the shape of the first ones. The model consists of two equations for the internal parameters:\
#let eq1 = nb_eq[$Phi_(n+1) = [Phi_n + (t_(n+1) - t_n) / p_n - eta_Phi F(Phi_n)] mod_"[-0.5, 0.5[" 1$];
#eq1 <large1>
#nb_eq[$p_(n+1) = p_n (1 + eta_p F(Phi_n))$] <large2>
Here, $(Phi_n)$ corresponds to the phase, or rather the phase shift between the oscillator and the external events, and $(p_n)$ embodies its period. Finally, $eta_p$ and $eta_Phi$ are both constant parameters. This initial model is then modified to consider a notion of attending _via_ the $kappa$ parameter, whose value change over time according to other equations. The new model contains the same formulas, with the following definition for $F$\
$F : Phi, kappa -> exp(kappa cos(2pi Phi)) / exp(kappa) sin(2pi Phi)/(2 pi)$.\

Even though this model shows pretty good results, has been validated through some experiments in #cite(<large_dynamics_1999>, form:"normal"), and is still used in the previously presented version (@large_dynamic_2023), a theorical study of the system behavior remains quite complex, even in simplified theorical cases #cite(<schulze_keeping_2005>, form:"normal"), notably because of the  function $F$ expression.\

In order to simplify the model, @schulze_keeping_2005 present _TimeKeeper_, that can be seen as a simplification of the previous approach, valid in the theorical framwork of a metronome presenting small tempo variations. Actually, the two models are almost equivalent under specific circumstances, as shown by @loehr_temporal_2011.\
\

@large_curve displays the results of the two previous models, and the canonical, or immediate tempo. One can notice the salient stability of @large_dynamics_1999 model.

#figure(
  image("../Figures/naive_version.png", width: 100%),
  caption: [
    Tempo curve for a performance of Islamey, Op.18, M. Balakirev according to various models
  ],
) <large_curve>

[Potential quick curve analysis]

=== LargeKeeper

Un premier objectif a été de fusionner les approches de @large_dynamics_1999 et @schulze_keeping_2005 afin d'essayer d'obtenir des garanties théoriques sur le modèle résultant. On montre en @ann1 que l'on obtient alors le système composé des deux équations suivantes :\
#eq1
#nb_eq[$p_(n+1) = p_n 1 / (1 - (p_n eta_Phi F(Phi_n, kappa_n)) / (t_(n+1) - t_n))$] <largekeeper>\
On notera que ce modèle a l'avantage de contenir un paramètre de moins que celui de Large.
On remarque également que, pour $Delta_t = t_(n+1) - t_n >> p_n eta_Phi F(Phi_n, kappa_n)$ dans @largekeeper, on obtient :
$p_(n+1) = p_n (1 + p_n / Delta_t eta_Phi F(Phi_n, kappa_n))$. Quitte à poser $eta_p = p_n / Delta_t eta_Phi$ on retrouve @large2.\
Les modèles sont donc équivalents sous ces conditions. En pratique (voir @ann2), on obtient des résultats très similaires à @large_dynamics_1999, avec un paramètre constant en moins. Bien que ce modèle n'offre guère plus de garanties _a priori_ que @large_dynamics_1999, il est toutefois nettement plus aisé d'en faire l'analyse par rapport à un tempo canonique. On peut ainsi montrer  que : #nb_eq[$alpha_(n+1) &= (alpha_n - eta_Phi F(Phi_n) / (Delta b_n)) T_n^* / (T_(n+1)^*) \
&= alpha_n T_n^* / T_(n+1)^* - eta_Phi F(Phi_n) / ( Delta t_n T_(n+1)^*)$]
où $forall n in NN, alpha_n = T_n / T_n^*$.\
Par ailleurs, on montre en @ann2 que ce modèle possède les mêmes garanties théoriques que @large_dynamics_1999 dans une situation idéalisée simple.
  

= Scoreless approaches

== principe: SoA quantification rythmique MIDI 
  2 papier
== approche estimateur : évite le problème de convergence de Large
== approche quantifiée "spectrale" à la Gonzalo
  - LR
  - bidi (2 passes: LR + RL) : justification : retour à la définition formelle de Tempo : valide dans les deux sens, d'où la possibilité de le faire en bidirectionnel
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

== LargeKeeper
On cherche ici à déterminer une équation pour la période, en fusionnant les modèles @large_dynamics_1999 et @schulze_keeping_2005.
On reprend donc l'équation de la phase donnée par @large_dynamics_1999 : EQ1

On cherche à calculer : $T_n = 1 / p_n = (Phi_(n+1) - Phi_n) / (t_(n+1) - t_n)$
On considérant $Phi_n$ comme le déphasage entre l'oscillateur de période $p_n$ et un oscillateur extérieur...\
$"On a :" Phi_(n+1) - Phi_n &= (Delta t_n) / p_n - eta_Phi F(Phi_n) \
&= T_n Delta t_n - eta_Phi F(Phi_n) \
&= T_n (b_(n+1) - b_n) / T_n^* - eta_Phi F(Phi_n) \
&= Delta b_n T_n / T_n^* - eta_Phi F(Phi_n)$

= Annexe B <ann2>

= Annexe C <gonzalo_spectre>

Posons tout d'abord quelques fonctions utiles.\
On définit : $g : x |-> min(x - floor(x), 1 + floor(x) - x)$\
On peut vérifier que $g : x |-> cases(x  - floor(x) "si" x  - floor(x) <= 1/2, 1 - (x - floor(x)) "sinon")$ et que $g$ est 1-périodique continue sur $RR$.\

Ainsi, on a : $epsilon_T (a) = max_(t in T) g(t/a)$, donc en particulier, $epsilon_T$ est continue sur $R^*_+$.

On remarque de plus, pour $n in NN^*, T subset (RR^*_+)^n, a in R^*_+ : epsilon_T (a) = a epsilon_(T \/ a) (1)$. Hence the intuitive following result : the smaller the tatum, the smaller the bound of the error.

== Caractérisation des maximums locaux

== Caractérisation des minimums locaux



Par continuité de $epsilon_T$, on est assuré de l'existence d'exactement un unique minimum local entre deux maximums locaux, qui est alors global sur cet intervalle.\
Par la condition nécessaire précédente, il suffit donc, pour déterminer ce minimum local, de déterminer le plus petit élément parmi les points obtenus, contenus dans l'intervalle.\
On en déduit ainsi un algorithme en $cal(O)(\# T^2 t^* / tau log(\# T t^* / tau))$ permettant de déterminer tous les minimums locaux accordés par le seuil $tau$ fixé, sur l'intervalle $]2 tau, t_* + tau[$

= Glossary
#print-glossary(show-all:false,
    (
    (key: "mir", short: "MIR", long:"Music Information Retrieval", group: "Acronyms", desc:[#lorem(10)]),

    (key:"tempo",
    short: "tempo",
    desc:[\ Défini formellement p. 2 selon la formule : $T_n^"*" = (b_(n+1) - b_n) / (t_(n+1) - t_n)$. Informellement, le tempo est une mesure la vitesse instantanée d'une performance, souvent indiqué sur la partition. On peut le voir comme le rapport entre la vitesse symbolique supposée par la partition, et la vitesse réelle d'une performance. Le tempo est usuellement indiqué en @beat par minute, ou bpm],
    group:"Definitions"),

    (key:"beat", short:"beat",
    desc:[\ Unité de temps d'une partition, le beat est défini par une signature temps, ou division temporelle. Bien que sa valeur ne soit _a priori_ pas fixe d'une partition à une autre, ni même sur une même partition, la notion de beat est en général l'unité la plus pratique quant à la description d'un passage rythmique, lorsque la signature temps est adéquatement définie.],
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
      key:"phrase",
      short:"phrase",
      desc:[A musical phrase is defined similarly as a sentence in formal speech, usually depicting a single idea with clear punctuation. In this analogy, @cadence act as a dots or comas within or in-between the phrases.],
      group:"Definitions"
    ),

    (
      key:"chord",
      short:"chord",
      desc:"A chord is by definition the simultaneous production of at least three musical events with different pitches",
      group:"Definitions"
    ),

    (
      key:"rest",
      short:"rest",
      desc:"A symbolic notation for silence, following the same rules as actual note notations.",
      group:"Definitions"
    ),

    (
      key:"poly",
      short:"polyphonic",
      desc:"Describes a music containing multiple independant voices.",
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
      desc:[describes how a specific note is played by the performer. For instance, _staccato_ means the note shall not be maintained, and instead last only a few musical units, depending on the context. On the other hand, a fermata (_point d'orgue_ in French) indicates that the note should stay longer than indicated, to the performer's discretion.],
      group:"Definitions"
    ),

    (
      key:"velocity",
      short:"velocity",
      desc:"The velocity describes how loud a sound shall be played, or is actually played.",
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