/// The concrete subject for storing and maitaining the tempo
/// used in "publish/subscribe" scheduling patterns


#pragma once


#ifndef __antescofo___TempoClass__
#define __antescofo___TempoClass__

#include <vector>/Users/jacquema/Code/Antescofo/Src/Listening/TempoClass.cpp

#ifndef PI
#define PI 3.1415926535897932384626
#endif

class antescofo_core;

class t_tempo
{
public:
    t_tempo(antescofo_core* ant);
    t_tempo(const t_tempo& tt);

    virtual ~t_tempo() {}
    
    virtual void init()
    {
        tempo_correction=0.0;kappa=2.0;s_kappa=0.0;
    };
	
    double
    kappa,			    // Expectancy parameter for Mises-Von distribution (or variance!)
    s_kappa,	     	// Maximum likelihood value approximation of kappa
    eta_s,				// Propagation parameter for kappa max. likelihood approx.
    rt_tempo,			// Realtime estimated tempo (second / beat)
    last_instantaneous_tempo,
    tempo_correction,	// Tempo correction value at each step
    last_sentTempo,		// last sent tempo for tempo synch from outside
    min_kappa;          // Minimum KAPPA value not to bypass (to limit manually tempo variation)
    int small_variation;
    
    double get_tempo();
    
    virtual void TempoUpdate(double t);
    
    /// Extended Kalman Filter predictive/corrective oscilator based on Large and Jones (1999)
    /// For tempo adaptation
    //void	tempoOsc(t_netscore &x_netscore,
    void tempoOsc(float passed_phi, float passed_beat, float score_tempo,
                  //int position, int last_position,
                  float x_elapsedrealtime, int verbosity=0);
    
    void Reset();

private:
	
    float	entrain(float phi, float kappa);
    std::vector<double> kappa_y;
    antescofo_core* antesc;
};


class t_tempo_var: public t_tempo
{
public:
    t_tempo_var(float temp_init = 60., float f = 1.0):
    t_tempo(NULL),
    freq (f),
    last_position (-1.),last_time(-1.),tempo_init(temp_init),freq_init(f)
    {rt_tempo  = 60./temp_init;}
    
    t_tempo_var(const t_tempo_var& ttv):
    t_tempo(ttv),
    freq (ttv.freq),
    last_position (ttv.last_position),last_time(ttv.last_time),tempo_init(ttv.tempo_init),freq_init(ttv.freq_init){}
    
    void init()
    {
        t_tempo::init();
        last_time = -1;
        rt_tempo  = 60./tempo_init;
        freq = freq_init;
        last_position = -1.;
        ind = 0;
    };
    void TempoUpdate(double t);
    void set_tempo(double t){rt_tempo =60./t;}
    double tempoOsc(double now);
    double  freq;
    double last_position;
    double last_time;
    double tempo_init;
    double freq_init;
    int ind;
};
#endif
