% mix.oz
%
% Authors: Xavier Lambein (54621300)
%          Victor Lecomte (65531300)
% Date: 2014-12-04

% Mix takes a score interpreter and a music as an argument, and returns an
% audio vector.
fun {Mix Interprete Music}
    
    % Envelopes, implemented in 'envelopes.oz'
    EnvTrapezoid
    EnvADSR
    EnvHyperbola
    
    % General constants
    Step
    InstrumentsDir
    
    % Length conversion
    ToAVLength
    ToDuration
    
    % Instrument sound extraction
    PitchToNote
    ReadInstrumentWav
    
    % Sample and voice generation
    SinusoidToAV
    SampleToAV
    VoiceToAV
    
    % Filters on AVs
    Cut
    Reverse
    RepeatNumber
    RepeatToLength
    Clip
    Fade
    CrossFade
    MergeTwo
    
    % Filters on musics
    EchoMusic
    MergeMusics
    
    % Music decomposition
    PieceToAV
    MusicToAV
in
    
    \insert 'envelopes.oz'
    
    
    % Time interval between two sampling points.
    Step = 1.0 / {IntToFloat Projet.hz}
    % Location of the instrument sound files
    InstrumentsDir = 'wave/instruments/'
    
    
    % Converts from a duration (in seconds) to number of sampling points.
    fun {ToAVLength Duration}
        {FloatToInt Duration / Step}
    end
    
    % Converts from a number of sampling points to a duration (in seconds).
    fun {ToDuration AVLength}
        {IntToFloat AVLength} * Step
    end
    
    
    % Transforms a pitch (relative to a4) into the correct note denomination in
    % instrument filenames.
    fun {PitchToNote Pitch}
        Octave
        InOctave
        % Gives the note name for a pitch within an octave (relative to c).
        fun {NoteLetter InOctave}
            case InOctave
            of 0 then 'c'
            [] 1 then 'c'
            [] 2 then 'd'
            [] 3 then 'd'
            [] 4 then 'e'
            [] 5 then 'f'
            [] 6 then 'f'
            [] 7 then 'g'
            [] 8 then 'g'
            [] 9 then 'a'
            [] 10 then 'a'
            [] 11 then 'b'
            end
        end
        % Gives the note alteration for a pitch within an octave (relative to
        % c).
        fun {NoteAlteration InOctave}
            case InOctave
            of 1 then '#'
            [] 3 then '#'
            [] 6 then '#'
            [] 8 then '#'
            [] 10 then '#'
            else
                none
            end
        end
        Letter
        Alteration
    in
        % Octave number
        Octave = (Pitch+9 + 4*12) div 12
        % Pitch within an octave (relative to c)
        InOctave = Pitch - (Octave-4)*12 + 9
        
        Letter = {NoteLetter InOctave}
        Alteration = {NoteAlteration InOctave}
        
        % Composing the note denomination.
        case Alteration
        of none then
            {VirtualString.toAtom Letter#Octave}
        else
            {VirtualString.toAtom Letter#Octave#"#"}
        end
    end
    
    % Reads the .wav file for given instrument and pitch.
    fun {ReadInstrumentWav Instrument Pitch}
        {Projet.readFile {VirtualString.toAtom InstrumentsDir#Instrument#'_'#{PitchToNote Pitch}#'.wav'}}
    end
    
    fun {SinusoidToAV Pitch Dur Envelope Next}
        Freq = {Pow 2. {IntToFloat Pitch}/12.}*440.
        Tau = 6.283185307
        Omega = Tau*Freq
        fun {ApplySine Pos}
            if Pos < Dur then
                0.5*{Envelope Pos}*{Sin Omega*Pos}|{ApplySine Pos+Step}
            else
                Next
            end
        end
    in
        {ApplySine 0.0}
    end
    
    % Gives an AV for the given sample (adding Next).
    fun {SampleToAV Sample Next}
        case Sample
        % If it is a silence, we fill the AV with zeroes.
        of silence(duree:D) then
            fun {Zeros Pos}
                if Pos < D then
                    0.0|{Zeros Pos+Step}
                else
                    Next
                end
            end
        in
            {Zeros 0.0}
        
        [] echantillon(hauteur:P duree:Dur instrument:I) then
        
            % For other samples, it depends on the instrument
            case I
            
            % Default instrument is a sinusoid with ADSR envelope.
            of none then
                {SinusoidToAV P Dur {EnvADSR 0.03 0.01 0.8 0.03 Dur} Next}
            
            % If the instrument only specifies the envelope to use.
            [] trapezoid(att:A rel:R) then
                {SinusoidToAV P Dur {EnvTrapezoid A R Dur} Next}
            [] adsr(att:A dec:D sus:S rel:R) then
                {SinusoidToAV P Dur {EnvADSR A D S R Dur} Next}
            [] hyperbola(att:A) then
                {SinusoidToAV P Dur {EnvHyperbola A Dur} Next}
            
            % Otherwise we have to read the instrument wav file.
            else
                RawAV = {ReadInstrumentWav I P}
                
                % We apply a trapezoid filter to smooth the end (the start is
                % already smooth).
                Env = {EnvTrapezoid 0.0 0.03 Dur}
                fun {ApplyEnv Pos AV}
                    case AV
                    of H|T then
                        H*{Env Pos}|{ApplyEnv Pos+Step T}
                    else
                        Next
                    end
                end
            in
                % We cut the instrument sample to the specified duration then we
                % apply the envelope.
                {ApplyEnv 0.0 {Cut 0.0 0.0 Dur RawAV nil}}
            end
        end
    end
    
    % Decomposes a voice into its samples and returns the combined AV (adding
    % Next).
    fun {VoiceToAV Voice Next}
        case Voice
        of H|T then
            {SampleToAV H {VoiceToAV T Next}}
        [] nil then
            Next
        end
    end
    
    
    % Cuts an audio vector to a specified start and end cut (adding Next). If
    % the cut spans regions outside the AV, those are filled with zeroes.
    fun {Cut Pos StartCut EndCut AV Next}
        if Pos =< EndCut then
            % If Pos is before the AV, we fill with zeroes.
            if Pos < 0.0 then
                0.0|{Cut Pos+Step StartCut EndCut AV Next}
            else
                case AV
                of H|T then
                    % If Pos is before the start cut and within the AV, we
                    % ignore this part.
                    if Pos < StartCut then
                        {Cut Pos+Step StartCut EndCut T Next}
                    % If Pos is within the cut *and* within the AV, we add the
                    else
                        H|{Cut Pos+Step StartCut EndCut T Next}
                    end
                % If Pos is past the end of the AV, we fill with zeroes.
                [] nil then
                    0.0|{Cut Pos+Step StartCut EndCut nil Next}
                end
            end
        % If Pos is past the end cut, we are finished.
        else
            Next
        end
    end
    
    % Reverses an audio vector (adding Next).
    fun {Reverse AV Next}
        case AV
        of H|T then
            {Reverse T H|Next}
        [] nil then
            Next
        end
    end
    
    % Repeats an audio vector a number of times, starting with Start and adding
    % Next.
    fun {RepeatNumber Number Start AV Next}
        case Start
        of H|T then
            H|{RepeatNumber Number T AV Next}
        [] nil then
            if Number == 0 then
                Next
            else
                {RepeatNumber Number-1 AV AV Next}
            end
        end
    end
    
    % Repeats an audio vector up to a specified length, starting with Start and
    % adding Next.
    fun {RepeatToLength Length Start AV Next}
        if Length == 0 then
            Next
        else
            case Start
            of H|T then
                H|{RepeatToLength Length-1 T AV Next}
            [] nil then
                {RepeatToLength Length AV AV Next}
            end
        end
    end
    
    % Clips any parts of an audio vector below or above set levels (adding
    % Next).
    fun {Clip Low High AV Next}
        case AV
        of H|T then
            R
        in
            if H < Low then
                R = Low
            elseif H > High then
                R = High
            else
                R = H
            end
            R|{Clip Low High T Next}
        [] nil then
            Next
        end
    end
    
    % Applies a fade effect (fade in and out) to an audio vector (adding Next).
    fun {Fade InDur OutDur AV Next}
        
        Dur = {ToDuration {Length AV}}
        fun {ApplyFade Pos AV}
            case AV
            of H|T then
                Hm
            in
                % Fade in
                if Pos < InDur then
                    Hm = H*Pos/InDur
                % Fade out
                elseif (Dur-Pos) < OutDur then
                    Hm = H*(Dur-Pos)/OutDur
                % Regular
                else
                    Hm = H
                end
                Hm|{ApplyFade Pos+Step T}
            [] nil then
                Next
            end
        end
    in
        {ApplyFade 0.0 AV}
    end
    
    % Links two audio vectors with a cross fade (adding Next).
    fun {CrossFade CrossDur AV1 AV2 Next}
        
        % We need the duration of the first audio vector to start the cross fade
        % at the right time.
        FirstDur = {IntToFloat {Length AV1}} * Step
        
        fun {ApplyCrossFade Pos AV1 AV2}
            case AV1
            of H1|T1 then
                % Before the cross fade
                if Pos < FirstDur-CrossDur then
                    H1|{ApplyCrossFade Pos+Step T1 AV2}
                % During the cross fade
                else
                    H2|T2 = AV2
                    Gain1 = (FirstDur-Pos)/CrossDur
                    H = H1*Gain1 + H2*(1.0-Gain1)
                in
                    H|{ApplyCrossFade Pos+Step T1 T2}
                end
            [] nil then
                case AV2
                % After the cross fade
                of H2|T2 then
                    H2|{ApplyCrossFade Pos+Step nil T2}
                % At the end
                [] nil then
                    Next
                end
            end
        end
    in
        {ApplyCrossFade 0.0 AV1 AV2}
    end
    
    % Merges two audio vectors with given intensities (adding Next).
    fun {MergeTwo Int1 AV1 Int2 AV2 Next}
        case AV1#AV2
        % Both are non-empty
        of (H1|T1)#(H2|T2) then
            (Int1*H1 + Int2*H2)|{MergeTwo Int1 T1 Int2 T2 Next}
        % AV2 is empty
        [] (H1|T1)#nil then
            (Int1*H1)|{MergeTwo Int1 T1 Int2 nil Next}
        % AV1 is empty
        [] nil#(H2|T2) then
            (Int2*H2)|{MergeTwo Int1 nil Int2 T2 Next}
        % Both are empty
        [] nil#nil then
            Next
        end
    end
    
    
    % Adds an echo effect to a music, where the echoes have a given offset and
    % decay (then adds Next).
    fun {EchoMusic RepStep Decay NumRepeat M Next}
        IntSum =
            if Decay == 1.0 then
                {IntToFloat NumRepeat}
            else
                (1.0 - {Pow Decay {IntToFloat NumRepeat}+1.0}) / (1.0 - Decay)
            end
        fun {ToMerge Lag Int I}
            if I == NumRepeat then
                nil
            else
                (Int#[voix([silence(duree:Lag)]) M])|{ToMerge Lag+RepStep Int*Decay I+1}
            end
        end
    in
        {MergeMusics {ToMerge 0.0 1.0/IntSum 0} Next}
    end
    
    % Merges a list of musics with their corresponding intensities (adding
    % Next).
    fun {MergeMusics List Next}
        case List
        of (Int#M)|T then
            {MergeTwo Int {MusicToAV M nil} 1.0 {MergeMusics T nil} Next}
        else
            nil
        end
    end
    
    % Mixes a piece, reading partitions, wav files or filters, and returns the
    % resulting AV (adding Next).
    fun {PieceToAV Piece Next}
        case Piece
        of voix(V) then
            {VoiceToAV V Next}
        [] partition(P) then
            {VoiceToAV {Interprete P} Next}
            
        [] wave(F) then
            {Append {Projet.readFile F} Next}
        
        % Filters on musics
        [] echo(delai:D M) then
            {EchoMusic D 1.0 2 M Next}
        [] echo(delai:D decadence:Dc M) then
            {EchoMusic D Dc 2 M Next}
        [] echo(delai:D decadence:Dc repetition:R M) then
            {EchoMusic D Dc R M Next}
        [] merge(L) then
            {MergeMusics L Next}
        
        % Filters on audio vectors
        [] couper(debut:S fin:E M) then
            {Cut {Min 0.0 S} S E {MusicToAV M nil} Next}
        [] renverser(M) then
            {Reverse {MusicToAV M nil} Next}
        [] repetition(nombre:N M) then
            {RepeatNumber N nil {MusicToAV M nil} Next}
        [] repetition(duree:D M) then
            {RepeatToLength {ToAVLength D} nil {MusicToAV M nil} Next}
        [] clip(bas:L haut:H M) then
            {Clip L H {MusicToAV M nil} Next}
        [] fondu(ouverture:I fermeture:O M) then
            {Fade I O {MusicToAV M nil} Next}
        [] fondu_enchaine(duree:D M1 M2) then
            {CrossFade D {MusicToAV M1 nil} {MusicToAV M2 nil} Next}
        end
    end
    
    % Decomposes a music into pieces, and returns the resulting AV (adding
    % Next).
    fun {MusicToAV Music Next}
        case Music
        of H|T then
            {PieceToAV H {MusicToAV T Next}}
        [] nil then
            Next
        else
            {PieceToAV Music Next}
        end
    end
    
    % Runs the mix with an empty accumulator, and benchmarks it.
    {FunBenchmark fun {$}
    {MusicToAV Music nil}
    end 'Mix'}
end
