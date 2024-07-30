class TempoModel():
    def __init__(self, tempo_init) -> None:
        self.tempo = tempo_init
    
    def update_and_return_tempo(self, input):
        return

class CanonicalTempo(TempoModel):
    def __init__(self, tempo_init=120) -> None:
        super().__init__(tempo_init)
    def update_and_return_tempo(self, input):
        beat_input, time_input = input
        return 60 * beat_input / time_input