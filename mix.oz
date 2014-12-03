% Mix prends une musique et doit retourner un vecteur audio.
fun {Mix Interprete Music} Vectorise EchantillonToAudio VoixToAudio FiltreRenverser FiltreRepetitionNombre FiltreRepetitionNbEch FiltreClip EchoIntensiteTotale FiltreFondueOuverture FiltreFondueFermeture MorceauToAudio MusiqueToAudio in
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
        local N NCut Freq in
            N = {FloatToInt {IntToFloat Projet.hz}*Echantillon.duree}
            case Echantillon
            of silence(duree:D) then
                Freq = 0
            [] echantillon(hauteur:H duree:D instrument:I) then
                Freq = {Pow 2. {IntToFloat H}/12.}*440.
            end
            NCut = N mod {FloatToInt {IntToFloat Projet.hz}/Freq}

            {Vectorise Freq 0 N-NCut {Vectorise 0 0 NCut End}}
        end
    end
    
    fun {VoixToAudio Voix End}
        case Voix
        of H|T then
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
    
    fun {FiltreRepetitionNombre Nombre VA FullVA End}
        case VA
        of H|T then
            H|{FiltreRepetitionNombre Nombre T FullVA End}
        [] nil then
            if Nombre > 0 then
                {FiltreRepetitionNombre Nombre-1 FullVA FullVA End}
            else
                End
            end
        end
    end
    
    fun {FiltreRepetitionNbEch NbEch VA FullVA End}
        if NbEch > 0 then
            case VA
            of H|T then
                H|{FiltreRepetitionNombre NbEch-1 T FullVA End}
            [] nil then
                {FiltreRepetitionNombre NbEch-1 FullVA FullVA End}
            end
        else
            End
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
    
    /*fun {EchoIntensiteTotale Decadence Repetition A1 A2}
        if Repetition == 0 then
            A1
        else
            local R=A2*Decadence in
                {EchoIntensiteTotale Decadence Repetition-1 A1+R R}
            end
        end
    end*/
    
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
    
    fun {MorceauToAudio Morceau End}
        case Morceau
        of voix(V) then
            {VoixToAudio V End}
        [] partition(P) then
            local V in
                {VoixToAudio {Interprete P} End}
            end
            
        [] wave(F) then
            {Projet.readFile F}|End
        %[] merge(M) then
        %    
        
        %filtres
        [] renverser(M) then
            {FiltreRenverser {MorceauToAudio M nil} End}
        [] repetition(nombre:N M) then
            local Audio={MorceauToAudio M nil} in
                {FiltreRepetitionNombre N Audio Audio End}
            end
        [] repetition(duree:D M) then
            local Audio={MorceauToAudio M nil} in
                {FiltreRepetitionNbEch {FloatToInt D*{IntToFloat Projet.hz}} Audio Audio End}
            end
        [] clip(bas:B haut:H M) then
            {FiltreClip B H {MorceauToAudio M nil} End}
        %[] echo(delai:D M) then
        %    {MorceauToAudio merge([0.5#M 0.5#[voix([silence(duree:D)]) M]])}
        %[] echo(delai:D decadence:Dc M) then
        %[] echo(delai:D decadence:Dc repetition:R M) then
        %    local IntensiteTotale={EchoIntensiteTotale D R 1.0 1.0} in
        %    end
        [] fondue(ouverture:O fermeture:F M) then
            {FiltreFondueFermeture F
            {FiltreFondueOuverture O {MorceauToAudio M this} 0.0 End}
            _ End}
        %[] fondue_enchaine(duree:D M1 M2) then
        %[] couper(debut:D fin:F M) then
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
    
    {MusiqueToAudio Music nil}
end
