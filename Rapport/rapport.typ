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
  paper-size:"a4",
)

#show figure : set figure.caption (position: bottom)

#let nb_eq(content) = math.equation(
    block: true,
    numbering: "(1)",
    (content),
)

#let appendix(title, body) = {
  figure(
    kind: "appendix",
    supplement: [Appendix],
    caption: title,
    numbering: "A ",
    body,
  )
}

#show figure.where(kind: "appendix"): it => {
  set block(breakable: true)
  heading(numbering: none, text(12pt, it.caption))
  counter(heading).update(0)
  set heading(numbering: "I.a)1.")
  text(10pt, it.body)
}

#let argmin = math.op("argmin", limits: true)
#let argmax = math.op("argmax", limits: true)

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

In this report, we will present the following contributions :
- a justified proposition for a formal definition of tempo based on @raphael_probabilistic_2001, @kosta_mazurkabl:_2018 and @hu_batik-plays-mozart_2023 ; and some immediate consequences (#link(<formal_consider>)[III.A], #link(<naive_use>)[III.B])
- a revision of @large_dynamics_1999 and @schulze_keeping_2005 to fit a score-based approach (#link(<largmodif>)[III.C])
- a theorical framework for scoreless tempo estimation (#link(<estimator_intro>)[IV.B])
- an extension of @romero-garcia_model_2022, to fit tempo estimation, and associated theorical results and proofs (#link(<quanti>)[IV.D] and @gonzalo_spectre)
- generated data based on @foscarin_asap:_2020 and @peter_automatic_2023



= Score-based approaches

== Formal considerations <formal_consider>

Since we chose to focus on MIDI files, we will represent a performance as a strictly increasing sequence of events $(t_n)_(n in NN)$, each element of whose indicates the onset of the corresponding performance event. Such a definition is very close to an actual MIDI representation.\

For practical considerations, we will stack together all events whose distance in time is smaller than $epsilon = 20 "ms"$. This order of magnitude, calculated by @nakamura_outer-product_2014 represents the limits of human ability to tell two rythmic events appart, and is widely used within the field #cite(<shibata_non-local_2021>, form:"normal") 
  #cite(<kosta_mazurkabl:_2018>, form:"normal")
  #cite(<hentschel_annotated_2021>, form:"normal")
  #cite(<hu_batik-plays-mozart_2023>, form:"normal")
  #cite(<nakamura_performance_2017>, form:"normal")
  #cite(<romero-garcia_model_2022>, form:"normal")
  #cite(<foscarin_asap:_2020>, form:"normal")
  #cite(<peter_automatic_2023>, form:"normal")
  #cite(<murphy_quantization_2011>, form: "normal").\

Likewise, a sheet music will be represented as a strictly increasing sequence of events $(b_n)_(n in NN)$. In both of those definition, the terms of the sequence do not indicate the nature of the event (@chord, single note, @rest...). Moreover, in terms of units, $(t_n)$ corresponds to real onset, thus expressed in seconds, whereas $(b_n)$ corresponds to theorical or symbolic onsets, expressed in beats.\

With those definitions, let us formally define tempo $T(t)$ so that, for all $n in NN$, $integral_(t_0)^(t_n) T(t) dif t = b_n - b_0$.\
@ann1 shows that this definition is equivalent to : $forall n in NN, integral_(t_n)^(t_(n+1)) T(t) dif t = b_(n+1) - b_n$.
However, tempo is only tangible (or observable) between two events _a priori_. We will then define the canonical tempo $T^*(t)$ so that :\
$forall x in RR^+, forall n in NN, x in bracket t_n, t_(n+1) bracket => T^*(x) = (b_(n+1) - b_n) / (t_(n+1) - t_n)$.\
The reader can verify that this function is a formal tempo according to the previous definition. From now on, we will consider the convention : $t_0 = 0 "(s)"$ et $b_0 = 0 "(beat)"$.\

Even though there is a general consensus in the field as for the interest and informal definition of tempo, several formal definitions coexist within litterature : @shibata_non-local_2021 and @nakamura_stochastic_2015 take $1 / T^*$ as definition ; @raphael_probabilistic_2001, @kosta_mazurkabl:_2018 et @hu_batik-plays-mozart_2023 choose similar definitions than the one given here (approximated at the scale of a  @measure or a section for instance).\

$T^*$ has the advantage to coincide with the tempo actually indicated on traditional sheet music (and therefore on .music_xml format), hence allowing a simpler and more direct interpretation of results.

== Naive use of formalism <naive_use>

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
    Tempo curve for a performance of Islamey, Op.18, M. Balakirev, with naive algorithm
  ],
) <naive_curve>

In this graph, one can notice how $T^*$ (plotted as little dots) appears noisy over time; even though allowing to distinguish a tempo change at $t_1 = 130$ s and $t_2 = 270$ s. Both the sliding window average (dotted line) and median (full line) of $T^*$ seem unstable, presenting undesirable peaks, whereas the "feeled" tempo is quite constant for the listener, although the median line is a bit more stable than the average line, as expected. There are two explanation for those results. First, fast events are harder to play exactly on time, and the very definition being a ratio with a small theorical value as the denominator explains the deviation and absurd immediate tempo plotted. In fact, we can read that about 10 points are plotted over 400 BPM (keep in mind that usual tempo are in the range 40 - 250 BPM). Second, the notion of timing and tempo are mixed together in this computation, hence giving results that do not match the listener feeling of a stable tempo.  Actually, timing can be seen as little modifications to the "official" score, and using the resulting score would allow for curves that fit better the listener feeling, though needing an actual transcription of the performance first.

== Physical models

Among the tasks needing tempo estimation, the problem of real time estimation to allow a dedicated machine to play an accompagnement by following at least one real musician has been tackled by various approaches in litterature. @raphael_probabilistic_2001 started with a probabilistic model, but those methods have found themselves replaced by a more physical understanding of tempo _via_ the notion of internal pulse, as explained by @large_dynamics_1999. In fact, their method has recently been developped to a commercial form #footnote[https://metronautapp.com/], based on an a previous adaption by @antescofo.\ \

The approach developped by @large_dynamics_1999 consider a simplified neurological model, where listening is a fundamentally active process, implying a synchronization between external events (those of the performance) and an internal oscillator, whose complexity depends of hypothesis on the shape of the first ones. The model consists of two equations for the internal parameters:\
#let eq1 = nb_eq[$Phi_(n+1) = [Phi_n + (t_(n+1) - t_n) / p_n - eta_Phi F(Phi_n)] display(mod_"[-0.5, 0.5[") 1$];
#eq1 <large1>
#nb_eq[$p_(n+1) = p_n (1 + eta_p F(Phi_n))$] <large2>
Here, $(Phi_n)$ corresponds to the phase, or rather the phase shift between the oscillator and the external events, and $(p_n)$ embodies its period. Finally, $eta_p$ and $eta_Phi$ are both constant parameters. This initial model is then modified to consider a notion of attending _via_ the $kappa$ parameter, whose value change over time according to other equations. The new model contains the same formulas, with the following definition for $F$\
$F : Phi, kappa -> exp(kappa cos(2pi Phi)) / exp(kappa) sin(2pi Phi)/(2 pi)$.\

Even though this model shows pretty good results, has been validated through some experiments in #cite(<large_dynamics_1999>, form:"normal"), and is still used in the previously presented version (@large_dynamic_2023), a theorical study of the system behavior remains quite complex, even in simplified theorical cases #cite(<schulze_keeping_2005>, form:"normal"), notably because of the  function $F$ expression.\
\

In order to simplify the previous model, @schulze_keeping_2005 present _TimeKeeper_, that can be seen as a linearization of the previous approach, valid in the theorical framwork of a metronome presenting small tempo variations. In fact, there is a strong analogy between the two models, that are almost equivalent under specific circumstances, as shown by @loehr_temporal_2011. Here, we used the derandomised version presented in #cite(<loehr_temporal_2011>, form: "normal"), where $M_i = 0$ and $T_i = tau_i$ for all $i in NN$.

None of those models have an inherent comprehension of musical score information, since the both rely on a rather stable metronome. In the version displayed hereafter, they were modified to consider score information, in the goal to create a more stable and precise value of tempo than the naive approach previously presented. Those modifications are detailled in the following paragraph (OR IN APPENDIX ?), and were made in order to keep consistency with the original models in their initial theorical framework of validity.
Let $display(min_"abs") : a, b |-> cases(a "if" |a| < |b|, b "otherwise")$\

We first modify the @large_dynamics_1999 equations accordingly : <largmodif>
#nb_eq($Phi_(n+1) = Phi_n + (t_(n+1) - t_n) / p_n - eta_Phi F(Psi_n, kappa_n)$)
#nb_eq($p_(n+1) = p_n (1 + eta_p F(Psi_n, kappa_n))$)
$Psi_n = -display(min_"abs") (k + b_n - Phi_n, k + 1 + b_n - Phi_n) \ k = floor(Phi_n - b_n)$.

Using the analogy presented in #cite(<loehr_temporal_2011>, form: "normal"), we then obtain the following equations for _TimeKeeper_ :

#nb_eq($A_(i+1) = K_i (1 - alpha) + tau_i - (t_(i+1) - t_i)$)
#nb_eq($tau_(i+1) = tau_i - beta * (K_i mod_"[-0.5, 0.5[" 1)$)
$K_i = -display(min_"abs") (k tau + b_i - A_i, (k + 1)tau + b_i - A_i) \ k = floor((A_i - b_i) / tau_i)$.

In  both of those extensions, the $"min"_"abs"$ function is used in order to represent a choice between two corrections. The first argument can be interpreted as a correction with respect to the most recent passed beat time occuring exactly on a actual beat, ie $a_1 = display(max_(n in NN  " " : " " b_n <= B_i)) floor(b_n)$ where $B_i$ represents the internal value at time $i$ acting as a beat unit ($Phi_i$ for @large_dynamics_1999 and $A_i$ for @schulze_keeping_2005). The second argument embodies the correction according to the following beat, $a_2 = a_1 + 1$.\
One can notice that the phase is actually always used modulo 1 in @large_dynamics_1999, since it appears only multiplied by $2pi$ in either $cos$ or $sin$ functions. Using this remark, one can verify that, in the initial presentation of the model with a metronome, ie $forall n in NN, b_n = 0 mod 1$, the extension proposed here is equivalent to the original approach, ie $(1), (2) <=> (3), (4)$, hence justifying the designation "extension".\
\

@large_curve displays the results of those two models, in regards with the canonical, or immediate tempo. One can notice that @large_dynamics_1999 model is less stable than _TimeKeeper_, although faster to converge.

#figure(
  image("../Figures/large_version.png", width: 100%),
  caption: [
    Tempo curve for a performance of Islamey, Op.18, M. Balakirev, according to various models
  ],
) <large_curve>

@init_curve (below) exposes the visible difference in tempo initialization of the two models, starting both here with the initial tempo of 70 BPM (♩ = 70, ie the _beat_ unit here is a quarter note). _TimeKeeper_ does not manage to converge to any significant tempo. Such a behavior was to be expected, considering the theorical framework for _TimeKeeper_, that is small tempo variation, and correct initialization. However, Large et al model manages to converge to a meaningful result. In fact, in the range 9 to 70 seconds, the estimated tempo according to Large is exactly half of the actual tempo hinted by the blue dots (canonical tempo).

#figure(
  image("../Figures/large_nc_version.png", width: 100%),
  caption: [
    Tempo curve for a performance of Piano Sonata No. 11 in A Major (K. 331: III), W.A Mozart, according to the previous models with irrelevant initialization
  ],
) <init_curve>
  

= Scoreless approaches

== Motivations


There are three main issues with the previous models, appart from the necessary knowledge of the sheet music, that are : salient sensibility to tempo initialization (cf. @init_curve), unstability that requires some time to (possibly) converge (cf. @large_curve and @init_curve), and difficulty to accurately estimate relevant values of the constant internal parameters. According to our implementation, @large_dynamics_1999 is a particularly chaotic model regarding the latter.\

We will present here two models focusing on tackling mainly the first two issues previously presented. Those rely on a specific musical property of division : in symbolic notations of music, every single event can be comprehended as a mutliple of a certain unit called a @tatum, usually expressed in beat unit. Therefore, the real events of a performance, or rather their duration, can be interpreted as multiple of this tatum. However, considering a non-constant tempo, the real value (ie real duration in seconds) of this tatum may evolve through time, whereas the symbolic value remains constant anyway. Actually, detecting the tatum is equivalent to transcript the performance to sheet music, which a rather more complicated task than tempo estimation. For instance, there are several ways to write down sheet musics that are undistinguishable when performed, all corresponding to the same canonical tempo.

We considered here two quantization methods extracted from litterature : @murphy_quantization_2011 and @romero-garcia_model_2022. Both of these papers present a theory of approximate division, that is a way to find a rationnal number, interpreted as the ratio of two symbolic events expressed in arbitrary unit (for instance in tatum) from the real events durations in seconds. Such a link is equivalent to defining a tempo with the formalism presented in III. Although #cite(<murphy_quantization_2011>, form: "normal") provides an algorithm to find candidate rationnals, they do not include a way to compare those candidates, thus leaving no choice but an exhaustive approach (top-down in the paper). With another formalism, #cite(<romero-garcia_model_2022>) define a graph, restrained only to consistent values of tatum. We choose to adapt the latter, although their presentation is clearly user-oriented rather than automatic, since the introduced graph allows to mathematically (and therefore automatically) define a "good" and a "best" choice among all possible found tatum values.

== Introduction of an estimator based approach <estimator_intro>

Given a sequence $(u_n)_(n in NN)$, we now introduce the notation $(Delta u_n)_(n in NN) := (u_(n+1) - u_n)_(n in NN)$ for the next sections.\

The reason why the previous models have to converge is because they both try to find an exact value of tempo, and therefore sudden and huge tempo changes will lead to a uncertain period for the resulting tempo estimation, that is in this way the exact same problem as tempo initialization. When doing tempo estimation, we are in fact much more interested in a local tempo variation, relative to the previous estimation, rather than an absolute value, especially on a local time scale (where we can often assume tempo to be almost constant). Using the formalism presented in III, we first present the following result since $T_n^* > 0$ :\
$T^*_(n+1) = T_n^* (T^*_(n+1)) / T^*_n = T_n^* (Delta t_n) / (Delta t_(n+1)) (Delta b_(n+1)) / (Delta b_n) = T_n^* (Delta t_n) / (Delta t_(n+1)) times (T_(n+1)^* Delta t_(n+1)) / (T_(n)^* Delta t_(n))$\

Let $T_n$ be an estimation of $T_n^*$ by a certain given model and $alpha_n = T_n / T_n^*$. We obtain :\
$alpha_n T_(n+1)^* = underbrace(alpha_n T^*_n, T_n) (Delta t_n) / (Delta t_(n+1)) times (Delta b_(n+1)) / (Delta b_n)$\

In the above formula, the only value to actually estimate is therefore $(b_(n+2) - b_(n+1)) / (b_(n+1) - b_n)$, where both the numerator and denumerator are translation permissive (ie we can afford a locally constant shift in both of our estimation), hence the resulting value is invariant by translation, or constant multiplication of our estimation. Furthermore, the value to be estimated only deals with symbolic units, meaning that we can use musical properties to find a consistent result. As a result, we can obtain a tempo estimation with the same multiplicative shift as the previous estimation $T_n$, thus, by using the formula recursively, we obtain a model that can track tempo variations over time without any need of convergence, and that is robust to tempo initialization, while using only local methods (in other words, the resulting model is @online). As noticed in the beginning of this section, symbolic value have some bindings that actually help to determine their values. Moreover, we find : $(Delta b_(n+1)) / (Delta b_n) = (T_(n+1)^* Delta t_(n+1)) / (T_(n)^* Delta t_(n)) = (1/alpha_n T_(n+1)) / (1/alpha_n T_n) times (Delta t_(n+1)) / (Delta t_(n))$,\
hence $(Delta b_(n+1)) / (Delta b_n) = T_(n+1) / T_n times (Delta t_(n+1)) / (Delta t_(n))$.\
Let us then write the actual formula of the model :\
#nb_eq($T_(n+1) / T_n = (Delta t_n) / (Delta t_(n+1)) underbrace(E(T_(n+1) / T_n times (Delta t_(n+1)) / (Delta t_(n))), display((Delta b_(n+1)) / (Delta b_n)))$) <estimator>\
where $E$ is a function-like object (closer to a _object_ in computer science than an actual mathematical function), designated by _estimator_. This function is supposed to act, on a theorical ground, as an oracle that returns the correct value of the symbolic $(Delta b_(n+1)) / (Delta b_n)$ from the given real values indicated in @estimator, therefore supposed to rarely match the theorical values.\

Given an estimator $E$, the tempo value defined as $T_(n+1)$, computed from both $T_n$ and local data, is obtained _via_ the following equation, where $x$ represents $T_(n+1) / T_n$ in @estimator : \
#nb_eq($T_(n+1) = T_n argmin_(x in [2/3 T_n, 4/3 T_n]) d(x, (Delta t_n) / (Delta t_(n+1)) E(x (Delta t_(n+1)) / (Delta t_(n)))) $) <estimatorf>
where $d : a, b |-> k_*|log(a/b)|, k_* in RR_+^*,$ is a logarithmic distance, choosen since an absolute distance would have favor small values by triangle inequality in the hereunder process.

In the implementation presented here, the estimator role is more to quantify the ratio in order to output a musically relevant value. In our test, we limited these quantification to accept only regular division (ie powers of 2). Furthermore, the numerical resolution for the previous equation was done by a logarithmically evenly spaced search and favor $x$ values closer to 1 (ie $T_(n+1)$ closer to $T_n$) in case of distance equality.

Such a research allows for a musically explainable result : the current estimation is the nearest most probable tempo, and both halving and doubling the previous tempo is considered as improbable, and as further going from the initial tempo. @ann2 gives further explanation about @estimatorf.

== Study of the model <study_of_esti>

Since this approach fundamentally search to estimate tempo variation rather than actual values, it is not easy to visualize the relevance of the result by naive means. We choose here to define $(alpha_n := T_n / T_n^*)_(n in [|1, N|])$ and $(tilde(alpha_n) := exp(ln(T_n / T_n^*) - floor(log_2 (T_n / T_n^*)) ln(2)))_(n in [|1, N|])$. $(tilde(alpha_n))_(n in [|1, N|])$ is then called the _normalized_ sequence of ratio, where each value is uniquely determined within the range $ [1, 2[$. Such a choice allows for merging together the tempo octaves, as explained in @ann1. In this representation, we actually have $tilde(2) = tilde(1)$, and adding $tilde(1)$ is equivalent to multiply the initial value by $2$. We will now define a _spectrum_ $S = (tilde(alpha_n))_(n in [|1, N|])$. We then call $|S|$ the value $N in NN$ and $cal(C)$ the range $[1, 2[$ seen as a circle according to the following application : $c : [1, 2[ &-> cal(C)(0, 1)\ x &|-> (cos(2pi x), sin(2pi x))$, so that $c(1) = c(2)$

We then define the _measure_ of a spectrum $S$, that embodies a standard deviation on $cal(C)$, so that : #nb_eq[$m(S, Delta) = max_(tilde(d) in cal(C)) ( |{n in [|1, |S| |] : d(tilde(alpha_n), tilde(d)) <= Delta}|) / (|S|)$]
Where $Delta in [0, 1/2]$ embodies the measure accuracy, and $d$ is still a logarithmic distance, slightly modified on $cal(C)$ to be consistent with $d(tilde(1), tilde(2)) = 0$. Actually, it can be shown that on $cal(C)$, $d : tilde(a), tilde(b) |-> min(abs(tilde(a) - tilde(b)), 1 - abs(tilde(a) - tilde(b)))$.

The reader can verify that this measure is invariant with respect to spectrum rotation by any $lambda in R^*_+$ (ie $m(S, Delta) = m((tilde(lambda alpha_n))_(n in [|1, N|]), Delta)$), and does not depend on the normalisation intervall (here $[1, 2[$, but actually $[lambda, 2 lambda[$ would work just as well, with a different expression of $d$ on $cal(C)$). Finally, $0 <= m(S, Delta) <= 1$, and $m(S, Delta) = 0 <=> |S| = 0$, $m(S, Delta) = 1$ iff $S$ only contains values within a $2Delta$ range.

This measure allows to quantify the quality of this model, without considering tempo octaves. @ann2 presents the C++ implementation of this measure used to obtain the following figures.

résultats sur (n-)Asap selon les périodes, les compositeurs, etc..., éventuellement en annexe ?

== Quantified approach <quanti>

The previous model suppose the existence of an oracle, more or less correct in its predictions, that is actually a (partial) transcriber. In this section, we will focus on this transcribing part, by extending @romero-garcia_model_2022 model with the previous formalism.

  - LR
  - bidi (2 passes: LR + RL) : justification (en annexe) : retour à la définition formelle de Tempo : valide dans les deux sens, d'où la possibilité de le faire en bidirectionnel + parler rapidement d'une application à Large
  - RT : avec valeur initiale de tempo
== résultats évaluation (comparaison avec 3)

plutôt en annexe je pense



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
- @quanti presented a model which appear to share some similarities with @large_dynamics_1999 as a score-based approach. Therefore, studying the formalism for a quantifier might allow to obtain some theorical results for the previous model, regarding for instance convergence guarantee and meaningfulness of the result.

#bibliography("refs.bib", title: "References")

#colbreak()

#appendix([Some formal considerations], [
== Equivalence of tempo formal definitions

Let $n in NN$.
$integral_(t_0)^(t_(n)) T(t) dif t = sum_(i = 0)^(n-1) integral_(t_i)^(t_(i+1)) T(t) dif t$\
Furthermore, $integral_(t_n)^(t_(n+1)) T(t) dif t = integral_(t_0)^(t_(n+1)) T(t) dif t + integral_(t_n)^(t_0) T(t) dif t = integral_(t_0)^(t_(n+1)) T(t) dif t - integral_(t_0)^(t_n) T(t) dif t$.\ \
Let $T$ be a formal tempo according to the first definition. For all $n in NN$, we then have :\ $integral_(t_n)^(t_(n+1)) T(t) dif t &= integral_(t_0)^(t_(n+1)) T(t) dif t - integral_(t_0)^(t_n) T(t) dif t\
&= b_(n+1) - b_0 - (b_n - b_0)\
&= b_(n+1) - b_n$\
Let $T$ be a formal tempo according to the second definition. For all $n in NN$ :\
$integral_(t_0)^(t_(n)) T(t) dif t &= sum_(i = 0)^(n-1) integral_(t_i)^(t_(i+1)) T(t) dif t\
&= sum_(i = 0)^(n-1) b_(i+1) - b_i\
&= b_n - b_0$\
We thus obtain the two implications, hence the equivalence.

== The tempo octave problem

When estimating tempo, or transcribing a performance, there always exist several equivalent possibilities. For instance, given a "correct" transcription $(b_n)$ of a performance $(t_n)$, one can choose to define its own transcription as $t = (b_n / 2)_(n in NN)$.\
Then, the canonical tempo according to $t$, called $(T_1^*)$, and the one according to $(b_n)$, called $(T_2^*)$ verify :\
$forall n in NN, T_(1, n)^* = (b_(n+1) / 2 - b_n / 2) / (t_(n+1) - t_n) = 1/2 T_(2, n)^*$.
Actually, the $t$ transcription corrections to $(b_n)$ where all durations are indicated doubled, but played twice faster, hence giving the exact same theorical performance. Unfortunately, there is no absolute way to decide which of those two transcription is better than the other. This problem is here known as the tempo octave problem, and should be keeped in mind when transcribing or estimating tempo. We present in @estimator_intro a model resistant to these tempo octaves, as well as other kind of octaves not discussed here (for instance multiplying the tempo by $3$ by using @triplet).


== Tempo convservation when reversing time

First, we want to insist on the fact that none of the sequence $(b_n)$ and $(t_n)$ are infinite, but in order to simplify the notation, we chose to indicate them as usual infinite sequences, or rather only consider them on a finite number of indexes, called $|(b_n)|$ and $|(t_n)|$ respectively, with $|(b_n)| = |(t_n)|$. Let us then define the reversed sequence of $(u_n)_(n in NN)$ as $r((u_n)_(n in NN)) := (overline(u_n) = u_(|(u_n)|) - u_(|(u_n)| - n))_(n in [|0, |(u_n)| |])$. Both $overline(b) = r((b_n)_(n in NN))$ and $overline(t) = r((t_n)_(n in NN))$ are correct representations of a sheet music and performance respectively, as defined in @formal_consider.

Let $t^* = t_(|(t_n)|)$ and $q = |(t_n)|$, $T$ a formal tempo with respect to $(t_n)$ and $(b_n)$, ie $forall n in NN, integral_(t_n)^(t_(n+1)) T(t) dif t = b_(n+1) - b_n$, $n in [| 0, q - 1|]$, and $T_r : t |-> T(t^* - t)$.

$integral_(overline(t_n))^(overline(t_(n+1))) T_r (t) dif t &= integral_(t^* - t_(q - n))^(t^* - t_(q - n-1)) T(t^* - t) dif t = integral_(t_(q - n))^(t_(q - n - 1)) -T(x) dif x\
&= integral_(t_(q - n - 1))^(t_(q - n)) T(t) dif t\
&= b_(q - n) - b_(q - n - 1)\
&= (b_(q - n) - b_q) - (b_(q - n - 1) - b_q)\
&= - overline(b_n) + overline(b_(n+1))\
&= overline(b_(n+1)) - overline(b_n)$

Hence $T_r$ is a formal tempo with respect to $(overline(t_n))$ and $(overline(b_n))$.

== Musical explication of the choice of  a tempo distance

In terms of tempo, halving and doubling are considered as far as each other from the initial value. Therefore a usual absolute distance does not fit this notion, and we will rather use a logarithmic distance when comparing tempi.
]) <ann1>

#appendix([Estimator Model], [
  - d est une distance

  - argmin : d est continue (distance), donc bornée et atteint ses bornes sur l'intervalle

  Remarque sur la distance log (pas d'importance de $k_*$).

  Pourquoi 2/3 et 4/3 :
  - candidat unique pour chaque changement de tempo : résistant aux octaves
  - easier to search ($|2/3 - 1| = |4/3 - 1|$) : solution of $2x - 1 = 1 - x <=> 3x = 2$ : on veut un tempo unique, DONC (à montrer éventuellement) entre $x$ et $2x$, et on prend $x$ "centré" en $1$.

  - si l'estimateur est l'identité : par hypothèse d'oracle, le tempo est constant, et joué parfaitement (ie fichier midi), et le résultat est le bon

  - l'estimateur n'est pas une fonction : l'output à un instant donné peut dépendre des outputs précédents (cas extrême : transcription en temps réel) : très bonne courbe, mais estimateur très complexe, or le problème ici est justement relaxé : ajouter un exemple de fausse transcription et de correcte avec les courbes de tempo correspondantes.

The C++ code for the measure of $S, Delta$ is presented hereafter :

```cpp
#measure.hpp :
using couple = std::pair<int, int>;

bool couple_eq(couple c1, couple c2) {
    auto [a, b] = c1;
    auto [c, d] = c2;
    return (a == c) && (b == d);
}

template <typename T>
class Circle {
    std::vector<T> t;
    std::vector<int> count;
    double x;
    int len;
    couple start;

    public:
    Circle(std::vector<T> spectre, double x, int i) : t(std::vector<T>()), count(std::vector<int>()), x(x), len(spectre.size()), start(couple(i, 0)) {
        count.push_back(1);
        t.push_back(spectre[0]);
        for (unsigned int ind = 0; ind + 1 < spectre.size(); ind++) {
            if (spectre[ind] == spectre[ind + 1]) {
                count[count.size() - 1]++;
            } else {
                count.push_back(1);
                t.push_back(spectre[ind+1U]);
            }
        }
    }

    int size() {
        return t.size();
    }

    bool is_start(couple end) {
        auto [i, k] = start;
        auto [j, l] = end;
        return i == j;
    }

    couple get_start() {
        return start;
    }

    double get(couple a) {
        auto [i, k] = a;
        return t[i]+ x*k;
    }

    couple get_next(couple a) {
        auto [i, k] = a;
        if (i + 1 == t.size()) {
            return couple(0, k+1);
        }
        return couple(i+1, k);
    }

    couple get_previous(couple a) {
        auto [i, k] = a;
        if (i == 0) {
            return couple(t.size() - 1, k-1);
        }
        return couple(i-1, k);
    }

    int get_count(couple a) {
        auto [i, _] = a;
        return count[i];
    }

    int get_cardinal(couple a1, couple a2) {
        auto [i1, k1] = a1;
        auto [i2, k2] = a2;
        int s = 0;
        int delta = i2 - i1 + (k2 - k1) * t.size();
        int q = delta / t.size();

        for (int i = 0; i < t.size(); i++) {
            int c = q;
            if (i1 > i2) {
                c += (i >= i1 || i <= i2);
            } else {
                c += (i >= i1 && i <= i2);
            }
            s += count[i] * c;
        }
        return s;
    }

    int length() {
        return len;
    }
};

#measure.cpp :
double distance(double a, double b, double x) {
    return fmin(fabs(a - b), x - fabs(a - b));
}

double get_measure(std::vector<double> spectre, const double delta, const double x, int i) {
    std::sort(spectre.begin(), spectre.end());
    Circle<double> c = Circle<double>(spectre, x, i);
    couple ind_end = c.get_start();
    couple ind_start = ind_end;
    double d = c.get(ind_end) - delta;
    for (int i = 0; i < c.size() - 1; i++) {
        ind_start = c.get_previous(ind_start);
        if (distance(c.get(ind_start), d, x) > delta) {
            ind_start = c.get_next(ind_start);
            break;
        }
    }
    int p = c.get_cardinal(ind_start, ind_end);
    int S = p;

    int h = 0;
    while (h+1 < c.size()) {
        double d1 = delta - distance(c.get(ind_start), d, x); // Next start index change
        if (c.get(ind_start) > d) {
            d1 = -d1 + 2*delta;
        }
        double d2 = distance(c.get(c.get_next(ind_end)), d, x) - delta; // Next end index change

        if (d1 <= d2) {
            p -= c.get_count(ind_start);
        }
        if (d2 <= d1) {
            h++; // A new point enters the delta area
            p += c.get_count(ind_end);
            S = fmax(S, p);
        }
        d += fmin(d1, d2);

        if (d1 <= d2) {
            ind_start = c.get_next(ind_start);
            if (couple_eq(ind_start, ind_end)) {
                ind_end = ind_start;
            }
        }

        if (d2 <= d1) {
            ind_end = c.get_next(ind_end);
        }
    }
    return (double)S / (double)(c.length());
}
```
]) <ann2>

#appendix([Quantified Model], [

Posons tout d'abord quelques fonctions utiles.\
On définit : $g : x |-> min(x - floor(x), 1 + floor(x) - x)$\
On peut vérifier que $g : x |-> cases(x  - floor(x) "si" x  - floor(x) <= 1/2, 1 - (x - floor(x)) "sinon")$ et que $g$ est 1-périodique continue sur $RR$.\

Ainsi, on a : $epsilon_T (a) = display(max_(t in T) (min_(m in ZZ) abs(t - m a))) = display(max_(t in T)) min(t - floor(t/a)a, (floor(t/a) + 1)a - t) = a display(max_(t in T) underbrace(min(t/a - floor(t/a), floor(t/a) + 1 - t/a), g(t/a))) = a display(max_(t in T) g(t/a))$, donc en particulier, $epsilon_T$ est continue sur $R^*_+$.

On remarque de plus, pour $n in NN^*, T subset (RR^*_+)^n, a in R^*_+ : epsilon_T (a) = a epsilon_(T \/ a) (1)$. Hence the intuitive following result : the smaller the tatum, the smaller the bound of the error.

== Caractérisation des maximums locaux qui ne sont pas des minimums locaux

=== First implication
\
Let $a$ be a local maxima (and not a local minima) of $epsilon_T$, $a > 0$. 
By definition, there is a $a > epsilon > 0$ so that :\
$forall delta in ]-epsilon, epsilon [, epsilon_T (a) >= epsilon_T (a + delta)$.\
Let $t in display(argmax_(t' in T)) g(t' / a)$, hence $epsilon_T (a) = a g(t/a)$.\
For all $delta in ]-epsilon, epsilon [, epsilon_T (a) = a g(t/a) >= epsilon_T (a + delta)$,\ and $epsilon_T (a + delta) = (a + delta) max_(t' in T) g(t'/(a + delta)) >= (a + delta) g(t / (a + delta))$.
For $delta >= 0, a + delta >= a$, so $a g(t/a) >= (a+delta) g(t/(a+delta)) >= a g(t/(a+delta))$\
Hence, $g(t/a) >= g(t/(a+delta))$ since $a > 0$, for all $delta in [0, epsilon[$.\
Therefore, $g$ #underline([increases monotonically]) in the range $] t/(a+delta), t/a [$, since $g$ has a unique local maxima (modulo 1), considering the previous range as a neighbourhood of $t/a$.\
Hence, $g = x |-> x - floor(x) $ within the considered range, and $g(t/a) = t/a - floor(t/a), epsilon_T (a) = t - a floor(t/a)$.\
\
The function $epsilon_T$ is the maximum of a finite set of continuous functions, with a countable set of $A$ of intersection, ie $A = {x in RR^*_+ : exists (t_1, t_2) in T^2 : t_1 != t_2 and x g(t_1/x) = x g(t_2/x)}$.
Indeed,\
$x in A &<=> exists (t_1, t_2) in T^2 : t_1 != t_2 and g(t_1/x) = g(t_2/x)\
&<=> exists (t_1, t_2) in T^2 : t_1 != t_2 and t_1/x = plus.minus t_2 / x mod 1\
&<=> exists (t_1, t_2) in T^2 : t_1 != t_2 and x = (t_1 minus.plus t_2) / n, n in ZZ^*$\
Hence $A subset {(t_1 minus.plus t_2) / n, (t_1, t_2) in T^2, n in ZZ^*}$, because $T subset (R^*_+)^(|T|)$.
Therefore, there is a countable set of closed convex intervalls, which union is $R^*_+$ so that on each of these intervalls, $epsilon_T$ is equal to $f_t : a |-> a g(t/a)$ for a $t in T$. Let then $t$ be so that for all $x in ]a-delta', a[, epsilon_T (x) = f_t(x)$, where $]a-delta', a[$ is included in one the previous intervalls. Since $f_t$ and $epsilon_T$ are both continuous on $[a-delta', a], f_t (a) = epsilon_T (a)$ and therefore, $t in display(argmax_(t' in T)) g(t' / a)$. The previous paragraph showed that $g$ is increasing on a left neighbourhood of $t/a$. Therefore, on a right neighbourhood of $t/a$, $g$ is either increasing or decreasing by its definition.

- if $g$ is increasing on this neighbourhood, called $N(t/a)^+$ in the following, the previous expression of $g$ remains valid, ie $forall x in N(t/a)^+, g(x) = x - floor(x)$. Moreover, $x |-> floor(x)$ is right-continuous, hence by restricting $N(t/a)^+$, we can assure for all $x in N(t/a)^+,floor(x) = floor(t/a)$. Let then $y = a - t/x$ so that $x = t/(a - y)$, we then have $epsilon_T (a - y) = t - (a - y) floor(t/a) <= epsilon_T (a) = t - a floor(t/a)$ because $a$ is a local maxima of $epsilon_T$ and $a - y$ is within a (left) neighbourhood of $a$, even if it means restricting $delta'$ or $N(t/a)^+$. Hence, $t - floor(t/a) a >= t - (a-y)floor(t/a)$ ie $a floor(t/a) <= (a - y) floor(t/a) <=> 0 <= -y floor(t/a)$ ie $floor(t/a) <= 0$ ie $floor(t/a) = 0$, since $y, t "and" a$ are all positive values. Then, $a > t$ and therefore $epsilon_T (a - y) = t = epsilon_T (a)$ for $floor(t/a) = 0$. This intervall where $epsilon_T$ is constant is then either going on infinitely on the right of $a$, or else $epsilon_T$ will reach a value greater than $epsilon_T (a) = t$, since $epsilon_T$ can then be rewritten as $x |-> max(display(max_(t' in T without {t}) x g(t'/x) ), epsilon_T (a))$ on $[a, +infinity[$. Hence $a$ is a local minima on the right, and since $epsilon_T$ is constant on a left neighbourhood of $a$, $a$ is also a local minima on the left. Finally, $a$ is a local minima, which is absurd by definition.

- else, $g$ is decreasing on $N(t/a)^+$, $t/a$ is by definition a local maxima of $g$. However, $g$ only has a unique local maxima modulo 1, that is $1/2$. Hence, $t/a = 1/2 mod 1$, ie $t/a = 1/2 + k, k in ZZ$, or $underline(a = t/(k + 1/2)\, k in NN)$, since $a > 0$.

=== Second implication
\
Let $(t, k) in T times NN, a = t/(k + 1/2)$.\
By definition : $g(t/a) = g(1/2 + k) = g(1/2) = 1/2 = max_RR g$.\
Therefore, $epsilon_T (a) = a max_(t' in T) g(t' / a) = a g(t/a) = a / 2$.\
For all $x in ]0, a[, epsilon_T (x) = x max_(t' in T) g(t'/x) <= x/2 < a/2 = epsilon_T (a)$, ie $underline(epsilon_T (a) > epsilon_T (x))$.\
Let $T^* = {t' in T : g(t'/a) = 1/2}$. Since $t in T^*$, $|T^*| > 1$.\
Let $t^* in T^*$. For all $t' in T without T^*, g(t'/a) < g(t^* / a)$.\
Since $h_(t') : x |->  g(t'/x) - g(t^* / x)$ is continuous in a neighbourhood of $a > 0$, we have the existence of $epsilon_(t') > 0$ so that $h_(t')$ is strictly positive within $[a, a + epsilon_(t') [$.\
Let $epsilon_(t^*) = min_(t' in T) epsilon_(t')$ and finally $epsilon_1 = min_(t^* in T^*) epsilon_(t^*)$.\
\
Let $(t_1, t_2) in (T^*)^2$.\
In the following, $N(a)^+$ is a right neighbourhood of $a$ such that $a in.not N(a)^+$.\

Let $"tmp" : x |-> g(t_1 / x) - g(t_2 / x)$ be a continous function on $N(a)^+$ and $A$ be the set of all $x^* in N(a)^+ $ so that $"tmp"(x^*) = 0 <=> g(t_1/x^*) = g(t_2/x^*)$.

  We have for all $x^* in A$, $ g(t_1/x^*) = g(t_2/x^*)$ by definition. Considering the expression of $g$, we then find : $t_1/x^* = plus.minus t_2/x^* mod 1$. Moreover, since $g$ only reach $g(t_1/a) = 1/2$ once per period, we have $t_1/a = t_2/a mod 1$, ie $|t_1/a - t_2/a| = k_a in NN$.

Then,  $t_1/x^* = plus.minus t_2/x^* mod 1$ ie $|t_1/x^* minus.plus t_2/x^*| = k_* in NN$, and therefore $|t_1 minus.plus t_2| = a k_a = x^* k_*$, and $x^* > a$ implies $k_a > k_* >=0$. However, $x^* = abs(t_1 minus.plus t_2) / k_*$, hence $A$ is finite if $A != emptyset$, and $emptyset$ is a finite set. Finally, $A$ is #underline([a finite set]), ie $|A| in NN$.\
Let then $x_(t_1, t_2) = cases(min A "if" A != emptyset, x in N(a)^+ without {a} "otherwise") $ WLOG $g(t_1/x) >= g(t_2/x) forall x in [a, x_(t_1, t_2)]$\
Let $a_2 = display(min_((t_1, t_2) in T^*^2)) underbrace(x_(t_1, t_2), > a)$ and $a_1 in ]a, a_2[$,\
let $t^* = display(argmax_(t' in T^*)) g(t'/a_1)$
We finally have $forall x in ]a, a_2[, g(t^* / x) >= g(t' / x), forall t' in T^*$.\
\
Let then $tilde(a) = min(a + epsilon_1, a_2)$ so that for all $x in ]a, tilde(a)[, t' in T, g(t^* / x) >= g(t'/x)$, hence $epsilon_T (x) = x g(t^* / x)$.\
Let $f : x |-> g(t^* / x), f(a) = g(t^* / a) = 1/2$ because $t^* in T^*$ hence $f$ is increasing on a right neighbourhood of a, $N(a)^+$, since $1/2$ is a global maxima of $g$, therefore $g$ is increasing on $N(t^* / a)^-$ a left neighbourhood of $t^* / a$, ie $f$ is increasing on $N(a)^+$. Therefore, we know that $g(t^* / x) = t^* / x - floor(t^* / x)$, since the only other possible expression for $g$ would imply a decreasing function on $N(t^* / a)^-$.\

Hence, $epsilon_T (x) = x g(t^* / x) = x (t^* / x - floor(t^* / x)) = t^* - x floor(t^* / x)$ and $epsilon_T (a) = t^* - a floor(t^* / a)$ since $epsilon_T$ is continuous on $RR^*_+$.\
By definition : $floor(t^* / a) <= t^* / a < floor(t^* / a) + 1$.\
However, $f(a) = 1/2 = t^* / a - floor(t^* / a)$, therefore $floor(t^* / a) < t^* / a$.\
Then, there is $alpha in RR^*_+$ so that $floor(t^* / a) < alpha < t^* / a$, let $y = t^* / alpha$, ie $alpha = t^* / y$, with $y > a$.\
Let $a' = min(y, tilde(a))$ and $k = floor(t^* / a)$. For all $x in ]a, a'[$,
- $x <= y = t^* / alpha$ hence $floor(t^* / a) <= alpha <= t^* / x$
- $x >= a$ hence $t^* / x <= t^* / a < floor(t^* / a) + 1$

In the end, $floor(t^* / x) = floor(t^* / a) = k$ by definition.
\
Then, $epsilon_T (x) = t^* -x k$ and $epsilon_T (a) = t^* -x a$, with $a < x$.\
Finally, $underline(epsilon_T (a) > epsilon_T (x))$.
\
To conclude, for all $x in ]0, a'[$,
- if $x <= a$, $epsilon_T (a) >= epsilon_T (x)$
- if $x >= a, x in [a, a'[$ and $epsilon_T (a) >= epsilon_T (x)$

Hence $a$ is a local maxima of $epsilon_T$ and not a local minima, and then the set of all such local maxima of $epsilon_T$ is $M_T = {t / (k + 1/2), t in T, k in NN}$ $qed$

== Caractérisation des minimums locaux

Let $a$ be a local minima of $epsilon_T$, ie 


$epsilon_T$ is constant on a neighbourhood of $+ infinity$, donc on va d'abord trouver un maximum local qui n'est pas un minimum local, puis le reste de la preuve fonctionne

Par continuité de $epsilon_T$, on est assuré de l'existence d'exactement un unique minimum local entre deux maximums locaux, qui est alors global sur cet intervalle.\
Par la condition nécessaire précédente, il suffit donc, pour déterminer ce minimum local, de déterminer le plus petit élément parmi les points obtenus, contenus dans l'intervalle.\
On en déduit ainsi un algorithme en $cal(O)(|T^2| t^* / tau log( |T| t^* / tau))$ permettant de déterminer tous les minimums locaux accordés par le seuil $tau$ fixé, sur l'intervalle $]2 tau, t_* + tau[$

On en déduit la correction de l'algorithme ci-dessous :
```python
def find_local_minima(T, start, end):
    assert(len(T) > 0)
    maxs = [t / (k+0.5) for t in T for k in range(int(t/end), int(t/start)+1)] # According to caracterization
    maxs.sort()
    potentials = [(t1+t2) / k for t1 in T for t2 in T for k in range(max(1, int((t1+t2)/end)), int((t1+t2)/start)+1) if t1 < t2]
    potentials.sort() # Only a necessary condition

    if len(potentials) == 0: # Implies : T = {T[0]}
        potentials = [T[0]/k for k in range(int(T[0]/end), int(T[0]/start)+1)[::-1]] # Already sorted
        mins = potentials # In this specific case, the condition is an equivalence
    else:
        j = 0
        mins = []
        for i in range(len(maxs)-1):
            pot_mins = []
            while j < len(potentials) and maxs[i] <= potentials[j] < maxs[i+1] :
                pot_mins.append(potentials[j])
                j += 1
            if len(pot_mins) > 0:
                mins.append(np.min(pot_mins))

    return mins
```
]) <gonzalo_spectre>

#appendix([Musical Glossary], [
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

      (
        key:"triplet",
        short:"triplet",
        desc:[A triplet is a musical symbol indicating to play a third of the indicated duration],
        group:"Definitions"
      ),

      (
        key:"online",
        short:"online",
        desc:[Définition d'une méthode / d'un algo online],
        group:"Definitions"
      ),
    )
  )
])