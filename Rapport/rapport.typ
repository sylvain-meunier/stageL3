#import "@preview/charged-ieee:0.1.0": ieee
#import "@preview/lovelace:0.3.0": *
#import "@preview/lemmify:0.1.5": *
#import "@preview/glossarium:0.4.1": make-glossary, print-glossary, gls, glspl
#show: make-glossary
#show link: set text(fill: blue.darken(30%))
#set page(numbering: "1")

#show: ieee.with(
  title: [Tempo curves generation, estimation and analysis\ L3 intership (CNAM / INRIA)\ 27/05/24 - 02/08/24],
  abstract: [
    Tempo estimation consists in detecting the speed at which a musician plays, or more broadly at which a piece of music is played. Such speed is usually expressed with respect to symbolic representation of the piece, in order to match the intuitive notion of a regular _pulse_.
    We present here some results regarding the generation and analysis of local tempo curves from musical performances involving, first, methods that need to be given some symbolic information, and then methods that don't. More precisely, we focus here on tempo estimation for a given performance recorded as a MIDI file, on both a local and global level, and with or without prior knowledge of a reference #gls("score", long: true). In order to do so, we introduce mathematical formalisms based on underlying notions in the literature.
  ],
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
  index-terms: ("Music Information Retrieval", "tempo estimation", "quantization", "musical formalism", "musical data representation"),
  paper-size:"a4",
)

#show figure : set figure.caption (position: bottom)

#let (
  lemma, corollary, theorem, proposition, definition, remark, example, proof, rules: thm-rules
) = default-theorems("thm-group", lang: "en", max-reset-level: 1, thm-numbering: thm-numbering-heading.with(max-heading-level: 1))
#show: thm-rules

#let set-thm-counter-value(group, value) = counter(thm-selector(group)).update(c => value)

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
#let amin = math.op("amin", limits: true)

#set cite(form: "prose")
#v(-.75em)
= Introduction
#v(-0.4em)
The @mir community focuses on three representations of musical information, presented here from lowest to highest level of formatting. The first one is raw audio, either recorded or generated, encoded using WAV or MP3 formats. The computation is based on a physical understanding of signals, using audio frames and spectrum, and represents the most common and accessible kind of data. The second is a more musically-informed format, representing notes with both pitch (i.e., the note that the listener hears) and duration in @rtu (sec.), encoded within a MIDI file.
The last way to encode musical information is a MusicXML file, mainly used for display and analysis purposes. The latter relies on a symbolic and abstract notation for time, that only describes the length of events in relation to a specific @mtu, called a @beat, and indicates as well the pitch and @articulation of those events.
These symbolic indications are then to be interpretated by a performer. An expressive musical performance is not only about theoretical compliance with rhythmic musical theory (a task that computers excel at), but rather, and actually mostly, about sprinkling micro-errors (refered to here as or shifts, or (micro) #gls("timing", display: "timings")).

Moreover, to actually play a sheet music, one needs a given @tempo, usually indicated as an amount of beat per minute (BPM). Therefore, the notion of tempo allows to translate @mtu symbolic notation into @rtu events. We will present a formal definition for both tempo and performance in @formal_consider.\

However, tempo itself is insufficient to translate a music score into musical performance, i.e., a sequence of real time events. Indeed, S. D. Peter et al. #cite(<peter2023sounding>, form: "normal") present four parameters, among which tempo and @articulation appear the most salient as opposed to @velocity and #gls("timing", long:false). Even though the MIR community studies the four parameters, the hierarchy exposed by #cite(<peter2023sounding>, form:"normal") embodies quite well their relative priority within literature.\

Tempo and associated works actually hold a prominent place in literature. Tempo inference was first computed based on probabilistic models #cite(<raphael_probabilistic_2001>, form: "normal") #cite(<nakamura_stochastic_2015>, form: "normal") #cite(<nakamura_outer-product_2014>, form:"normal"), and physical or neurological models #cite(<large_dynamics_1999>, form: "normal") #cite(<schulze_keeping_2005>, form: "normal") as methods for real time (musical) @score synchronization with a performance ; and later the community tried neural network models #cite(<Kosta2016Mapping>, form:"normal") and hybrids approaches #cite(<shibata_non-local_2021>, form: "normal").\

A very useful preprocessing task for tempo inference and further analysis, such as #cite(<kosta_mazurkabl:_2018>, form:"normal") #cite(<hentschel_annotated_2021>, form:"normal") #cite(<hu_batik-plays-mozart_2023>, form:"normal"), is note-alignement, that is a matching between each note of a MIDI performance and those indicated by a given score. Two main methods are to be found in literature : a dynamic programming algorithm, equivalent to finding a shortest path, that can work on raw audio #cite(<muller_memory-restricted_nodate>, form: "normal"); and a Hidden Markov Model that needs more formatted data, such as MIDI files #cite(<nakamura_performance_2017>, form: "normal").  As most of the previous examples, we shall focus here on mathematically or musically explainable methods.\
We shall present below our following contributions :
#list(
  marker: [‣],
  indent: 0.2em,
  body-indent: 0.5em,
  [Formal definition of tempo, based on #cite(<raphael_probabilistic_2001>, form: "normal"), #cite(<kosta_mazurkabl:_2018>, form: "normal") and #cite(<hu_batik-plays-mozart_2023>, form: "normal") (#link(<formal_consider>)[II.A]) ; and some immediate consequences (#link(<naive_use>)[II.B])],
  [Revision of #cite(<large_dynamics_1999>, form: "normal") and #cite(<schulze_keeping_2005>, form: "normal") for score based tempo inference (#link(<largmodif>)[II.C])],
  [Original techniques of tempo inference, without score, based on #cite(<murphy_quantization_2011>, form: "normal") (#link(<estimator_intro>)[III.A]), and #cite(<romero-garcia_model_2022>, form: "normal"), with related new theoretical results (#link(<quanti>)[III.B], #link(<quanti_revised>)[III.C] and @gonzalo_spectre)],
  [Method for data augmentation, and related results, based on #cite(<foscarin_asap:_2020>, form: "normal") and #cite(<peter_automatic_2023>, form: "normal")  (#link(<data_gen>)[IV.A])]
)
#v(0.45em)
#h(0.6em)This document, along with some algorithm implementations and detailled results can be found on the dedicated #link("https://github.com/sylvain-meunier/stageL3")[github repository] #cite(<git>, form: "normal"). Most proofs are to be found in Appendices.
= Score-based approaches <score_based>

== Preliminary works <formal_consider>

#definition(numbering: none)[
  Let $u = (u_n)_(n in NN)$ be a sequence, we introduce the notation : $(u_n)$ for $u$, where $n$ is a dummy variable, and its introduction $n in NN$ is implicit.
]\
#v(-1.7em)
Since we chose to focus on MIDI files, we will represent a (@monophonic) performance as a strictly increasing sequence of timepoints, or events, $(t_n) in RR^NN$, each element of whose indicates the onset of a corresponding performance event. Such a definition is very close to an actual MIDI representation.\
For practical considerations, we will stack together all events whose distance in time is smaller than $epsilon = 20 "ms"$. This order of magnitude represents the limits of human ability to tell two rhythmic events apart #cite(<nakamura_outer-product_2014>, form: "normal"), and is widely used within the field #cite(<shibata_non-local_2021>, form:"normal") 
  #cite(<kosta_mazurkabl:_2018>, form:"normal")
  #cite(<hentschel_annotated_2021>, form:"normal")
  #cite(<hu_batik-plays-mozart_2023>, form:"normal")
  #cite(<murphy_quantization_2011>, form: "normal")
  #cite(<romero-garcia_model_2022>, form:"normal")
  #cite(<foscarin_asap:_2020>, form:"normal")
  #cite(<peter_automatic_2023>, form:"normal").
Likewise, a music score will be represented as a strictly increasing sequence of symbolic events $(b_n) in RR^NN$. An extension of this formalism for polyphonic pieces is discussed in @ann1.\
Please note that, in both definitions, the terms of the sequence do not indicate the nature of the corresponding event (@chord, single note, @rest...). Moreover, in terms of time units, $(t_n)$ is expressed in @rtu, whereas $(b_n)$ is expressed in @mtu.\
With these definitions, let us formally define tempo :
#v(-.4em)
#definition[
  $T in (RR^*_+)^RR$ is said to be a formal tempo (curve) with respect to $(t_n)$ and $(b_n)$ when,\ for all $n in NN$, $integral_(t_0)^(t_n) T(t) dif t = b_n - b_0$
] <tempo_def>
#v(-.4em)
#proposition[
  Let $T in (RR^*_+)^RR$.\ $T$ is a formal tempo with respect to $(t_n)$ and $(b_n)$ iff\ $forall n in NN, integral_(t_n)^(t_(n+1)) T(t) dif t = b_(n+1) - b_n$
] <local_tempo>
#v(-.4em)
Since tempo is only observable between two events _a priori_, we introduce a definition for a canonical tempo $T^*$, also called immediate tempo.
#v(-.4em)
#definition[
  Given $(t_n)$ and $(b_n)$, respectively a performance and a score, the canonical tempo is defined as a stepwise constant function $T^* in (RR^*_+)^RR$ such that :\
  $forall x in RR^+, forall n in NN, x in bracket t_n, t_(n+1) bracket => T^*(x) = (b_(n+1) - b_n) / (t_(n+1) - t_n)$
] <tempo_definition>
#v(-.4em)
The reader can verify that this function is a formal tempo as defined in @tempo_def. From now on, we will assume by convention that $t_0 = 0 "RTU"$ et $b_0 = 0 "MTU"$.\

Even though there is a general consensus in the field as for the interest and informal definition of tempo, several formal definitions coexist within literature : #cite(<raphael_probabilistic_2001>, form: "normal"), #cite(<kosta_mazurkabl:_2018>, form: "normal") and #cite(<hu_batik-plays-mozart_2023>, form: "normal") choose definitions very similar to $T^*$, approximated at the scale of a @measure or a section for instance, whereas #cite(<nakamura_stochastic_2015>, form: "normal") and #cite(<shibata_non-local_2021>, form: "normal") use $1 / T^*$.\

When a performance perfectly fits theoretical expectations, $T^*$ has the advantage to coincide with the tempo indicated on a traditional sheet music (and therefore on a corresponding MusicXML) when expressed in BPM, hence allowing for a simpler and more direct interpretation of results.
== Computation of the canonical tempo <naive_use>

There exists a few datasets containing note-alignment matching between both music score and corresponding audio, more or less anotated with various labels #cite(<kosta_mazurkabl:_2018>, form:"normal")
#cite(<hentschel_annotated_2021>, form:"normal")
#cite(<hu_batik-plays-mozart_2023>, form:"normal")
#cite(<foscarin_asap:_2020>, form:"normal")
#cite(<peter_automatic_2023>, form:"normal").
For this study, we chose to rely on the (n)-ASAP dataset #footnote([https://github.com/CPJKU/asap-dataset]) that presents a vast amount of piano performances on MIDI format, with over 1000 different pieces of classical music, all note-aligned with their corresponding score. From there, we can easily visualize our definition of canonical tempo.\

@naive_curve presents the results for a specific piece of the (n)-ASAP dataset with a logarithmic y-scale, that shows two abrupt tempo changes, whilst maintaining a rather stable tempo value in-between.

#figure(
  image("../Figures/naive_version.png", width: 100%),
  caption: [
    Graph of $T^*$ for a performance of Islamey, Op.18,\ M. Balakirev, extracted from the (n)-ASAP dataset.
  ],
) <naive_curve>

In this graph, one can notice how $T^*$ (plotted as little dots) appears to be noisy over time; even though allowing to distinguish a tempo change at $t_1 = 130$ s and $t_2 = 270$ s. Both the sliding window average (dotted line) and median (full line) of $T^*$ seem unstable, presenting undesirable peaks, whereas the perceived tempo is quite constant for the listener. The median curve is a bit more stable than the average curve, as expected. There are two explanation for those results. First, fast events are harder to play exactly on time, and the very definition being a ratio with a small theoretical value at the denominator explains the deviation and absurd immediate tempo plotted. In fact, we can read that about 10 points are plotted over 400 BPM (keep in mind that usual tempo are in the range 40 - 250 BPM). Second, the notions of timing and tempo are merged in this computation, hence giving results that do not match the listener feeling of a stable tempo.  Actually, timing can be seen as expressive modifications to the "official" score. Using the score containing said modifications would allow for curves that fit better the listener feeling, though needing an actual transcription of the performance first.
For instance, if the performer plays "off-the-beat", with added syncopations, which is notably common in swing interpretations, one would need the actual transcription in order to define a meaningful tempo.
== Two physical models for tempo generation <large_modif>

Among the tasks requiring tempo generation, score following, that is the real time inference of tempo to allow a dedicated machine to play an accompagnement by following at least one actual musician, has been tackled by various approaches in literature. @raphael_probabilistic_2001 started with a probabilistic model, but those methods have found themselves replaced by a more physical understanding of tempo _via_ the notion of internal pulse, as explained by @large_dynamics_1999. In fact, a combination of these methods has recently been developped as a commercial product #footnote[https://metronautapp.com/], based on an a previous work by @antescofo.\
#v(0.4em)
The approach #cite(<large_dynamics_1999>, form: "normal") considers a simplified neurological model, where listening is a fundamentally active process, implying a synchronization between _observations_, i.e., external events (those of the performance) and _expectations_, here being an internal oscillator whose complexity depends of hypotheses on the shape of _observations_. The model consists of two equations for the internal parameters presented hereafter for all $n in NN$ :\
#let eq1 = nb_eq[$Phi_(n+1) = [Phi_n + (t_(n+1) - t_n) / p_n - eta_Phi F(Phi_n, kappa)] limits(mod)_"[-0.5, 0.5[" 1$];
#eq1 <large1>
#nb_eq[$p_(n+1) = p_n (1 + eta_p F(Phi_n, kappa))$] <large2>
where $Phi_n$ corresponds to the phase, or rather the phase shift at each event $t_n$ between the oscillator and the external events, $p_n$ embodies its period, $eta_p in RR⁺$ and $eta_Phi in RR⁺$ are both constant damping parameters, and $F$ is the correction at $t_n$ to match _expectations_ and _observations_.\

This initial model is then modified to consider a notion of attending _via_ the $kappa$ parameter, whose value changes over time according to other equations not showed here.\
We finally have : $F : Phi, kappa |-> exp(kappa cos(2pi Phi)) / exp(kappa) sin(2pi Phi)/(2 pi)$\

This model being fit for @bt, we modified it to consider score information in order to generate a more stable and precise value of tempo than the naive approach previously presented.
The modifications presented hereafter were made in order to keep consistency with respect to the original model theoretical framework of validity :\
#nb_eq($Phi_(n+1) = Phi_n + (t_(n+1) - t_n) / p_n - eta_Phi F(Psi_n, kappa)$) <largmodif>
#nb_eq($p_(n+1) = p_n (1 + eta_p F(Psi_n, kappa))$)\
#v(-1em)
$"where" #h(0.8em) &amin : a, b |-> cases(a "if" |a| < |b|, b "otherwise")\ &Psi_n = -amin (k + b_n - Phi_n, k + 1 + b_n - Phi_n) \ &k = floor(Phi_n - b_n)$\
Here, the $amin$ function is used in order to represent a choice between two corrections. The first argument can be interpreted as a correction with respect to the most recent passed beat time occuring exactly on a actual beat. Said beat is formally defined as $a_1 = limits(max)_(n in NN  " " : " " b_n <= Phi_i) floor(b_n)$ where $Phi_i$ is the internal value at time $i$ acting as a beat unit. The second argument embodies the correction according to $a_2 = a_1 + 1$, the following beat.
One can notice that the phase is actually always considered modulo $1$ in #cite(<large_dynamics_1999>, form: "normal"), since it appears only multiplied by $2pi$ in either $cos$ or $sin$ functions. Using this remark, one can verify that, in the initial presentation of the model with a metronome, i.e., $forall n in NN, b_n = 0 mod 1$, the extension proposed in $(3, 4)$ is equivalent to the original approach $(1, 2)$, hence justifying the designation "extension". 
We will from now on refer to this model as _Large et al._ since the modifications presented here were inspired by various works in literature, including #cite(<antescofo>, form: "normal"). The original model will not be considered in this report.\

Even though the latter has been validated experimentally in #cite(<large_dynamics_1999>, form:"normal"), and is still used in the presented version #cite(<large_dynamic_2023>, form: "normal"), a theoretical study of the system behavior remains quite complex, even in simplified theoretical cases, notably because of the function $F$ expression. #cite(<schulze_keeping_2005>, form:"normal") thus presents the _TimeKeeper_ model, that can be seen as a linearization of the previous approach, valid in the theoretical framework of a metronome presenting small tempo variations. In fact, there is a strong analogy between the two models, that are almost equivalent under specific circumstances #cite(<loehr_temporal_2011>, form: "normal"). We used the derandomised version considered by J. D. Loher et al. #cite(<loehr_temporal_2011>, form: "normal"). Using their analogy, we then obtain the following equations for _TimeKeeper_ :

#nb_eq($A_(i+1) = K_i (1 - alpha) + tau_i - (t_(i+1) - t_i)$)
#v(-.5em)
#nb_eq($tau_(i+1) = tau_i - beta times [K_i limits(mod)_"[-0.5, 0.5[" 1]$)\
#v(-1em)
$"where" #h(0.8em)&K_i = -amin (k tau + b_i - A_i, (k + 1)tau + b_i - A_i) \ &k = floor((A_i - b_i) / tau_i)$.\

Here, $A_i$ is the absolute asynchrony at time $t_i$, with a similar role than the phase shift in @large1, $alpha$ and $beta$ are both constant damping parameters, and $tau_i$ is the time value that represents the current tempo, similarly to the period in @large2.\
@large_curve displays the results of those two models, compared to the canonical tempo. One can notice that the _Large et al._ model is less stable than _TimeKeeper_, although faster to converge.
#v(-.55em)
#figure(
  image("../Figures/large_version.png", width: 100%),
  caption: [
    Tempo curve for the same performance of Islamey, Op.18, M. Balakirev, according to the models presented here
  ],
) <large_curve>

@init_curve illustrates the differences in managing an irrelevant tempo initialization value of the two models, starting here both with the initial tempo value of 70 BPM (♩ = 70, i.e., the _beat_ unit here is a quarter note). As expected, _TimeKeeper_ does not manage to converge to any significant tempo : its theoretical framework supposes small tempo variations (and preferably relevant initialization). However, _Large et al._ model manages to converge to a meaningful result. In fact, in the range 9 to 70 seconds, its estimated tempo is exactly half of the actual tempo hinted by the blue dots (canonical tempo). This is an example of a _tempo octave_, defined and discussed in @ann1.
#v(-.5em)
#figure(
  image("../Figures/large_nc_version.png", width: 100%),
  caption: [
    Tempo curve for a performance of Piano Sonata No. 11 in A Major (K. 331: III), W.A Mozart, according to the two previously modified models, with irrelevant initialization
  ],
) <init_curve>
#v(-.4em)
A solution to adress this latter problem could be to begin the computation from the end of the piece, and the going backwards to the start, hence hopefully obtaining a meaningful initialization value. Such a method is theoretically valid as explained in @ann1.
#v(-.75em)
= Scoreless approaches <score_less>
#v(-.4em)
The first issue with the two previous approaches is the requirement of both a reference score and a note-alignment between the given performance and the latter, which is something the field lacks at large scale. Therefore, we will now focus on methods for tempo estimation that *do not* require the prior knowledge of a reference score. However, we will suppose such a score actually exists, and use the notation $(b_n)$ to designate it for formal proofs. One may notice that in this framework, estimating $T^*$ is equivalent to transcribing the actual performance, which we can consider to be the most exact tempo curve one can compute. Since such a tempo cannot be uniquely determined (see @ann1 for details on the _tempo octave_ problem), we will here try to relax the problem by finding a "flattened" tempo curve that intuitively gives the general tempo hinted by $T^*$.
To a lesser extent, we will try to find methods that do not present salient sensitivity to tempo initialization, unstability nor require to accurately estimate relevant values of some constant internal parameters.\y According to our implementation, _Large et al._ model is a particularly chaotic model regarding the latter.\

This section presents two models, respectively based on #cite(<murphy_quantization_2011>, form: "normal") and #cite(<romero-garcia_model_2022>, form: "normal") that rely on the notion of @quantization, i.e., the process of converting real values into simple enough rational numbers, according to restrictions.

== Introduction of an estimator based approach <estimator_intro>

#definition(numbering: none)[Given a sequence $(u_n)$, let from now on $(Delta u_n) "be" (u_(n+1) - u_n)_(n in NN)$\
$(Delta u_n)$ embodies the durations of the different events of $(u_n)$. The previous expression is actually valid in monophonic pieces, under the hypothesis that the end of each note is exactly the begining of the next one. Since our framework is firstly monophonic, we will consider the given expression for durations, but this sequence could be defined otherwise in order to consider polyphonic pieces. Most of the following results do not depend on the actual expression of durations. See @ann1 and @ann2 for polyphonic considerations.]
#v(-.4em)
This first method aims at tracking tempo variation rather than actual values. Hence, we suppress the need for a convergence time. In fact, we search to estimate $alpha T^*$, where $alpha in RR^*_+$ is an unknown multiplicative factor that we try to make constant over time.
Using the formalism presented in III, we first present the following result since $T_n^* > 0$ :
#nb_eq($T^*_(n+1) = T_n^* (T^*_(n+1)) / T^*_n = T_n^* (Delta t_n) / (Delta t_(n+1)) (Delta b_(n+1)) / (Delta b_n)$)

Let $T_n$ be an estimation of $T_n^*$ by a given model at a given time $t_n$ and $alpha_n = T_n / T_n^*$. We obtain
$alpha_n T_(n+1)^* = underbrace(alpha_n T^*_n, T_n) (Delta t_n) / (Delta t_(n+1)) times (Delta b_(n+1)) / (Delta b_n)$\

In the above formula, the only value to actually estimate is therefore $(b_(n+2) - b_(n+1)) / (b_(n+1) - b_n)$, which allows for a locally constant shift in both our estimations of the numerator and denominator. Hence the resulting value is invariant by translation, or constant multiplication of our estimation of $(b_n)$. Furthermore, this value only deals with symbolic units, meaning that we can apply musical properties to find a consistent result.\

The point of this approach is to keep a constant factor between $(T_n)$ and $(T_n^*)$. We thus define $T_(n+1) = alpha_n T^*_(n+1)$, to find :\ #v(0.4em)
$(Delta b_(n+1)) / (Delta b_n) = (T_(n+1)^* Delta t_(n+1)) / (T_(n)^* Delta t_(n)) = (T_(n+1) \/ alpha_n) / (T_n \/ alpha_n) times (Delta t_(n+1)) / (Delta t_(n))$,#v(-0.1em)\
Hence #h(.2em)$(Delta b_(n+1)) / (Delta b_n) = T_(n+1) / T_n times (Delta t_(n+1)) / (Delta t_(n))$.\

If we manage to correctly estimate $T_(n+1)$, we can obtain a tempo estimation with the same multiplicative shift as the previous estimation $T_n$, thus by using the formula recursively, we obtain a model that can track tempo variations over time without any need for convergence, hence being robust to irrelevant tempo initialization, while using only local methods (i.e., the resulting model is @online). We then obtain :
#v(.35em)
#nb_eq($T_(n+1) / T_n = T^*_(n+1) / T^*_n = (Delta t_n) / (Delta t_(n+1)) underbrace(E(T_(n+1) / T_n times (Delta t_(n+1)) / (Delta t_(n))), display((Delta b_(n+1)) \/ (Delta b_n)))$) <estimator>
where $E$, designated by _estimator_, is supposed to act on a theoretical ground as an oracle that returns the correct value of the symbolic $(Delta b_(n+1)) / (Delta b_n)$ from the given real values indicated in @estimator. In practice, $E$ is actually a rhythmic quantizer.\

Given an estimator $E$, the tempo value defined as $T_(n+1)$, computed from both $T_n$ and local data, is obtained _via_ the following equation, where $x$ embodies $T_(n+1) / T_n$ in @estimator : \
#nb_eq($#h(-1.2em)T_(n+1) = T_n argmin_(x in [sqrt(2)/2 T_n, sqrt(2) T_n]) d(x, (Delta t_n) / (Delta t_(n+1)) E(x (Delta t_(n+1)) / (Delta t_(n)))) $) <estimatorf>
with $d : a, b |-> k_*|log(a/b)|, k_* in RR_+^*$ a logarithmic distance, choosen since an absolute distance would have favored small values by triangle inequality in the following process.\
Further explanations about @estimatorf can be found in @ann2.\

In the implementation presented here, the estimator role is to output a musically relevant value, given that the real durations contain (micro)-@timing. In our tests, we limited these outputs to be either regular divisions (i.e., powers of 2) or #gls("triplet", display: "triplets"). Furthermore, the numerical resolution for the previous equation was done by a logarithmically evenly spaced search and favored $x$ values closer to 1 (i.e., $T_(n+1)$ closer to $T_n$) in case of distance equality.\

Such a research allows for a musically explainable result : the current estimation is the nearest most probable tempo, and both halving and doubling the previous tempo is considered as improbable, and as further away from the initial tempo.\
#v(.45em)
@estim-perf-1 compares the canonical tempo and the tempo curve obtained by our naive estimator (here almost correctly initialized to simplify the interpretation of the result). One can notice that the constant distance between the two curves indicates in our logarithmic scale a constant multiplicative factor, except for the dotted line. There, the actual ratio of $T_(n+1)^* / T_n^*$ exceeds our bound of $[1/sqrt(2), sqrt(2) [$. Hence, the computation finds the representative within the range, here being $1/2 T_(n+1)^* / T_n^* > sqrt(2)/2$. This example illustrates that the values obtained through this method may be off by a power of $2$. @ann2 presents a formal study of this model adressing this problem.

#figure(
  image("../Figures/estimator_mozart_5.png", width: 100%),
  caption: [
    Normalized canonical tempo and estimation according to the model presented here for the first measures of Piano Sonata No. 11 in A Major (K. 331: III), W.A Mozart.
  ],
) <estim-perf-1>

#figure(
  image("../Figures/sonata-11.png", width: 100%),
  caption: [
    The first measures of Piano Sonata No. 11 in A Major (K. 331: III), W.A Mozart.
  ],
)\
#v(-1.6em)

== Towards a quantized approach <quanti>

#definition(numbering: none)[Let $f in RR^RR$ be a continuous function, $a in "dom"(f)$ is said to be a semi-strict local minimum (resp. maximum) of $f$ when $a$ is a local minimum (resp. maximum) of $f$, and $a$ is not a local maximum (resp. minimum) of $f$, or in other words, $f$ is not constant on a neighbourhood of $a$.]
#v(-.4em)
In this section, we extend the previous approach by considering the estimator as our central model and only then extracting tempo values rather than the opposite. We based our work on G. Romero-García et al. #cite(<romero-garcia_model_2022>, form:"normal") with the previous formalism.

Let $n in NN^*$ and $D subset (R^+)^n$ be a set of some durations of real time events. The function $epsilon_D$ is defined by #cite(<romero-garcia_model_2022>, form: "normal") as :
$ epsilon_D : a |-> max_(d in D) min_(m in ZZ) thick |d - m a| $ <epsi_def>
This continuous function is called the _transcription error_, and can be interpretated as maximum error (in RTU) between all real events $d in D$ and theoretical real duration $m a$, where $m$ is a symbolic notation expressed in arbitrary symbolic unit, and $a$ a real time value corresponding to a @tatum at a given tempo. We proove in @gonzalo_spectre that the set of all semi-strict local maxima of $epsilon_D$ is : #nb_eq($M_D &= {d / (k+1/2), d in D, k in NN}\ &= limits(union.big)_(d in D) {d/(k+1/2), k in NN}$) <local_maxima>
In fact, each of these local maxima corresponds to a change of the $m$ giving the minimum in the expression of $epsilon_D$, hence the following result : in-between two such successive local maxima, the quantization remains the same, i.e. @same_quantization :
#v(-.4em)
#proposition[Let $m_1, m_2$ be two successive local maxima of $epsilon_D$, $a_1 in ]m_1, m_2[, a_2 in [m_1, m_2], d in D$ and $m in ZZ$.\ Then $m in display(argmin_(k in ZZ)) |d - k a_1| => m in display(argmin_(k in ZZ)) |d - k a_2|$.] <same_quantization>
#corollary[Let $d in D, a in RR^*_+, A = limits(argmin)_(k in ZZ) |d - k a|$.\
Then : $0 < |A| <= 2$ and $|A| = 2 <=> a in M_D$.] <card_A>
#v(-.4em)
#proof[$A subset {floor(d/a), floor(d/a) + 1}$, $limits(lim)_(|k| -> +infinity) |d - k a| = +infinity$, hence $A != emptyset$.
Finally, let $k = floor(d/a)$,\
#v(.5em)
$|A| = 2 &<=> A = {floor(d/a), floor(d/a) + 1}\
&<=> |d - k a| = |d - (k+1) a| = 1/2\
&<=> a = d/(k + 1/2) <=> a in M_D$]

With this property, we can then choose to consider only semi-strict local minima of $epsilon_D$ as in #cite(<romero-garcia_model_2022>, form: "normal"), since there is exactly one semi-strict local minimum in-between two semi-strict local maxima, and choosing any other value in this range would result in the exact same transcription, with a higher error by definition of a local minimum (that is global on the considered interval). The correctness of the following algorithm to find all local minima within a given interval is proven in @gonzalo_spectre.
#v(-.5em)
#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  caption: [Finds all semi-strict local minima of $[$start, end$]$],
pseudocode-list(booktabs: true, hooks: .5em, title: [FindLocalMinima($D != emptyset$, start, end) :])[
  + $M <- {d / (k + 1/2), d in D, k in [|d/"end", d/"start"  |]} $
  + $P <- {(d_1 + d_2) / k, (d_1, d_2) in D^2, k in [|(d_1+d_2)/"end", (d_1+d_2) / "start"|] sect NN^*} $
  + $"localMinima" <- emptyset$
  + *for* $(m_1, m_2) in M^2$ two successive local maxima :
    + $"in_range" <- {p in P : m_1 <= p < m_2}$
    + $"localMinima" <- "localMinima" union {min("in_range")}$
  + *return* $"localMinima"$
]) <algonzalo>
#v(-.35em)
#cite(<romero-garcia_model_2022>, form: "normal") then defined $G = (V, E)$ a graph whose vertices are the semi-strict local minima of $epsilon_D$, where $D$ is a sliding window, or _frame_, on a given performance, and whose edges are such that they can guarantee a _consistency property_, explained hereafter.

The _consistency property_ for two tatums $a_1, a_2$ specifies that, for all $d in F_sect$ where $F_sect$ is the set of all values in common between two successive frames, $d$ is equally quantized according to $a_1$ and $a_2$, i.e., the symbolic value of $d$ is the same when considering either $a_1$ of $a_2$ as the duration of a given tatum at some tempo (respectively $1/a_1$ and $1/a_2$, as shown in @quanti_revised). From these definitions, we can now define a _tempo curve_ as a path in $G$. In fact, #cite(<romero-garcia_model_2022>, form: "normal") call such a path a _transcription_ rather than a tempo curve, yet, since an exact tempo curve would be $(T_n^*)$, these two problems are equivalent.

Actually, the consistency property is not that restrictive when considering tempo curves. Let $F_1, F_2$ be two successive frames, $F_sect = F_1 sect F_2$, $d in F_sect$, and $p$ a path in $G$ containing a local minimum $a_1$ of $epsilon_F_1$. According to @local_maxima, we can divide the set of all semi-strict local maxima in two, with those "caused" by $F_sect$, $M_F_sect$, and the others. Let then $m_1, m_2 in M_F_sect$. These are local maxima for both $epsilon_F_1$ and $epsilon_F_2$ by @local_maxima since $F_sect subset F_2$, and therefore there is at least one local minimum within the range $]m_1, m_2[$ for both of these functions. However, thanks to @same_quantization, we know that both these local minima will equally quantize the elements of $D$. Hence, by defining :
- #v(.1em)$m_1 = max{m in M_F_sect : m < a_1}$#v(.3em)
- $m_2 = min{m in M_F_sect : m > a_1}$#v(.3em)
- $a_2$ a local minimum of $epsilon_F_2$ in the range $]m_1, m_2[$, which exists since $m_1$ and $m_2$ are semi-strict local maxima,
#v(-.55em)
$(a_1, a_2)$ is _consistent_ according to the consistency property.

#corollary(numbering: none)[The consistency property only implies restrictions relative to the interval of research. In other words, any given strictly partial path $p$ in $G$ can be extended to a _consistent_ path, even if it means considering a larger interval, for any given performance, and any given frame length used to define $G$.]
#v(-.2em)
#remark[This approach supposes that we can define a tatum within all frames i.e., that there is a real value of the same tatum that can maintain a single value within the frame. In other words, let $a$ be the symbolic value of a given tatum, $n in NN$, and $F = {f_1, ..., f_n}$ a given frame. If we suppose all the events of F to embody a musical meaning, we can define an immediate tempo for each of them, and therefore we can express $a_i$ the value of $a$ in RTU at the tempo $t_i$ corresponding to $f_i$, $i in [|1, n|]$. In order for this approach to be meaningful, we then need the existence of $hat(a) in RR^*_+$ such that each $f_i$ is equally quantized according to $a_i$ and $hat(a)$. Since, by definition, $f_i$ is quantized by $f_i times t_i$, we obtain the following definition.
] <tatum_exist>
#v(-.4em)
#definition[With the notations introduced in @tatum_exist, a tatum $a in RR^*_+$ is said to have an actual meaning with respect to a frame $F = {f_1, ..., f_(|F|)}$ when, for all $i in [|1, |F| |], f_i times t_i in limits(argmin)_(k in ZZ) (f_i - k hat(a))$.]
#v(-.4em)
#proposition()[When $t_i = t$ for all $i in [|1, |F| |]$, $1/t$ has an actual meaning with respect to $F$.] <constant_tempo>

== Quantization revised <quanti_revised>

We choose to define our tatum $epsilon$ as $1/60 ♩$, which corresponds to a sixteenth note (i.e., 𝅘𝅥𝅯) wrapped within a triplet within a quintuplet, and has the property that $1 " " epsilon"/sec" = 1 "♩/min"$.
This definition implies that we restrain to symbolic durations that are integer multiples of $epsilon$ in our framework. Hence, we can take $epsilon$ as our MTU. We then have $T := (Delta b) / (Delta t) = (1 epsilon) / a$, where $a$ is the theoretical duration of $epsilon$ at tempo $T$.
From there, we can define $sigma_D : a |->  1/a epsilon_D (a)$ the _normalized error_, or _symbolic error_, which embodies the error between a transcription $m$ of $d in D$ expressed in tatum (thus a quantized and valid transcription), and $d times 1/a = d times T$, which is the expression of the symbolic duration of $d$ at tempo $T$ according to @tempo_definition.
#v(-.2em)
#definition[Let $A subset RR$ a countable set and $f : A -> RR$.\
$a in A$ is said to be a local minimum of $f$ when :\
$exists eta in RR^*_+ : forall a' in Eta := {a' in A : |a - a'| <= eta},$\
$ f(a') >= f(a) and sup(Eta) > a > inf(Eta)$.]
#v(-.4em)

#h(1em)In order to reduce the amount of local minima considered during computation, we propose the following conditions on a local minimum $a$ of $epsilon_D$, where $m = {a' in m_D : a' >= a}$ with $m_D$ the set of all semi-strict local minima of $epsilon_D$  :
+ $forall a' in m, epsilon_D (a) <= epsilon_D (a')$
+ $forall a' in m, sigma_D (a) <= sigma_D (a')$
+ $a$ is a local minimum of $lambda_1 : x in m_D |-> epsilon_D (x)$
+ $a$ is a local minimum of $lambda_2 : x in m_D |-> sigma_D (x)$
#v(-.5em)
Since $2 => 1$ and $4 => 3$, one can only consider conditions $2, 4$.

We present here a modified version of #cite(<romero-garcia_model_2022>, form: "normal") introduced in the previous section. We similarly define a graph $G = (V, E)$, with the relaxation that the edges no longer guarantee the consistency property. In order to define our tempo curves, we then sequentially define paths in $G$ according to the following process, where $d$ is a logarithmic distance, $P$ is the set of all possible paths, and $A_n$ the set of all local minima of $epsilon_F_n$ ; $F_n$ being the n-th frame.\
#v(-.4em)
#definition[A path $p = (p_1, ..., p_f)$ in $G$ is said to be a fixpoint when there exists a path $p' = (p'_1, ..., p_f)$ in $G$ such that $forall i in [| 1, |p'|-1|],$
$p'_(i+1) in limits(argmin)_(s in A_(i+1)) d(s, p'_i)$,\
and $p'_1 in limits(argmin)_(s in A_1) d(s, p_f)$.]
#v(-.4em)
#figure(
  kind: "algorithm",
  supplement: [Algorithm],
  caption:[Returns potential tempo curves of a performance],
pseudocode-list(booktabs: true, hooks: .5em, title: [FindPotentialPaths(performance, frame_length, start, end) :])[
  + $F_1 <- {p_i in "performance", i in [|1, "frame_length"|]}$
  + $P <- "FindLocalMinima"(F_1, "start", "end")$
  + *for* $n$ corresponding to a frame :
    + $F_n <- {p_(n+i) in "performance", i in [|1, "frame_length"|]}$
    + $A_n <- "FindLocalMinima"(F_n, "start", "end")$
    + *for* all path $p = (p_1, ..., p_n)$ in P :
      + $p_(n+1) <- limits(argmin)_(a in A_n) d(p_n, a)$
      + $p <- (p_1, ..., p_n, p_(n+1))$
  + *return* the fixpoints of $P$
]) <find_potential_path>
#v(-.4em)
We prove in @gonzalo_spectre that this algorithm is correct under some hypotheses, notably that the final tempo of the section is the same as the one at the begining, which is true in particular if the tempo is quasi-constant during the considered section.

== Raw results and comparison with @score_based

All the tempo curves presented in this section have been obtained on performances without abrupt tempo changes. In order to output a single curve, we choose here to select the path whose first tatum value corresponds to the nearest tempo to a given initialization value, according to $d$.
#v(-.5em)
#figure(image("../Spectros/image.png", width: 100%), caption: [Potential tempo curves and canonical tempo for a performance of J-S. Bach, Italian Concerto, BWV 971]) <raw_output>

#figure(image("../Figures/compar_II_III.png", width: 100%), caption: [Comparison of different models for the previous performance of J-S. Bach, Italian Concerto, BWV 971]) <esti_result>
#v(-.6em)
#figure(image("../Figures/compar_II_III_2.png", width: 100%), caption: [Comparison of different models for the same performance of J-S. Bach, Italian Concerto, BWV 971]) <esti_result2>\
#v(-1.7em)
@raw_output presents the potential tempo curves (black dots) and actual canonical tempo (blue stars). @esti_result illustrates that the estimator approach is sensitive to tempo octaves, hence we only plotted values within the range [10, 100]. Even though, the associated transcription appears satisfying, there would need for an actual formatting of said transcription in order to obtain satisfying tempo values. The latter is done on @esti_result2, where one can see the tempo curve hinted by the estimator approach is actually really similar to the mean of the canonical tempo notably presented in @naive_curve, though less unstable. However, such an approach needs for post-processing, and a way to determine the constant factor (obtained _via_ _Large et al._ model here).
The quantized approach - which do not require such heavy post-processing - appears more stable than the methods presented in @score_based, as shown by @large_quanti.
#v(-.75em)
#figure(image("../Figures/compar_large_quanti.png", width: 100%), caption: [Comparison of different models for a performance of M. Ravel, _Pavane pour une infante défunte_]) <large_quanti>
#v(-1.9em)
= Applications

== A method for (monophonic) data augmentation <data_gen>

Let $(Delta t_n), (T_n^*), (T_n)$ be respectively a performance, the canonical tempo for this performance, an estimated tempo curve (supposed to be flattened with respect to the canonical tempo) and $T_c in R^*_+$ a given tempo value.
#definition[We define the symbolic shift of the performance according to $(T_n^*)$ and $(T_n)$ as $(s_n := Delta t_n (T_n - T_n^*))$. ]

#definition[The _normalized_ performance at tempo $T_c$ is defined as :
$hat(t)_0 = t_0, hat(t)_(n+1) = hat(t)_n + underbrace(Delta t_n T_n^* / T_c, alpha_n) + underbrace(s_n / T_c, beta_n) forall n in NN$.]
#v(-.6em)
Here $a_n$ represents the new duration of $Delta t_n$ at tempo $T_c$, since $alpha_n = (Delta b_n) / T_c$, and $beta_n$ embodies the actual time shift at tempo $T_c$.

#proposition[$(hat(t)_n)$ is indeed a performance, as defined in @formal_consider. Furthermore, $(hat(T)_n^*) = ((Delta b_n) / (Delta hat(t)_n)) = (1 / (1 + s_n / (Delta b_n)) T_c)$.] <canonical_v>
#v(-.8em)
#proof[
For all $n in NN^*$ :\
$Delta hat(t)_n &= alpha_n + beta_n = Delta t_n / T_c (T_n^* + T_n - T_n^*) = Delta t_n T_n / T_c > 0$\
Furthermore, $hat(T)_n^* = (Delta b_n) / (Delta hat(t)_n) = (Delta b_n) / (Delta b_n / T_c + s_n / T_c) = 1 / (1 + s_n / (Delta b_n)) T_c$]
#v(-.2em)
#remark(numbering: none)[In order to adapt this formalism for polyphonic pieces, one should also consider a shift in terms of onsets in addition to the shifts in terms of duration considered here.]
#v(-.4em)
Depending on the use of this data, one can choose to adapt the definition of $(s_n)$, for instance by normalizing its values or cutting all shifts that represent over a certain portion of their duration. @canonical_v illustrates how such definitions of $(s_n)$ allow for guarantees on deviations of the canonical tempo for the _normalized_ performance with respect to $T_c$.\

== Monophonic performance generation <perf-gen>

By considering the set of all shifts obtained from various performances, that one can see as a rhythmic language, and trying to generate a word of this language (i.e., a rhythmic template for a performance), we can generate rough performances from a given score. A few examples of such generated pieces are to be found on #cite(<git>, form: "normal"). A more subtle method could be to train some algorithms to reproduce rhythmic patterns within a database depending on the context of a particular piece (rhythmic (un)stability, begining of a @phrase, @cadence...), as score features may sometimes eclipse individual styles #cite(<Kosta2016Mapping>, form: "normal").

== Quantitative musicological analysis

A formal definition for time-shifts allows for a quantitative, and statistical analysis of human performances regarding the latter. The analysis of quantitative variations of the canonical tempo at the end of a phrase, or depending on the kind of cadence already exist within literature #cite(<kosta_mazurkabl:_2018>, form:"normal") #cite(<hentschel_annotated_2021>, form:"normal") #cite(<hu_batik-plays-mozart_2023>, form:"normal"), and could be complemented with such a study.
#colbreak()
== MIDI transcription

The methods presented in @score_less could be used as pre-processing for transcription problems, allowing to add complementary data with respect to the transcription (such as tempo stability, consistency, and potentially tempo changes).
#v(-.4em)
= Conclusion & perspectives <conclusion>

We presented here some methods for @monophonic tempo analysis, with applications to data augmentation (@data_gen), rough performance generation (@perf-gen), and transcription. The latter could allow for further development in addition to a generative grammar for global consistency, as a multi-criteria optimisation #cite(<foscarin2019parse>, form: "normal") including tempo stability, specifically when coupled by a method similar to @quanti_revised.\
In particular, a dynamic programming algorithm could be used to detect potential abrupt tempo changes, or quasi-constant tempo sections.
Even though we focused here on monophonic works, or rather on monophic views of performances, the very definition of canonical tempo presented here is more fit for monophonic pieces than polyphonic ones. The reader shall find some extensions of this formalism suited for polyphonic works in @ann1.

@quanti_revised also presented a model which appears to share some similarities with the _Large et al._ model (@large_modif), modified as a score-based method. Therefore, studying the formalism for a quantizer might allow to obtain some theoretical results for the previous model, regarding for instance time of convergence guarantee and meaningfulness of the result.

Finally, the most immediate case of use of @data_gen is fuzz testing for algorithm in tasks such as beat-tracking, transcription or tempo inference. In fact, this section presented a way to "midify" an actual performance, that we can see as a function from the set of musical human performances to the set of plain and flat midi files as generated by standard softwares. Being able to reverse this function could then allow for generating convincing performances. We presented in @perf-gen a rough way to extrapolate such data augmentation for performance generation, that could be improved with formal langage algorithms or machine learning techniques.

#bibliography("refs.bib", title: "References")

#colbreak()

#appendix([Some formal considerations], [
== Proof of @local_tempo

Let $n in NN$,
$integral_(t_0)^(t_(n)) T(t) dif t = limits(sum)_(i = 0)^(n-1) integral_(t_i)^(t_(i+1)) T(t) dif t$\
#v(.8em)
$"Furthermore", integral_(t_n)^(t_(n+1)) T(t) dif t &= integral_(t_0)^(t_(n+1)) T(t) dif t + integral_(t_n)^(t_0) T(t) dif t \ &= integral_(t_0)^(t_(n+1)) T(t) dif t - integral_(t_0)^(t_n) T(t) dif t$\
Let $T$ be a formal tempo according to the first definition.\
For all $n in NN$, we then have :\ #v(.2em) $integral_(t_n)^(t_(n+1)) T(t) dif t &= integral_(t_0)^(t_(n+1)) T(t) dif t - integral_(t_0)^(t_n) T(t) dif t\
&= b_(n+1) - b_0 - (b_n - b_0)\
&= b_(n+1) - b_n$\
Let $T$ be a formal tempo according to the second definition. For all $n in NN$ :\ #v(.2em)
$integral_(t_0)^(t_(n)) T(t) dif t &= limits(sum)_(i = 0)^(n-1) integral_(t_i)^(t_(i+1)) T(t) dif t\
&= limits(sum)_(i = 0)^(n-1) b_(i+1) - b_i\
&= b_n - b_0$\
We thus obtain the two implications, hence the equivalence stated in @local_tempo.

== The *tempo octave* problem <tempo_oct>

When defining tempo, or transcribing a performance, there always exist several equivalent possibilities. For instance, given a "correct" transcription $(b_n)$ of a performance $(t_n)$, one can choose to define its own transcription as $t = (b_n / 2)$.\
Then, the canonical tempo with respect to $t$, called $(T_1^*)$, and the one with respect to $(b_n)$, called $(T_2^*)$ verify :\
$forall n in NN, T_(1, n)^* = (1/2 b_(n+1) - 1/2 b_n) / (t_(n+1) - t_n) = 1/2 T_(2, n)^*$.
Actually, the transcription $t$ corresponds to $(b_n)$ where all durations are indicated doubled, but played twice faster, hence giving the exact same theoretical performance. Unfortunately, there is no absolute way to decide which of these two transcription is better than the other. This problem is known as the tempo octave problem, and should be kept in mind when transcribing, or estimating tempo. We present in @estimator_intro a model robust to these tempo octaves, and other kind of octaves not discussed here (for instance multiplying the tempo by $3$ using @triplet).


== Tempo conservation when reversing time

First, we want to insist on the fact that none of the sequences $(b_n)$ and $(t_n)$ are infinite, but in order to simplify the notation, we chose to indicate them as usual infinite sequences, or rather only consider them on a finite number of indexes, refered to as $|(b_n)|$ and $|(t_n)|$ respectively, with $|(b_n)| = |(t_n)|$. Let us then define the reversed sequence of $(u_n)$ as $r((u_n)) := (overline(u_n) = u_(|(u_n)|) - u_(|(u_n)| - n))_(n in [|0, |(u_n)| |])$\
Both $overline(b) = r((b_n))$ and $overline(t) = r((t_n))$ are correct representations of a music score and performance respectively, as defined in @formal_consider.\
Let $q = |(t_n)|$, $t^* = t_q$, $T$ a formal tempo with respect to $(t_n)$ and $(b_n)$, $n in [| 0, q - 1|]$ and $T_r : t |-> T(t^* - t)$.

$integral_(overline(t_n))^(overline(t_(n+1))) T_r (t) dif t &= integral_(t^* - t_(q - n))^(t^* - t_(q - n-1)) T(t^* - t) dif t = integral_(t_(q - n))^(t_(q - n - 1)) -T(x) dif x\
&= integral_(t_(q - n - 1))^(t_(q - n)) T(t) dif t\
&= b_(q - n) - b_(q - n - 1)\
&= (b_(q - n) - b_q) - (b_(q - n - 1) - b_q)\
&= - overline(b_n) + overline(b_(n+1))\
&= overline(b_(n+1)) - overline(b_n)$

Hence $T_r$ is a formal tempo with respect to $(overline(t_n))$ and $(overline(b_n))$.

== Musical explanation of the choice of  a tempo distance

In terms of tempo, halving and doubling are considered as far as each other from the initial value. Therefore a usual absolute distance does not fit this notion, and we will rather use a logarithmic distance when comparing tempi.
]) <ann1>

== Monophony and polyphony

@tempo_definition is valid when considering @monophonic pieces. In order to adapt the formalism for polyphony, one should consider the sequence $(b_n)$ to be increasing (but not necessarily strictly), and instead of using $b_(n+1) - b_n$, the sequence $(Delta b_n)$ embodying the different durations of the events should be defined. The same modifications applied to $(t_n)$ allow for defining a polyphonic performance of a polyphonic piece. However, in such a piece, the tempo may vary between the different voices, hence different formalisms for tempo may be defined, especially for a formal tempo curve.\ \

Nonetheless, according to @quanti_revised and @data_gen, defining a single global tempo for all voices, and considering deviations as #gls("timing", display: "timings") may be the easiest way to extend our formalism, although more studies should be done in order to verify this assumption.\ \
Therefore, the canonical tempo for a polyphonic performance $(t_n)$  of a polyphonic piece $(b_n)$ is defined as $T_n^* = (Delta b_n) / (Delta t_n)$, for all $n in NN$ in all our polyphonic works.\ 

#appendix([Estimator Model], [

== Formal explanations and proofs
First $d$ is indeed a mathematical distance : let $a, b in (R^*_+)^2, d(a, b) = d(b, a)$ and $d(a, b) = 0 <=> abs(log(a/b)) = 0 <=> a = b$. Finally, let $c in R^*_+, d(a, c) = k_* abs(log(a/c)) = k_* abs(log(a/b times b/c)) = k_* abs(log(a / b) + log(b / c)) <= d(a, b) + d(b, c)$.\ \
Then, formula of the model is valid on a monophic context, where all the grace notes are explicit (in other words, $(b_n)$ is strictly increasing).\
\
The estimator $E$ is not exactly a function in practice. Its actual expression is only supposed to remains the same between two computations of $T_n$, in order for the $argmin$ to make sens, as explained hereafter.
@estimatorf presents an $argmin$, that makes sense when $E$ is a increasing right-continuous function-like object, even though its actual expression may change after each computed value of $T_(n+1)$. In fact, $E$ can only output a countable set of values, hence $E$ is piecewise constant under those hypothesis.\ \
Finally, one can notice that the value of $k_* in R^*_+$ does not affect the result of the process.

==  About the range $[sqrt(2)/2 T_n, sqrt(2) T_n]$

In order to resist to the tempo octave problem discussed in @ann1, we choose here to consider a unique candidate within a range $[x, 2x] subset [1/2, 2]$, for a given $x in R^*_+$. Then, we want this range to be centered around $1$, since its values corresponds to tempo variation, and our system should not favor increasing nor decreasing the tempo _a priori_. For this musical reason, we then take $x$ as solution of : $norm(x - 1) = norm(2x - 1)$ that implies $1 - x = 2x - 1$, i.e., $x = 2/3$ with the absolute value distance.\
With a logarithmic distance, the same reasoning would give : $log(1/x) = log(2x) <=> -log(x) = log(2) + log(x) <=> log(x^2) = -log(2) <=> x^2 = 1/2 <=> x = sqrt(2) / 2$ since $x > 0$.\ \
Then, when considering the tempo distance between $T_(n+1)$ and $T_n$, we find : #nb_eq($d(T_(n+1), T_n) = k_* abs(log(y)) = d(1, y)$)
where $y = limits(argmin)_(x' in [x, 2x]) d(x', (Delta t_n) / (Delta t_(n+1)) E(x' (Delta t_(n+1)) / (Delta t_(n))))$.\
Therefore, since we want the extreme possible values of our range to imply an equal distance between $T_n$ and $T_(n+1)$, we choose the logarithmic distance, and hence $x = sqrt(2) / 2$, so that $d(1, x) = d(1, 2x)$.\

In fact, those two distances give the same results according to the measure. We favor the logarithmic since it embodies more musical meaning.

== About the estimator $E$

One can notice that $E = id$ implies, by the hypothesis that $E$ acts as an oracle, that the theoretical and actual values are the same, or that the performance is a perfect interpretation of the piece. Since real players do not make such performance, we can expect a relevant estimator to act rather differently than the identity function.

Moreover, $E$ is not a function : its expression only has to be fixed when computing the numerical resolution for the $argmin$. Hence, an given output can depends on several previous outputs. In an extreme case, $E$ can even be a transcripting system. However, in our problem of tempo estimation, we do not have as much constraints as in transcription.\
Indeed, the following figures displays two transcription A and B and their corresponding tempo curves. The latter transcription is actually incorrect with regards to usual transcription convention, with inconsistent duration for a measure that do not match the indicated time signature, and increased reading complexity with respect to transcription A.\

#grid(
  align: bottom,
  columns: (auto, auto),
  rows: (auto),
  figure(image("../Figures/Ugly_castle-Piano-2.png", width: 100%), caption: [Transcription A]), figure(image("../Figures/Ugly_castle-Piano-1.png", width: 100%), caption: [Transcription B])
)

#figure(image("../Figures/tempo_curves.png", width: 100%), caption: [Tempo curves A and B plotted together])

One can notice that these tempo curves are quite similar, and in fact, a human being could not tell them apart, as shown by @tempo_distance.

#grid(
  align: bottom,
  columns: (auto, auto),
  rows: (auto),
  [#figure(image("../Figures/tempo_distance.png", width: 100%), caption: [Tempo distance (s)]) <tempo_distance>], figure(image("../Figures/tempo_distance2.png", width: 100%), caption: [Tempo distance (log)])
)

Tempo distance between the two previous curves. Being able to differentiate them would imply to tell apart two rhythmic events within 4 ms, which is supposed impossible for a human being according to the value of $epsilon$ defined in @formal_consider (and displayed as the top line in @tempo_distance).
]) <ann2>

== Formal study of the model <study_of_esti>

Since this approach fundamentally search to estimate tempo variation rather than actual values, it is not easy to visualize the relevance of the result by naive means. We choose here to define the sequence of ratios $(alpha_n := T_n / T_n^*)_(n in [|1, N|])$, and then$(tilde(alpha)_n := exp(ln(alpha_n) - floor(log_2 (alpha_n)) ln(2)))_(n in [|1, N|])$. The latter is called the _normalized_ sequence of ratio, where each value is uniquely determined within the range $[tilde(1), tilde(2)[$. Such a choice allows for merging together the tempo octaves, as explained in @ann1. One can notice that adding $tilde(1)$ to a normalized value is equivalent to multiplying the initial value by $2$.
We now define a _spectrum_ $S = (tilde(alpha)_n)_(n in [|1, N|])$, and call $|S|$ the value $N in NN$. Finally, we define $cal(C)$ the range $[tilde(1), tilde(2)[$ seen as a circle according to the following application : $c : [tilde(1), tilde(2)[ &-> cal(C)(0, 1)\ tilde(x) &|-> (cos(2pi tilde(x)), sin(2pi tilde(x)))$, so that $c(tilde(1)) = c(tilde(2))$

#figure(image("../Figures/spectre_mozart_full.png", width: 100%), caption: [Distribution of $(alpha_n)$ for a monophic piece])

#figure(image("../Figures/spectre_mozart_full_normalised.png", width: 100%), caption: [Distribution of the spectrum $(tilde(alpha)_n)$ for the same piece])

#definition[Let $S$ be a spectrum, and $Delta in [0, 1/2]$.\
We define as follow the _measure_ of $S$ with imprecision $Delta$, that embodies a standard deviation on $cal(C)$ :
#nb_eq[$m(S, Delta) = max_(tilde(d) in cal(C)) ( |{n in [|1, |S| |] : d(tilde(alpha)_n, tilde(d)) <= Delta}|) / (min(1, |S|))$]
]

Here $d$ is still a logarithmic distance with $k_* = 1/ln(2)$, slightly modified on $cal(C)$ to be consistent with $d(tilde(1), tilde(2)) = 0$.\ Actually, $d : tilde(a), tilde(b) |-> min(abs(log_2(tilde(a) / tilde(b))), 1 - abs(log_2(tilde(a) / tilde(b))))$ on $cal(C)$.

#proposition[Let $a, b in (RR^*_+)^2, tilde(a^(-1)) times tilde(a) = tilde(1)$, and $tilde(a b) = tilde(tilde(a) b)$]

#definition[Let $S$ be a spectrum and $lambda in RR^*_+$, we define the rotation of $S$ by $lambda$ as : $lambda S = (tilde(lambda S_n))_(n in [| 1, |S| |])$]

#proposition[Let $Delta in [0, 1/2], lambda in RR^*_+$ and $S$ a spectrum.\
Let $S'$ be the spectrum of the same initial values as $S$, but normalized within the interval $[tilde(lambda), tilde(2 lambda)[$ instead of $[tilde(1), tilde(2)[$, and $S^(-1) := (tilde(1/alpha_n))_(n in [| 1, |S| |])$\
Then :
- $m(S', Delta) = m(S, Delta) = m(S^(-1), Delta) = m(lambda S, Delta)$
- $0 <= m(S, Delta) <= 1$
- $m(S, Delta) = 0 <=> |S| = 0$
- $m(S, Delta) = 1 <=> forall (tilde(a), tilde(b)) in S^2, d(tilde(a), tilde(b)) <= 2 Delta$
]

This _measure_ allows to quantify the quality of this model, without considering tempo octaves, or equivalently to quantify the quality of the estimator. A C++ implementation of this measure is available on #cite(<git>, form: "normal"), as well as the detailled performance of our test model over the (n)-ASAP dataset. @estim-perf presents those results in a global display. The blue values corresponds to the pieces written by W.A Mozart, that usually contain mainly regular division, and thus are expected to produce a _measure_ closer to 1 than average. On the other hand, the red values corresponds to M. Ravel's pieces, much more rhythmically expressive, hence we expect a _measure_ closer to 0. To understand the global results, we present in @estim-rand the same results for a random estimator.

#figure(
  image("../Figures/estimator_results_over_ASAP.png", width: 100%),
  caption: [
    Measures of the resulting spectrum over the whole (n)-ASAP dataset with $Delta = 0.075$, with naive estimator.
  ],
) <estim-perf>

#figure(
  image("../Figures/estim_perf_poly.png", width: 100%),
  caption: [
    Measures of the resulting spectrum over the whole (n)-ASAP dataset with $Delta = 0.075$, with naive estimator.
  ],
) <estim-perf-poly>

#figure(
  image("../Figures/compar_poly_mono.png", width: 100%),
  caption: [
    Comparison between the two latters.
  ],
)

#figure(
  image("../Figures/mono_estim_perf_025.png", width: 100%),
  caption: [
    Measures of the resulting spectrums over the whole (n)-ASAP dataset with $Delta = 0.025$, with $63%$ over mean.
  ],
)

#figure(
  image("../Figures/poly_estim_perf_025.png", width: 100%),
  caption: [
    Measures of the resulting spectrums over the whole (n)-ASAP dataset with $Delta = 0.025$, with 51% over mean
  ],
)

#figure(
  image("../Figures/poly_estim_perf_075.png", width: 100%),
  caption: [
    Measures of the resulting spectrums over the whole (n)-ASAP dataset with $Delta = 0.075$, with 62% over mean
  ],
)

#figure(
  image("../Figures/random_estim_perf.png", width: 100%),
  caption: [
    Measures of the resulting spectrums over the whole (n)-ASAP dataset with $Delta = 0.075$, with an estimator outputing random quantized values.
  ],
) <estim-rand>

@estim-perf shows results indicating that our naive estimator performs well on pieces with regular division and small tempo changes, which is typically the style of the classical era. The random estimator could actually output regular division, and to a lesser extent triplets (with a lower probability). Hence, it performed better than the naive one for a few pieces, especially those containing such irregular divisions. Finally, our naive estimator has $34.2 %$ of its value strictly over its average, whereas this value is $27.6 %$ for the random estimator.

Absolute distance and log distance presents the same results regarding the measure value.

#figure(
  image("../Figures/spectre_mozart_full_normalised.png", width: 100%),
  caption: [
    Example of a spectrum for a performance of a Mozart piece with our naive estimator in a monophic context
  ],
)


#figure(
  image("../Figures/spectre_mozart_random_full.png", width: 100%),
  caption: [
    Example of a spectrum with random estimator. Such a spectrum actually reflects the distribution of ratios throughout the piece's actual score
  ],
)
#appendix([Quantized Model], [
In this section we use the notation introduced by @romero-garcia_model_2022, that essentially replace $D$ by $T$.

Let us first define : $g : x |-> min(x - floor(x), 1 + floor(x) - x)$\
One can make sure that $g : x |-> cases(x  - floor(x) "si" x  - floor(x) <= 1/2, 1 - (x - floor(x)) "sinon")$ and that $g$ is $1$-periodic, continuous on $RR$.\
Then, by definition :\

$epsilon_T (a) &= display(max_(t in T) (min_(m in ZZ) abs(t - m a)))\
&= display(max_(t in T)) min(t - floor(t/a)a, (floor(t/a) + 1)a - t)\
&= a display(max_(t in T) underbrace(min(t/a - floor(t/a), floor(t/a) + 1 - t/a), g(t/a)))\
&= a display(max_(t in T) g(t/a))$\ hence we have proved $epsilon_T$ to be continous on $R^*_+$.\

Furthermore, for $n in NN^*, T subset (RR^*_+)^n, a in R^*_+,$\
$ epsilon_T (a) = a limits(max)_(t in T) g(t/a) = a times 1 limits(max)_(t in T) g(t/a 1^(-1)) =  a epsilon_(T \/ a) (1)$. Hence the intuitive following result : the smaller the tatum, the smaller the bound of the error.

== Characterization of semi-strict local maxima

=== First implication
\
Let $a$ be a semi-strict local maximum of $epsilon_T$, $a > 0$. 
By definition, there is a $a > epsilon > 0$ so that :\
$forall delta in ]-epsilon, epsilon [, epsilon_T (a) >= epsilon_T (a + delta)$.\
Let $t in display(argmax_(t' in T)) g(t' / a)$, hence $epsilon_T (a) = a g(t/a)$.\
For all $delta in ]-epsilon, epsilon [, epsilon_T (a) = a g(t/a) >= epsilon_T (a + delta)$,\ and $epsilon_T (a + delta) = (a + delta) max_(t' in T) g(t'/(a + delta)) >= (a + delta) g(t / (a + delta))$.
For $delta >= 0, a + delta >= a$, so $a g(t/a) >= (a+delta) g(t/(a+delta)) >= a g(t/(a+delta))$\
Hence, $g(t/a) >= g(t/(a+delta))$ since $a > 0$, for all $delta in [0, epsilon[$.\
Therefore, $g$ #underline([increases monotonically]) in the range $] t/(a+delta), t/a [$, since $g$ has a unique local maximum (modulo 1), considering the previous range as a neighbourhood of $t/a$.\
Hence, $g = x |-> x - floor(x) $ within the considered range, and $g(t/a) = t/a - floor(t/a), epsilon_T (a) = t - a floor(t/a)$.\
\
The function $epsilon_T$ is the maximum of a finite set of continuous functions, with a countable set of $A$ of intersection, i.e., $A = {x in RR^*_+ : exists (t_1, t_2) in T^2 : t_1 != t_2 and x g(t_1/x) = x g(t_2/x)}$.
Indeed,\
$x in A &<=> exists (t_1, t_2) in T^2 : t_1 != t_2 and g(t_1/x) = g(t_2/x)\
&<=> exists (t_1, t_2) in T^2 : t_1 != t_2 and t_1/x = plus.minus t_2 / x mod 1\
&<=> exists (t_1, t_2) in T^2 : t_1 != t_2 and x = (t_1 minus.plus t_2) / n, n in ZZ^*$\
Hence $A subset {(t_1 minus.plus t_2) / n, (t_1, t_2) in T^2, n in ZZ^*}$, because $T subset (R^*_+)^(|T|)$.
Therefore, there is a countable set of closed convex intervals, whose union is $R^*_+$ so that on each of these intervals, $epsilon_T$ is equal to $f_t : a |-> a g(t/a)$ for a $t in T$. Let then $t$ be so that for all $x in ]a-delta', a[, epsilon_T (x) = f_t(x)$, where $]a-delta', a[$ is included in one the previous intervals. Since $f_t$ and $epsilon_T$ are both continuous on $[a-delta', a], f_t (a) = epsilon_T (a)$ and therefore, $t in display(argmax_(t' in T)) g(t' / a)$. The previous paragraph showed that $g$ is increasing on a left neighbourhood of $t/a$. Therefore, on a right neighbourhood of $t/a$, $g$ is either increasing or decreasing by its definition.

- if $g$ is increasing on this neighbourhood, called $N(t/a)^+$ in the following, the previous expression of $g$ remains valid, i.e., $forall x in N(t/a)^+, g(x) = x - floor(x)$. Moreover, $x |-> floor(x)$ is right-continuous, hence by restricting $N(t/a)^+$, we can assure for all $x in N(t/a)^+,floor(x) = floor(t/a)$. Let then $y = a - t/x$ so that $x = t/(a - y)$, we then have $epsilon_T (a - y) = t - (a - y) floor(t/a) <= epsilon_T (a) = t - a floor(t/a)$ because $a$ is a local maximum of $epsilon_T$ and $a - y$ is within a (left) neighbourhood of $a$, even if it means restricting $delta'$ or $N(t/a)^+$. Hence, $t - floor(t/a) a >= t - (a-y)floor(t/a)$ i.e., $a floor(t/a) <= (a - y) floor(t/a) <=> 0 <= -y floor(t/a)$ i.e., $floor(t/a) <= 0$ i.e., $floor(t/a) = 0$, since $y, t "and" a$ are all positive values. Then, $a > t$ and therefore $epsilon_T (a - y) = t = epsilon_T (a)$ for $floor(t/a) = 0$. This interval where $epsilon_T$ is constant is then either going on infinitely on the right of $a$, or else $epsilon_T$ will reach a value greater than $epsilon_T (a) = t$, since $epsilon_T$ can then be rewritten as $x |-> max(display(max_(t' in T without {t}) x g(t'/x) ), epsilon_T (a))$ on $[a, +infinity[$. Hence $a$ is a local minimum on the right, and since $epsilon_T$ is constant on a left neighbourhood of $a$, $a$ is also a local minimum on the left. Finally, $a$ is a local minimum, which is absurd by definition.

- else, $g$ is decreasing on $N(t/a)^+$, $t/a$ is by definition a local maximum of $g$. However, $g$ only has a unique local maximum modulo 1, that is $1/2$. Hence, $t/a = 1/2 mod 1$, i.e., $t/a = 1/2 + k, k in ZZ$, or $underline(a = t/(k + 1/2)\, k in NN)$, since $a > 0$.

=== Second implication
\
Let $(t, k) in T times NN, a = t/(k + 1/2)$.\
By definition : $g(t/a) = g(1/2 + k) = g(1/2) = 1/2 = max_RR g$.\
Therefore, $epsilon_T (a) = a max_(t' in T) g(t' / a) = a g(t/a) = a / 2$.\
For all $x in ]0, a[, epsilon_T (x) = x max_(t' in T) g(t'/x) <= x/2 < a/2 = epsilon_T (a)$, i.e., $underline(epsilon_T (a) > epsilon_T (x))$.\
Let $T^* = {t' in T : g(t'/a) = 1/2}$. Since $t in T^*$, $|T^*| > 1$.\
Let $t^* in T^*$. For all $t' in T without T^*, g(t'/a) < g(t^* / a)$.\
Since $h_(t') : x |->  g(t'/x) - g(t^* / x)$ is continuous in a neighbourhood of $a > 0$, we have the existence of $epsilon_(t') > 0$ so that $h_(t')$ is strictly positive within $[a, a + epsilon_(t') [$.\
Let $epsilon_(t^*) = min_(t' in T) epsilon_(t')$ and finally $epsilon_1 = min_(t^* in T^*) epsilon_(t^*)$.\
\
Let $(t_1, t_2) in (T^*)^2$.\
In the following, $N(a)^+$ is a right neighbourhood of $a$ such that $a in.not N(a)^+$.\

Let $"tmp" : x |-> g(t_1 / x) - g(t_2 / x)$ be a continous function on $N(a)^+$ and $A$ be the set of all $x^* in N(a)^+ $ so that $"tmp"(x^*) = 0 <=> g(t_1/x^*) = g(t_2/x^*)$.

  We have for all $x^* in A$, $ g(t_1/x^*) = g(t_2/x^*)$ by definition. Considering the expression of $g$, we then find : $t_1/x^* = plus.minus t_2/x^* mod 1$. Moreover, since $g$ only reach $g(t_1/a) = 1/2$ once per period, we have $t_1/a = t_2/a mod 1$, i.e., $|t_1/a - t_2/a| = k_a in NN$.

Then,  $t_1/x^* = plus.minus t_2/x^* mod 1$ i.e., $|t_1/x^* minus.plus t_2/x^*| = k_* in NN$, and therefore $|t_1 minus.plus t_2| = a k_a = x^* k_*$, and $x^* > a$ implies $k_a > k_* >=0$. However, $x^* = abs(t_1 minus.plus t_2) / k_*$, hence $A$ is finite if $A != emptyset$, and $emptyset$ is a finite set. Finally, $A$ is #underline([a finite set]), i.e., $|A| in NN$.\
Let then $x_(t_1, t_2) = cases(min A "if" A != emptyset, x in N(a)^+ without {a} "otherwise") $ #gls("wlog", display: "WLOG,") $g(t_1/x) >= g(t_2/x) forall x in [a, x_(t_1, t_2)]$\
Let $a_2 = display(min_((t_1, t_2) in T^*^2)) underbrace(x_(t_1, t_2), > a)$ and $a_1 in ]a, a_2[$,\
let $t^* = display(argmax_(t' in T^*)) g(t'/a_1)$
We finally have $forall x in ]a, a_2[, g(t^* / x) >= g(t' / x), forall t' in T^*$.\
\
Let then $tilde(a) = min(a + epsilon_1, a_2)$ so that for all $x in ]a, tilde(a)[, t' in T, g(t^* / x) >= g(t'/x)$, hence $epsilon_T (x) = x g(t^* / x)$.\
Let $f : x |-> g(t^* / x), f(a) = g(t^* / a) = 1/2$ because $t^* in T^*$ hence $f$ is increasing on a right neighbourhood of a, $N(a)^+$, since $1/2$ is a global maximum of $g$, therefore $g$ is increasing on $N(t^* / a)^-$ a left neighbourhood of $t^* / a$, i.e., $f$ is increasing on $N(a)^+$. Therefore, we know that $g(t^* / x) = t^* / x - floor(t^* / x)$, since the only other possible expression for $g$ would imply a decreasing function on $N(t^* / a)^-$.\

Hence, $epsilon_T (x) = x g(t^* / x) = x (t^* / x - floor(t^* / x)) = t^* - x floor(t^* / x)$ and $epsilon_T (a) = t^* - a floor(t^* / a)$ since $epsilon_T$ is continuous on $RR^*_+$.\
By definition : $floor(t^* / a) <= t^* / a < floor(t^* / a) + 1$.\
However, $f(a) = 1/2 = t^* / a - floor(t^* / a)$, therefore $floor(t^* / a) < t^* / a$.\
Then, there is $alpha in RR^*_+$ so that $floor(t^* / a) < alpha < t^* / a$, let $y = t^* / alpha$, i.e., $alpha = t^* / y$, with $y > a$.\
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

Hence $a$ is a semi-strict local maximum of $epsilon_T$, and then the set of all semi-strict local maxima is $M_T = {t / (k + 1/2), t in T, k in NN}$.\
Finally, with the notations introduced in @quanti, we proved @local_maxima #align(end, [$square$])

== Necessary condition to be a semi-strict local minimum

Let $a$ be a semi-strict local minimum of $epsilon_T$.\
There exists $epsilon > 0 : forall delta in ]-epsilon, epsilon[, epsilon_T(a + delta) >= epsilon_T(a)$.\
Thanks to the previous results, we know $epsilon_T(a) < a/2$ since otherwise, $a in M_T$, hence $a$ is a strict local maximum.\
We now consider two neighbourhoods of $a : N(a)^+ "and" N(a)^-$. Similarly to the previous proof, we can define $(t^+, t^-) in T^2$ so that :
- for all $x in N(a)^+, epsilon_T (x) = x g(t^+ / x)$
- for all $x in N(a)^-, epsilon_T (x) = x g(t^- / x)$
We can then consider $epsilon' > 0$ so that, for all $delta in ]0, epsilon'[ :$
- $epsilon_T (a + delta) = (a + delta) g(t^+ / (a + delta)) >= epsilon_T (a) = a g(t^+ /a)$
- $epsilon_T (a - delta) = (a - delta) g(t^- / (a - delta)) >= epsilon_T (a) = a g(t^- /a)$

However $a - delta < a$, hence $g(t^- / (a - delta)) > g(t^- / a)$, or in other words, $g$ is increasing on $]t^- / a, t^- / (a - delta)[$ since $t^- / (a - delta) > t^- / a$, and $g$ is stepwise monotonic.
Note that this implies $epsilon_T$ is decreasing on $N(a)^-$, which is conveniently consistent with the hypothesis of $a$ being a local minimum of the latter.\
Then, we have : $g(t^- / (a - delta)) = t^- / (a - delta) - floor(t^- / (a - delta))$\
Moreover, since the functions considered here are all continuous on $]a-epsilon', a+epsilon'[$, we have $g(t^- / a) = g(t^+ / a) = 1/a epsilon_T (a)$.\
If $g$ were increasing on $]t^+ / (a + delta), t^+ / a [$, then $a$ is also a local maximum of $epsilon_T$ according to the first implication of the previous proof. Hence, $a$ is not a semi-strict local minimum, which is absurd.\
Therefore, $g$ is decreasing on $]t^+ / (a + delta), t^+ / a [$, i.e., $g(t^+ / (a + delta)) = 1 + floor(t^+ / (a + delta)) - t^+ / (a + delta)$.

Finally, since $g(t^+ / a) = g(t^- / a)$, we obtain :\
$1 + floor(t^+ / a) - t^+ / a = t^- / a - floor(t^- / a)$,\
hence : $t^- + t^+ = a (1 + floor(t^- / a) + floor(t^+ / a))$.
We finally obtain the following necessary condition : $t^- + t^+ = a k, k in NN^*.$\
Therefore, by defining $m_T = {(t_1 + t_2) / k, (t_1, t_2) in T^2, k in NN^*}$, we have $a in m_T$.\ \

== Conclusion about the correctness of @algonzalo

Since $epsilon_T$ is constant on a neighbourhood of $+ infinity$, we know that the first semi-strict local minimum will be strictly contained in-between two semi-strict local maxima.
Thanks to the previous necessary condition, to find the semi-strict local minimum (which exists since $epsilon_T$ is a continuous function on $RR^*_+$) in-between two given successive semi-strict local maxima $m_1$ and $m_2$ of $M_T$, we only have to determine the value of $limits(argmin)_(m in m_T sect \]m_1, m_2\[) epsilon_T (m)$.\

Finally @algonzalo is correct, and can actually run in
$cal(O)(|D|^2(1 + d^* / "start" - d_* / "end"))$ with $d_* = min T$ and $d^* = max T$.
]) <gonzalo_spectre>

#proposition[Let $(b_n)$ be a correct transcription for a performance $(t_n)$. This informally means that $(b_n)$ is for instance the original score, or an equivalent transcription (with a different tempo or @timesig). If the canonical tempo is within range $[1/"end", 1/"start"]$, and for all $n in NN, exists k in NN : b_n = k epsilon$\
then the complete graph whose verticies are all the local maxima contains a path which is equivalent to the canonical tempo, at least in terms of transcription.]

== Remarks about the fixpoints

@quanti_curves presents the potential tempo curves, where the y-axis represents tempo, and is linear between ♩ = 40 (bottom) and ♩ = 240 (top). Since we only extend previously existing paths, without creating new, we see some path convergence, i.e., the merging of two paths into one. In this case, we end up with only 6 potential paths, whereas we started with over a thousand (exactly 1010). The x-axis corresponds to the index of each event in the performance, hence it does not contain any information regarding actual time. Such a representation allows for displaying results over a whole performance, instead of extracts. Furthermore, among the 6 paths present at the end, only 3 are fixpoints, hence can actually be a tempo curve.

#figure(
  image("../Spectros/Mozart_sonata_1.png", width: 95%),
  caption: [
    All potentials tempo curves found by our quantized approach for a performance of K. 331: III, W.A Mozart.
  ],
) <quanti_curves>

#definition[Usually, a correct transcription does not indicates much tempo variations. Hence, if the considered section of a performance is played at a quasi-constant tempo, then the correct tempo curve is defined as the tempo curve $T = (t_1, ... t_N)$ in the graph that minimizes $limits(sum)_(i = 1)^(N-1) d(t_i, t_(i+1))$, and that is the nearest to the canonical tempo among all such tempo curves according to the tempo distance (or logarithmic distance) $d$. We can then extend this definition by merging different correct tempo curves corresponding to different sections of the performance under the hypothesis that an "actual" tempo curve is either stepwise quasi-constant, or slowly varying (and in this latter case, we will consider the tempo to be quasi-constant at the scale of two successive frames only).]

Moreover, under the hypothesis that there exists a tatum $t$ that has an actual meaning with respect to $F = F_1 union F_N, N in NN$, we can extend the performance by duplicating it, as shown in @fixpoint. In this situation, the fixpoints of the graph are all the lines (that are actually all possible paths) which end is also a starting point when the performance duplicates, hence the top one, but not the bottom one.

#grid(
  align: bottom,
  columns: (auto, auto),
  rows: (auto),
  [#figure(image("../Spectros/Mozart_sonata.png", width: 100%), caption: [First duplication])], [#figure(image("../Spectros/Mozart_sonata.png", width: 100%), caption: [Second duplication]) <fixpoint>]
)

As the previous figures suggest, one can verify that @quanti_curves only contains $3$ fixpoints by following each line and checking that the end point of the first duplication is the same as for the second duplication.\

The following proposition is actually a conjecture at the time being, for we did not have time to formally prove it.

#proposition[If the tempo at times $t_1$ and $t_N$ is the same, $N in NN$, then the correct tempo curve is a fixpoint for the section $(t_1, ..., t_N)$ of a performance $(t_n)$.]
#corollary[The correct tempo curve for a duplicated performance is the duplicated correct tempo curve for the initial performance.]

@ann1 explains that reversing the performance allows for verifying a tempo curve, since any formal tempo is correct when reversed in time. One can verify that the notion of fixpoints is actually a more subtle way to discriminate tempo curves, and that all fixpoints are actually correct when reversed in time, since the computation minimises a distance, that is thus symetrical.

In the case of @raw_output and @esti_result, the canonical tempo clearly indicates a @rallentando at the end of the piece, hence the previous remarks about fixpoints cannot be applied to discriminate tempo curves.

#proposition[For all partial performance $(t_n)_(n in [| 0, N|]), N in NN$, there is a fixpoint among the potential paths given by @find_potential_path.]

== Remarks about the distances used in the quantized approach

In the definition of $epsilon_T$ @epsi_def, we used an absolute distance, that allows for defining a distance to $0$, in case of grace notes. However, when considering $t_a in RR^*_+$ a tatum and $T^*$ a canonical tempo for a given performance, we know the tempo corresponding to $t_a$ is $1/t_a$ and $d(1/t_a, T^*) = d(1/t_a, (Delta b_n) / (Delta t_n)) = d(Delta t_n, Delta b_n t_a)$. Hence, if we consider $limits(argmin)_(m in ZZ) "dist"(Delta t_n, m t_a) $ to be a possible transcription of $Delta t_n$ at tempo $1/t_a$ as we did in our approach, where $"dist"$ is a distance, using $d$ instead of $"dist"$ would imply to minimize the distance between the canonical tempo, and the actual tempo of the transcription, which may embody more musical meaning than the absolute distance.\
However, such a distance can consider a distance to $0$, or in other words accepts grace notes, whereas a logarithmic one cannot, by definition. This implies that, if we were to use a logarithmic distance, then the grace notes would have to me marked down explicitly, at least at first processing.\ \

Furthermore, we then minimize a norm over all elements of $D$, that was actually a $max$ in @epsi_def, hence an infinity norm. Such a norm gives actual guarantees about the result, and may be simpler to understand and use, especially on theoretical proofs, but we could not find any evidence that point towards the use of this particular norm in our study.

== A remark about the consistency property

#definition[formal definition of the property]

#definition[locally consistent and inconsistent]

Let $p$ be a path in $G$ locally inconsistent, i.e., such that there are $a_1, a_2 in p$ so that $d in D$ is quantized differently according to $a_1$ and $a_2$, with $a_1$ and $a_2$ local minima of successive frames. We therefore have a two partial transcriptions of $d$ being either : $m_1$ at tempo $1/a_1$ and $m_2$ at tempo $1/a_2$, both expressed in tatum unit, with $m_1 != m_2$. By hypothesis of our model, both $a_1$ and $a_2$ have an actual meaning within their respective frame $F_1$ and $F_2$.
Let $A_i = limits(argmin)_(k in ZZ) (d - k a_i), i in {1, 2}$, $A = A_1 sect A_2$ and $t$ be the canonical tempo corresponding to $d$ according to a correct transcription of the given performance. Thanks to @card_A, we know that $|A_i| >= 2$ iff $a_i$ is a local maximum, which is absurd in our case, since both $a_1$ and $a_2$ are  semi-strict local minima. Hence, $|A_i| = 1$. Moreover, by definition, $t d in A$, hence $A != emptyset$, hence $A_1 = A_2$.
Since $m_1 in A_1, m_2 in A_2$, both correspond to the same value, possibly express in different MTU. However, by definition, they both are expressed in tatum unit, since $a_1$ and $a_2$ embody a RTU value for the same tatum. Finally $m_1 = m_2$.

== Others formal proofs

#proof(name: [@constant_tempo])[
  Let $i in [|1, |F| |]$, since $t_i = t$, we have $f_i t in NN$ MTU, when expressing symbolic values in tatum.\ Therefore, since $limits(min)_(k in ZZ) (f_i - k/t) = 1/t limits(min)_(k in ZZ) (t (f_i - k/t))$, we obtain : $limits(argmin)_(k in ZZ) (f_i - k/t) = limits(argmin)_(k in ZZ) (t (f_i - k/t)) = limits(argmin)_(k in ZZ) (f_i t - k) = {f_i t}$]

#appendix([Glossary], [
  #print-glossary(show-all:false,
      (
      (key: "mir", short: "MIR", long:"Music Information Retrieval", group: "Acronyms", desc:[Interdisciplinary science aiming at retrieving information from music, in several ways. Amoungst the various problems tackled by the community, one can notice @transcription, automatic or semi-automatic musical analysis, and performance generation or classification...]),
      
      (key: "mtu", short: "MTU", long:"Musical Time Unit", group: "Acronyms", desc:[ Time unit for a symbolic, or musical notation, e.g., beat, quarter note (♩), eighth note (♪).]),
      
      (key: "rtu", short: "RTU", long:"Real Time Unit", group: "Acronyms", desc:[Time unit to represent real events. Here, we usually use 
      seconds as RTU.]),

      (key: "wlog", short: "WLOG", long:"Without loss of generality", group: "Acronyms", desc:[The term is used to indicate the assumption that what follows is chosen arbitrarily, narrowing the premise to a particular case, but does not affect the validity of the proof in general. The other cases are sufficiently similar to the one presented that proving them follows by essentially the same logic.]),

      (key:"transcription",
      short: "transcription",
      desc:[Process of converting an audio recording into symbolic notation, such as music score or MIDI file. This process involves several audio analysis tasks, which may include multi-pitch detection, duration or tempo estimation, instrument identification...],
      group:"Definitions"),

      (key:"score",
      short: "score",
      long: [_sheet music_],
      desc:[Symbolic notation for music. The version considered here is supposed to fit a simplified version of the rhythmic Western notation system],
      group:"Definitions"),

      (key:"tempo",
      short: "tempo",
      desc:[Formally defined in @tempo_def by $T_n^"*" = (b_(n+1) - b_n) / (t_(n+1) - t_n)$, tempo is a measure of the immediate speed of a performance, usually written on the score. It can be seen as a ratio between the symbolic speed indicated by the score, and the actual speed of a performance. Tempo is often expressed in @beat per minute, or bpm],
      group:"Definitions"),

      (key:"beat", short:"beat",
      desc:[Symbolic time unit of a score, its value is defined by a time signature. Although its value can change within a score, or through various transcription of a same piece, this notion is usually the most convenient way to describe a rhythmic sequence of events, since it is supposed to embody the _pulse_ of the music felt by the listener.],
      group:"Definitions"),
      (
        key: "tatum",
        short: "tatum",
        group:"Definitions",
        desc:[Minimal resolution of a musical unit, expressed in beats. Although several values are possible, a tatum is usually indicates the following value for a given score $(b_n)$ : $sup {r | forall n in NN, exists k in NN : b_n = k r, r in RR_+^*}$. For practical reasons, a tatum may be defined as smaller value than the one previously given, especially if this value is easier to express within the current time signature, or makes more sense musically..]
      ),

      (
        key:"timesig",
        short:"time signature",
        desc:"The time signature is a convention in Western music notation that specifies how many note values of a particular type are contained within each measure. It is composed of two integers : the amount of beat contained within a measure, and the value of these beats, indicated as division of a whole note, i.e., four quarter notes.",
        group:"Definitions"
      ),

      (
        key:"rallentando",
        short:"rallentando",
        desc:"Musical direction used to indicate a slackening in the pace.",
        group:"Definitions"
      ),

      (
        key:"cadence",
        short:"cadence",
        desc:"A cadence is can be defined as a progression of at least two chords which concludes a musical phrases. Actually, cadence is often used to refer to some parts of the punctuation within a musical section.",
        group:"Definitions"
      ),

      (
        key:"quantization",
        short:"quantization",
        desc:[We consider here rhythm quantization, i.e., a way to find a rational number expressed in @mtu from the real events durations in @rtu, based on specific musical properties of time division. Indeed, in symbolic rhythmic notations of music, every single event can be expressed as a multiple of a certain unit called a @tatum, usually expressed in @beat. Then, the rhythm quantization consists in expressing each real event of a given performance, or rather its duration, as an integer. This integer is to be interpretated as the value of the duration, expressed in tatum converted to RTU. Hence, rythm quantization is equivalent to tempo inference, as explained in @quanti_revised],
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
        desc:[A chord is by definition the simultaneous production of at least three musical events with different pitches],
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
        key:"articulation",
        short:"articulation",
        desc:[Describes how a specific note is played by the performer. For instance, _staccato_ means the note shall not be maintained, and instead last only a few musical units, depending on the context. On the other hand, a fermata (_point d'orgue_ in French) indicates that the note should stay longer than indicated, to the performer's discretion.],
        group:"Definitions"
      ),

      (
        key:"monophonic",
        short:"monophonic",
        desc:[Describes a piece played so that a single note can be heard at a time. A common hypothesis for monophonic pieces is to consider the end of a note as the begining of the next one. The formalism presented in @formal_consider is more fit for a monophic piece thant a polyphonic one.],
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
        desc:[A measure is a symbolic time unit corresponding to a fixed amount (integer) of beats. This value is indicated by the @timesig.],
        group:"Definitions"
      ),

      (
        key:"triplet",
        short:"triplet",
        desc:[A triplet is a musical symbol indicating to play a third of the indicated duration.],
        group:"Definitions"
      ),

      (
        key:"bt",
        short:"beat tracking",
        desc:[Common problem in the MIR community that consists in detecting the onsets of the theoretical beats from a performance, thus creating a partial note-alignment.],
        group:"Definitions"
      ),

      (
        key:"timing",
        short: "timing",
        long: [_shifts_],
        desc: [Delay between the theoretical real time onset according to the current tempo, and the actual onset heard in the performance. Even though such a delay is inevitable for neurological and biological reasons, those timings are usually overemphasized and understood as part of the musical expressivity of the performance],
        group:"Definitions"
      ),

      (
        key:"online",
        short:"online",
        desc:[In computer science, an online algorithm is one that can process its input piece-by-piece in a serial fashion, i.e., in the order that the input is fed to the algorithm, without having the entire input available from the start.],
        group:"Definitions"
      ),
    )
  )
])

#highlight([TODO : send report to Gonzalo, (Rigaux, Lemaitre)])