% Mix takes a score interpreter and a music as an argument, and returns an
% audio vector.
fun {Mix Interprete Music}
    Step = 1.0 / {IntToFloat Projet.hz}
    
    fun {ToAVLength Duration}
        {FloatToInt Duration*{IntToFloat Projet.hz}}
    end
    
    fun {EnvHyperbola Dur}
        Ts = 0.05
        Scaling = ((Dur+2.0*Ts)*(Dur+2.0*Ts)) / (Dur*Dur)
    in
        fun {$ Pos}
            Scaling * Pos/(Pos+Ts) * (Dur-Pos)/(Dur-Pos+Ts)
        end
    end
    
    fun {SampleToAV Sample End}
        case Sample
        of silence(duree:D) then
            fun {Zeros Pos End}
                if Pos < D then
                    0.0|{Zeros Pos+Step End}
                else
                    End
                end
            end
        in
            {Zeros 0.0 End}
        
        [] echantillon(hauteur:P duree:D instrument:_) then
            Freq = {Pow 2. {IntToFloat P}/12.}*440.
            Tau = 6.283185307
            Omega = Tau*Freq
            Envelope = {EnvHyperbola D}
            fun {Sinusoid Pos End}
                if Pos < D then
                    0.5*{Envelope Pos}*{Sin Omega*Pos}|{Sinusoid Pos+Step End}
                else
                    End
                end
            end
        in
            {Sinusoid 0.0 End}
        end
    end
    
    fun {VoiceToAV Voice End}
        case Voice
        of H|T then
            {SampleToAV H {VoiceToAV T End}}
        [] nil then
            End
        end
    end
    
    fun {Reverse AV End}
        case AV
        of H|T then
            {Reverse T H|End}
        [] nil then
            End
        end
    end
    
    fun {RepeatNumber Number Start AV End}
        case Start
        of H|T then
            H|{RepeatNumber Number T AV End}
        [] nil then
            if Number == 0 then
                End
            else
                {RepeatNumber Number-1 AV AV End}
            end
        end
    end
    
    fun {RepeatToLength Length Start AV End}
        if Length == 0 then
            End
        else
            case Start
            of H|T then
                H|{RepeatToLength Length-1 T AV End}
            [] nil then
                {RepeatToLength Length AV AV End}
            end
        end
    end
    
    fun {Clip Low High AV End}
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
            R|{Clip Low High T End}
        [] nil then
            End
        end
    end
    
    fun {EchoMusic RepStep Decay NumRepeat M End}
        IntSum = (1.0 - {Pow Decay {IntToFloat NumRepeat}+1.0}) / (1.0 - Decay)
        fun {ToMerge Lag Int I}
            if I == NumRepeat then
                nil
            else
                (Int#[voix([silence(duree:Lag)]) M])|{ToMerge Lag+RepStep Int*Decay I+1}
            end
        end
    in
        {MergeMusics {ToMerge 0.0 1.0/IntSum 0} End}
    end
    
    fun {Fade InDur OutDur AV End}
        
        Dur = {IntToFloat {Length AV}} * Step
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
                End
            end
        end
    in
        {ApplyFade 0.0 AV}
    end
    
    fun {Cut I StartCut EndCut AV End}
        if I =< EndCut then
            if I < 0 then
                0.|{Cut I+1 StartCut EndCut AV End}
            else
                case AV
                of H|T then
                    if I < StartCut then
                        0.|{Cut I+1 StartCut EndCut T End}
                    else
                        H|{Cut I+1 StartCut EndCut T End}
                    end
                else
                    0.|{Cut I+1 StartCut EndCut nil End}
                end
            end
        else
            End
        end
    end
    
    fun {MergeTwo I1 AV1 I2 AV2 End}
        case AV1#AV2
        of (H1|T1)#(H2|T2) then
            (I1*H1 + I2*H2)|{MergeTwo I1 T1 I2 T2 End}
        [] (H1|T1)#nil then
            (I1*H1)|{MergeTwo I1 T1 I2 nil End}
        [] nil#(H2|T2) then
            (I2*H2)|{MergeTwo I1 nil I2 T2 End}
        [] nil#nil then
            End
        end
    end
    
    fun {MergeMusics List End}
        case List
        of (I#M)|T then
            {MergeTwo I {MusicToAV M nil} 1.0 {MergeMusics T nil} End}
        else
            nil
        end
    end
    
    fun {PieceToAV Piece End}
        case Piece
        of voix(V) then
            {VoiceToAV V End}
        [] partition(P) then
            {VoiceToAV {Interprete P} End}
            
        [] wave(F) then
            {Projet.readFile F}|End
        [] merge(L) then
            {MergeMusics L End}
        [] echo(delai:D M) then
            {EchoMusic D 1.0 1 M End}
        [] echo(delai:D decadence:Dc M) then
            {EchoMusic D Dc 2 M End}
        [] echo(delai:D decadence:Dc repetition:R M) then
            {EchoMusic D Dc R M End}
        
        %filtres
        [] renverser(M) then
            {Reverse {MusicToAV M nil} End}
        [] repetition(nombre:N M) then
            {RepeatNumber N nil {MusicToAV M nil} End}
        [] repetition(duree:D M) then
            {RepeatToLength {ToAVLength D} nil {MusicToAV M nil} End}
        [] clip(bas:L haut:H M) then
            {Clip L H {MusicToAV M nil} End}
        [] fondu(ouverture:I fermeture:O M) then
            {Fade I O {MusicToAV M nil} End}
        %[] fondue_enchaine(duree:D M1 M2) then
        [] couper(debut:D fin:F M) then
            {Cut {Min 0 {ToAVLength D}} {ToAVLength D} {ToAVLength F} {MusicToAV M nil} End}
        end
    end
    
    fun {MusicToAV Music End}
        case Music
        of H|T then
            {PieceToAV H {MusicToAV T End}}
        [] nil then
            End
        else
            {PieceToAV Music End}
        end
    end
    
in
    
    {MusicToAV Music nil}
end
