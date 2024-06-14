//
//  TempoClass.cpp
//  antescofo~
//
//  Created by José Echeveste on 27/10/12.
//


// keep this include first, before math- and algo-related stuff, 
// because of MinGW (see Archi.h)
#include <Archi.h> 

#include <functional>
#include <algorithm>

#include "kappa_table.h"

#include "TempoClass.h"
#include "score_utils.h"
#include "AntescofoCore.h"
#include "Environment.h"

t_tempo::t_tempo(antescofo_core* ant)
: kappa(2.0), s_kappa(0.94), eta_s(0.9), rt_tempo(1.0), last_instantaneous_tempo(1.0), tempo_correction(0.0),min_kappa(1.0),small_variation(0),antesc(ant)
{
    kappa_y.assign(kappa_table, kappa_table + (sizeof(kappa_table)/sizeof(kappa_table[0])));
}

t_tempo::t_tempo(const t_tempo& tt):
kappa(tt.kappa), s_kappa(tt.s_kappa), eta_s(tt.eta_s),
rt_tempo(tt.rt_tempo), last_instantaneous_tempo(tt.last_instantaneous_tempo),
tempo_correction(tt.tempo_correction),min_kappa(tt.min_kappa),
small_variation(tt.small_variation),kappa_y(tt.kappa_y), antesc(tt.antesc)
{}

double t_tempo::get_tempo(){return (double) (60./rt_tempo);}

/*!
 *  @brief          Reset internal tempo states.
 *
 *  Used for example during BPM initialization.
 *
 */
void t_tempo::Reset()
{
    tempo_correction = 0.0;
    kappa  = 2.0;
    s_kappa  = 0.94;
}

void t_tempo::TempoUpdate(double t)
{
    assert(t>0);
    if (rt_tempo != t)
    {
        rt_tempo = t;
        last_instantaneous_tempo = t;
        assert(antesc && antesc->get_env());
        assert(rt_tempo != 0.0);
        antesc->get_env()->updateTempo(60./rt_tempo);
        small_variation = 0;
    }
}

/*!
 *  @brief          Tempo update oscillator for mono-tonic tempo
 *
 *  Mono-tonic tempo update oscillator based on Large & Jones.
 *
 *  @param passed_phi        passed phase in the score
 *  @param passed_beat       passed beat time in the score
 *  @param score_tempo       Tempo in the score
 *  @param x_elapsedrealtime       Passed absolute time (seconds)
 *  @param verbosity        verbosity flag for debugging
 *  @see AnotherMethod()   [optional..]
 *  @return void - but updates internal tempo
 *
 *  @details
 *  @n
 */
void t_tempo::tempoOsc(float passed_phi, float passed_beat, float score_tempo,
                       float x_elapsedrealtime,
                       int verbosity)
{
    //if(antescofo_core::f_notempo)
    //{
	/********************************
	 *		(3)	Tempo Decoding.		*
	 ********************************/
	// The decoded tempo will in return change the "expectancy" parameters
	// in x_netscore used in future computations.
    
    assert(rt_tempo >= 0.);
    assert(passed_beat > 0.);
    assert(score_tempo > 0.);
    assert(x_elapsedrealtime >= 0.);
    
    
    double new_rt_tempo = -666.666;


    /// Calculate realtime phase
    if (rt_tempo == 0.0)
        rt_tempo = score_tempo;	//x_netscore[position].tempo;
    
    float rt_beat = x_elapsedrealtime / rt_tempo    - tempo_correction ;
    //float instantaneous_rt_beat = x_elapsedrealtime / last_instantaneous_tempo;

    float rt_phi = wrap_phi(rt_beat);
    
    float phi_diff = wrap_phi(rt_beat - passed_beat);
	
    /// Calculate phase difference between realtime and score
    //float phi_diff = rt_phi - passed_phi;
    
    // correct the difference based on score progression (our advantage to Large!)
    if ( rt_beat >= passed_beat )
    {
        if (phi_diff < 0)
            phi_diff = -1.0 * phi_diff;
    }else
    {
        if (phi_diff > 0)
            phi_diff = -1.0 * phi_diff;
    }

    //post("phi_diff %f, passed_phi %f, rt_phi %f ", phi_diff, passed_phi,rt_phi);

    /// Update error accumulation
    s_kappa = s_kappa - eta_s * (s_kappa - cos(2.0*PI* (phi_diff)));  // was rt_phi - passed_phi
    //s_kappa = eta_s * (cos(2.0*PI* (phi_diff)));
    
    /// Update kappa by table lookup
    // The bigger the kappa, the smaller the tempo change.. thus, s_kappa should be big for small tempo changes!
    if (fabs(s_kappa)<kappa_table[0])  // Bound the likelihood to the min of table
    {
        kappa= kappa_list[0];
    }else									  // Bound the likelihood to the max of table
		if (fabs(s_kappa) >= kappa_y.at(kappa_y.size()-1) )
		{
            //int kappa_index =kappa_y.size()-1;
			kappa=10.0;
		}else									 // Find the most likely kappa by table lookup
		{
			std::vector<double>::iterator thiskappa_it = lower_bound(kappa_y.begin(), kappa_y.end(),
                                                                     double(fabs(s_kappa)), std::less<double>() );
			int kappa_index = distance(kappa_y.begin(), thiskappa_it);
            
			kappa=kappa_list[kappa_index-1];
		}
    
    // Apply the MIN filter
    if (kappa<min_kappa)
    {
        kappa=min_kappa;
    }
    
    
    /// Inflection Check: EXPERIMENTAL
    //  If the difference in passed_beat (score) and rt_beat is minimal, then  .
    //  IDEA: Large's Tempo correction is based on constant beat-tapping. In our applicaiton, durations are different! Thus, a beat-difference of 0.1 on a note with duration 10 is not the same as on duration 1.0. Here, we take this into account before wrapping to the phase world.
    //if ((fabs(passed_beat-rt_beat)/passed_beat)<0.1)
   
    
    /* if ((fabs(passed_beat-rt_beat)/passed_beat)<0.1)
    {
        // Less than 10% change! IGNORE
        //Post("------------");
        //Post("Beat change of %f over %f. IGNORED!", fabs(passed_beat-rt_beat), passed_beat);
        return;
    }
    
    /// Update realtime tempo
    tempo_correction =  entrain(phi_diff, kappa);
    rt_tempo = rt_tempo * (1 + tempo_correction);
    */
    
    /*
    if ((fabs(passed_beat - instantaneous_rt_beat)/passed_beat) < 0.02)
    {
        if(small_variation >= 10)
        {
            tempo_correction =  entrain(phi_diff, kappa);
            //double larg = rt_tempo * (1 + tempo_correction);
           rt_tempo = x_elapsedrealtime/passed_beat;
           //post("Valeur tempo absolue : %f, passed_beat : %f , phi_diff %f, tempo_correction %f ",rt_tempo,passed_beat,phi_diff,tempo_correction);
        }else{
            /// Update realtime tempo
            tempo_correction =  entrain(phi_diff, kappa);
            rt_tempo = rt_tempo * (1 + tempo_correction);
            //calcul du tempo instantannée pour vérification
            last_instantaneous_tempo = x_elapsedrealtime/passed_beat;
            //post("Valeur tempo large : %f, passed_beat : %f phi_diff %f, tempo_correction %f ",rt_tempo,passed_beat,phi_diff,tempo_correction);
        }

        small_variation++;
    }
    else*/
    {
    /// Update realtime tempo
        tempo_correction =  entrain(phi_diff, kappa);
        new_rt_tempo = rt_tempo * (1. + tempo_correction);
        small_variation = 0;
    }
    
    //// DEBUG:
    /*Post("------------");
    Post("RT_Phi: %.4f (RT:%.4f-Beat:%.4f)",rt_phi, x_elapsedrealtime,rt_beat);
    Post("Passed_Phi: %.4f (sBeat:%.3f)",passed_phi, passed_beat);
    Post("Phi Diff: %f",phi_diff);
    Post("s_kappa: %f - kappa: %f (eta %f)",s_kappa, kappa, eta_s);
    Post("tempo_correction: %f (%f from %f)",tempo_correction, rt_tempo, rt_was);
    Post("Gives: %.4f BPM",(60.0/rt_tempo) );*/
    
    assert(new_rt_tempo >= 0);
    
    if (verbosity>0)
    {
        post("        RT phi %.3f, passed phase %.3f, delta %.3f, tempo correction %.4e, TEMPO=%.4e (%.2f BPM), Kappa=%.4f",
             rt_phi,passed_phi,phi_diff,tempo_correction,rt_tempo,60.0/rt_tempo, kappa);
        //post("Kappa was updated to %f with max. likelihood of %f",kappa,fabs(s_kappa));
    }
	
	if (last_sentTempo != new_rt_tempo)
		TempoUpdate(new_rt_tempo);		// update and NOTIFY subscribers
    //}
}

/*! Entrainement Function based on Mises-Von first derivative distribution */
float t_tempo::entrain(float phi, float kappa)
{
	return (1.0/(2.0*PI*exp(kappa))) * exp(kappa * cos(2.0*PI*phi))*sin(2.0*PI*phi);
}


void t_tempo_var::TempoUpdate(double tempo_spb)
{
    assert(tempo_spb>0);
    rt_tempo = tempo_spb ;
}

double t_tempo_var::tempoOsc(double now)
{
    if(last_time == -1.)
    {
        last_position = 0.;
        ind = 1;
    }else{
        last_position += freq;
        double x_elapsedrealtime = now - last_time;
        if(x_elapsedrealtime > 0.)
        {
            t_tempo::tempoOsc(wrap_phi(freq),
                             freq,
                             rt_tempo,
                             x_elapsedrealtime);
        }
        ind = floor(last_position/freq) + 1;
    }
    last_time = now;
    return 60./rt_tempo;
}


