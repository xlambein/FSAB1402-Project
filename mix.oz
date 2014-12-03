% Mix prends une musique et doit retourner un vecteur audio.
fun {Mix Interprete Music}

    fun {DureeToNbEch Duree}
        {FloatToInt Duree*{IntToFloat Projet.hz}}
    end
    
    fun {Smoothing Pos D}
        Sm = 0.005 in
        Pos/(Pos+Sm) * (D-Pos)/(D-Pos+Sm)
    end
    
    fun {EchantillonToAudio Echantillon End}
        Pas = 1.0 / {IntToFloat Projet.hz}
    in
        case Echantillon
        of silence(duree:D) then
            fun {Zeros Pos End}
                if Pos < D then
                    0.0|{Zeros Pos+Pas End}
                else
                    End
                end
            end
        in
            {Zeros 0.0 End}
        
        [] echantillon(hauteur:H duree:D instrument:I) then
            Freq = {Pow 2. {IntToFloat H}/12.}*440.
            Tau = 6.283185307
            Omega = Tau*Freq
            Sm = 0.005
            fun {Sinusoid Pos End}
                if Pos < D then
                    0.5*{Smoothing Pos D}*{Sin Omega*Pos}|{Sinusoid Pos+Pas End}
                else
                    End
                end
            end
        in
            {Sinusoid 0.0 End}
        end
    end
    
    fun {VoixToAudio Voix End}
        case Voix
        of H|T then
            {EchantillonToAudio H {VoixToAudio T End}}
        [] nil then
            End
        end
    end
    
    fun {FiltreRenverser VA End}
        case VA
        of H|T then
            {FiltreRenverser T H|End}
        [] nil then
            End
        end
    end
    
    fun {FiltreRepetitionNombre Nombre Start VA End}
        case Start
        of H|T then
            H|{FiltreRepetitionNombre Nombre T VA End}
        [] nil then
            if Nombre == 0 then
                End
            else
                {FiltreRepetitionNombre Nombre-1 VA VA End}
            end
        end
    end
    
    fun {FiltreRepetitionNbEch NbEch Start VA End}
        if NbEch == 0 then
            End
        else
            case Start
            of H|T then
                H|{FiltreRepetitionNbEch NbEch-1 T VA End}
            [] nil then
                {FiltreRepetitionNbEch NbEch VA VA End}
            end
        end
    end
    
    fun {FiltreClip Bas Haut VA End}
        case VA
        of H|T then
            local R in
                if H > Haut then
                    R = Haut
                else if H < Bas then
                    R = Bas
                else
                    R = H
                end
                R|{FiltreClip Bas Haut T End}
            end
            end
        [] nil then
            End
        end
    end
    
    fun {Echo Delai Decadence Repetition M End}
        IntensiteTotale = (1.0 - {Pow Decadence {IntToFloat Repetition}+1.0}) / (1.0 - Decadence)
        fun {ToMerge Decalage Intensite RepetIndex}
            if RepetIndex == Repetition then
                nil
            else
                (Intensite#[voix([silence(duree:Decalage)]) M])|{ToMerge Decalage+Delai Intensite*Decadence RepetIndex+1}
            end
        end
    in
        {Merge {ToMerge 0.0 1.0/IntensiteTotale 0} End}
    end
    
    fun {FiltreFondueOuverture NbEch VA Pos End}
        case VA
        of H|T then
            if Pos < NbEch then
                H*({IntToFloat Pos}/{IntToFloat NbEch})
                |{FiltreFondueOuverture NbEch T Pos+1 End}
            else
                H|T
            end
        [] nil then
            End
        end
    end
    
    fun {FiltreFondueFermeture NbEch VA Pos End}
        case VA
        of H|T then
            local NextPos Rest in
                Rest = {FiltreFondueFermeture NbEch T NextPos End}
                Pos = NextPos+1

                if Pos < Duree then
                    H*({IntToFloat Pos}/{IntToFloat NbEch})|Rest
                else
                    H|Rest
                end
            end
        [] nil then
            Pos = 0
            End
        end
    end
    
    fun {FiltreCouper I Debut Fin VA End}
        if I =< Fin then
            if I < 0 then
                0.|{FiltreCouper I+1 Debut Fin VA End}
            else
                case VA
                of H|T then
                    if I < Debut then
                        0.|{FiltreCouper I+1 Debut Fin T End}
                    else
                        H|{FiltreCouper I+1 Debut Fin T End}
                    end
                else
                    0.|{FiltreCouper I+1 Debut Fin nil End}
                end
            end
        else
            End
        end
    end
    
    fun {FiltreMergeTwo I1 VA1 I2 VA2 End}
        case VA1#VA2
        of (H1|T1)#(H2|T2) then
            (I1*H1 + I2*H2)|{FiltreMergeTwo I1 T1 I2 T2 End}
        [] (H1|T1)#nil then
            (I1*H1)|{FiltreMergeTwo I1 T1 I2 nil End}
        [] nil#(H2|T2) then
            (I2*H2)|{FiltreMergeTwo I1 nil I2 T2 End}
        [] nil#nil then
            End
        end
    end
    
    fun {Merge List End}
        case List
        of (I#M)|T then
            {FiltreMergeTwo I {MusiqueToAudio M nil} 1.0 {Merge T nil} End}
        else
            nil
        end
    end
    
    fun {MorceauToAudio Morceau End}
        case Morceau
        of voix(V) then
            {VoixToAudio V End}
        [] partition(P) then
            {VoixToAudio {Interprete P} End}
            
        [] wave(F) then
            {Projet.readFile F}|End
        [] merge(L) then
            {Merge L End}
        [] echo(delai:D M) then
            {Echo D 1.0 1 M End}
        [] echo(delai:D decadence:Dc M) then
            {Echo D Dc 2 M End}
        [] echo(delai:D decadence:Dc repetition:R M) then
            {Echo D Dc R M End}
        
        %filtres
        [] renverser(M) then
            {FiltreRenverser {MusiqueToAudio M nil} End}
        [] repetition(nombre:N M) then
            {FiltreRepetitionNombre N nil {MusiqueToAudio M nil} End}
        [] repetition(duree:D M) then
            {FiltreRepetitionNbEch {DureeToNbEch D} nil {MorceauToAudio M nil} End}
        [] clip(bas:B haut:H M) then
            {FiltreClip B H {MusiqueToAudio M nil} End}
        [] fondue(ouverture:O fermeture:F M) then
            {FiltreFondueFermeture F
            {FiltreFondueOuverture {DureeToNbEch O} {MusiqueToAudio M nil} 0.0 End}
            _ End}
        %[] fondue_enchaine(duree:D M1 M2) then
        [] couper(debut:D fin:F M) then
            {FiltreCouper {Min 0 {DureeToNbEch D}} {DureeToNbEch D} {DureeToNbEch F} {MorceauToAudio M nil} End}
        end
    end
    
    fun {MusiqueToAudio Musique End}
        case Musique
        of H|T then
            {MorceauToAudio H {MusiqueToAudio T End}}
        [] nil then
            End
        else
            {MorceauToAudio Musique End}
        end
    end
    
in
    
    {MusiqueToAudio Music nil}
end
