% Mix prends une musique et doit retourner un vecteur audio.
fun {Mix Interprete Music}
    fun {DureeToNbEch Duree}
        {FloatToInt Duree*{IntToFloat Projet.hz}}
    end

    fun {Vectorise Freq I N End}
        local Tau=6.283185307 X X0 F in
            if I < N then
                %X = 500.*{IntToFloat I}/{IntToFloat Projet.hz}
                %X0 = 500.*{IntToFloat N}/{IntToFloat Projet.hz}
                %F = X/(X + 1.)*(X-X0)/(X-X0-1.)
                X = {IntToFloat I}/{IntToFloat Projet.hz}
                X0 = {IntToFloat N}/{IntToFloat Projet.hz}
                F = X/(X + 0.005) * (X0-X)/(X0-X + 0.005)
                if Freq == 0 then
                    0.|{Vectorise 0 I+1 N End}
                else
                    F*0.5*{Sin Tau*Freq*{IntToFloat I}/{IntToFloat Projet.hz}}|{Vectorise Freq I+1 N End}
                end
            else
                End
            end
        end
    end
    
    fun {EchantillonToAudio Echantillon End}
        local N Freq in
            case Echantillon
            of silence(duree:D) then
                Freq = 0
            [] echantillon(hauteur:H duree:D instrument:I) then
                Freq = {Pow 2. {IntToFloat H}/12.}*440.
            end

            {Vectorise Freq 0 {FloatToInt {IntToFloat Projet.hz}*Echantillon.duree} End}
        end
    end
    
    fun {VoixToAudio Voix End}
        case Voix
        of voix(V) then
            {VoixToAudio V End}
        [] H|T then
            {EchantillonToAudio H {VoixToAudio T End}}
        else
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
        %{Browse NbEch}
        if NbEch == 0 then
            End
        else
            case Start
            of H|T then
                H|{FiltreRepetitionNbEch NbEch-1 T VA End}
            [] nil then
                %{Browse 1}
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
    
    fun {FiltreEcho Delai Decadence Repetition VA End}
        IntensiteTotale = (1.0 - {Pow Decadence {IntToFloat Repetition+1.0}}) / (1.0 - Decadence)
    in
        %{FiltreMerge
        VA|End
    end
    
    fun {FiltreFondueOuverture Duree VA Pos End}
        case VA
        of H|T then
            if Pos < Duree then
                H*(Pos/Duree)|{FiltreFondueOuverture Duree T Pos+(1.0/Projet.hz) End}
            else
                H|T
            end
        [] nil then
            End
        end
    end
    
    fun {FiltreFondueFermeture Duree VA Pos End}
        case VA
        of H|T then
            local NextPos Rest in
                Rest = {FiltreFondueFermeture Duree T NextPos End}
                Pos = NextPos+(1.0/Projet.hz)

                if Pos < Duree then
                    H*(Pos/Duree)|Rest
                else
                    H|Rest
                end
            end
        [] nil then
            Pos = 0.0
            End
        end
    end
    
    fun {FitreCouper I Debut Fin VA End}
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
                    0.|{FiltreCouper I+1 Debut Fin T End}
                end
            end
        else
            End
        end
    end
    
    fun {MergeWith I VA1 VA2 End}
        case VA1#VA2
        of (H1|T1)#(H2|T2) then
            (I*H1 + H2)|{MergeWith I T1 T2 End}
        [] (H1|T1)#nil then
            (I*H1)|{MergeWith I T1 nil End}
        [] nil#(H2|T2) then
            H2|{MergeWith I nil T2 End}
        [] nil#nil then
            End
        end
    end
    
    fun {Merge List End}
        case List
        of (I#M)|T then
            {MergeWith I {MorceauToAudio M nil} {Merge T nil} End}
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
        
        %filtres
        [] renverser(M) then
            {FiltreRenverser {MorceauToAudio M nil} End}
        [] repetition(nombre:N M) then
            {FiltreRepetitionNombre N nil {MorceauToAudio M nil} End}
        [] repetition(duree:D M) then
            {FiltreRepetitionNbEch {DureeToNbEch D} nil {MorceauToAudio M nil} End}
        [] clip(bas:B haut:H M) then
            {FiltreClip B H {MorceauToAudio M nil} End}
        [] echo(delai:D M) then
            {FiltreEcho D 1.0 1 {MorceauToAudio M nil} End}
        [] echo(delai:D decadence:Dc M) then
            {FiltreEcho D Dc 1 {MorceauToAudio M nil} End}
        [] echo(delai:D decadence:Dc repetition:R M) then
            {FiltreEcho D Dc R {MorceauToAudio M nil} End}
        [] fondue(ouverture:O fermeture:F M) then
            {FiltreFondueFermeture F
            {FiltreFondueOuverture O {MorceauToAudio M nil} 0.0 End}
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
