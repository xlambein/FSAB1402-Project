% Mix takes a score interpreter and a music as an argument, and returns an
% audio vector.
fun {Mix Interprete Music}
    Step = 1.0 / {IntToFloat Projet.hz}
    InstrumentsDir = 'wave/instruments/'
    
    fun {ToAVLength Duration}
        {FloatToInt Duration / Step}
    end
    
    fun {ToDuration AVLength}
        {IntToFloat AVLength} * Step
    end
    
    fun {Cut Pos StartCut EndCut AV Next}
        if Pos =< EndCut then
            if Pos < 0.0 then
                0.0|{Cut Pos+Step StartCut EndCut AV Next}
            else
                case AV
                of H|T then
                    if Pos < StartCut then
                        {Cut Pos+Step StartCut EndCut T Next}
                    else
                        H|{Cut Pos+Step StartCut EndCut T Next}
                    end
                [] nil then
                    0.0|{Cut Pos+Step StartCut EndCut nil Next}
                end
            end
        else
            Next
        end
    end
    
    \insert 'envelopes.oz'
    
    % Gives the pitch of a note relative a4, in semitones.
    fun {PitchToNote Pitch}
        Octave
        InOctave
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
        Octave = (Pitch+9 + 4*12) div 12
        InOctave = Pitch - (Octave-4)*12 + 9
        Letter = {NoteLetter InOctave}
        Alteration = {NoteAlteration InOctave}
        
        case Alteration
        of none then
            {VirtualString.toAtom Letter#Octave}
        else
            {VirtualString.toAtom Letter#Octave#"#"}
        end
    end
    
    fun {InstrumentToAV Instrument Pitch}
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
    
    fun {SampleToAV Sample Next}
        case Sample
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
            case I
            of none then
                {SinusoidToAV P Dur {EnvADSR 0.03 0.01 0.8 0.03 Dur} Next}
            [] trapezoid(att:A rel:R) then
                {SinusoidToAV P Dur {EnvTrapezoid A R Dur} Next}
            [] adsr(att:A dec:D sus:S rel:R) then
                {SinusoidToAV P Dur {EnvADSR A D S R Dur} Next}
            [] hyperbola(att:A) then
                {SinusoidToAV P Dur {EnvHyperbola A Dur} Next}
            else
                RawAV = {InstrumentToAV I P}
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
                {ApplyEnv 0.0 {Cut 0.0 0.0 Dur RawAV nil}}
                %[0.0]
            end
        end
    end
    
    fun {VoiceToAV Voice Next}
        case Voice
        of H|T then
            {SampleToAV H {VoiceToAV T Next}}
        [] nil then
            Next
        end
    end
    
    fun {Reverse AV Next}
        case AV
        of H|T then
            {Reverse T H|Next}
        [] nil then
            Next
        end
    end
    
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
    
    fun {Fade InDur OutDur AV Next}
        
        Dur = {ToDuration {Length AV}}
        fun {ApplyFade Pos AV}
            case AV
            of H|T then
                Hm
            in
                if Pos < InDur then
                    Hm = H*Pos/InDur
                elseif (Dur-Pos) < OutDur then
                    Hm = H*(Dur-Pos)/OutDur
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
    
    fun {CrossFade CrossDur AV1 AV2 Next}
        
        FirstDur = {IntToFloat {Length AV1}} * Step
        fun {ApplyCrossFade Pos AV1 AV2}
            case AV1
            of H1|T1 then
                if Pos < FirstDur-CrossDur then
                    H1|{ApplyCrossFade Pos+Step T1 AV2}
                else
                    H2|T2 = AV2
                    Gain1 = (FirstDur-Pos)/CrossDur
                    H = H1*Gain1 + H2*(1.0-Gain1)
                in
                    H|{ApplyCrossFade Pos+Step T1 T2}
                end
            [] nil then
                case AV2
                of H2|T2 then
                    H2|{ApplyCrossFade Pos+Step nil T2}
                [] nil then
                    Next
                end
            end
        end
    in
        {ApplyCrossFade 0.0 AV1 AV2}
    end
    
    fun {MergeTwo Int1 AV1 Int2 AV2 Next}
        case AV1#AV2
        of (H1|T1)#(H2|T2) then
            (Int1*H1 + Int2*H2)|{MergeTwo Int1 T1 Int2 T2 Next}
        [] (H1|T1)#nil then
            (Int1*H1)|{MergeTwo Int1 T1 Int2 nil Next}
        [] nil#(H2|T2) then
            (Int2*H2)|{MergeTwo Int1 nil Int2 T2 Next}
        [] nil#nil then
            Next
        end
    end
    
    fun {MergeMusics List Next}
        case List
        of (Int#M)|T then
            {MergeTwo Int {MusicToAV M nil} 1.0 {MergeMusics T nil} Next}
        else
            nil
        end
    end
    
    fun {PieceToAV Piece Next}
        case Piece
        of voix(V) then
            {VoiceToAV V Next}
        [] partition(P) then
            {VoiceToAV {Interprete P} Next}
            
        [] wave(F) then
            {Append {Projet.readFile F} Next}
        [] merge(L) then
            {MergeMusics L Next}
        [] echo(delai:D M) then
            {EchoMusic D 1.0 2 M Next}
        [] echo(delai:D decadence:Dc M) then
            {EchoMusic D Dc 2 M Next}
        [] echo(delai:D decadence:Dc repetition:R M) then
            {EchoMusic D Dc R M Next}
        
        %filtres
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
        [] couper(debut:S fin:E M) then
            {Cut {Min 0.0 S} S E {MusicToAV M nil} Next}
        end
    end
    
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
    
in
    
    {FunBenchmark fun {$}
    {MusicToAV Music nil}
    end 'Mix'}
end
