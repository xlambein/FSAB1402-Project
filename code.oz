% Vous ne pouvez pas utiliser le mot-clé 'declare'.
local Mix Interprete Projet in
    [Projet] = {Link ['Projet2014_mozart2.ozf']}
    % Si vous utilisez Mozart 1.4, remplacez la ligne précédente par celle-ci :
    % [Projet] = {Link ['Projet2014_mozart1.4.ozf']}
    %
    % Projet fournit quatre fonctions :
    % {Projet.run Interprete Mix Music 'out.wav'} = ok OR error(...) 
    % {Projet.readFile FileName} = audioVector(AudioVector) OR error(...)
    % {Projet.writeFile FileName AudioVector} = ok OR error(...)
    % {Projet.load 'music_file.oz'} = Oz structure.
    %
    % et une constante :
    % Projet.hz = 44100, la fréquence d'échantilonnage (nombre de données par seconde)

    % Mix prends une musique et doit retourner un vecteur audio.
    fun {Mix Interprete Music}
        % Test avec un seul échantillon
        local N Freq Vectorise EchantillonToAudio VoixToAudio MorceauToAudio MusiqueToAudio in
            fun {Vectorise Freq I N End}
                local Tau=6.283185307 in
                    if I < N-1 then
                        0.5*{Sin Tau*Freq*{IntToFloat I}/{IntToFloat Projet.hz}}|{Vectorise Freq I+1 N End}
                    else
                        0.5*{Sin Tau*Freq*{IntToFloat I}/{IntToFloat Projet.hz}}|End
                    end
                end
            end
            
            fun {EchantillonToAudio Echantillon End}
                local N Freq in
                    N = {FloatToInt {IntToFloat Projet.hz}*Echantillon.duree}
                    case Echantillon
                    of silence(duree:D) then
                        Freq = 0
                    [] echantillon(hauteur:H duree:D instrument:I) then
                        Freq = {Pow 2. {IntToFloat H}/12.}*440.
                    end
            
                    {Vectorise Freq 0 N End}
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
            
            fun {FiltreRenverser VA Acc}
                case VA
                of H|T then
                    {FiltreRenverser T H|Acc}
                [] nil then
                    Acc
                end
            end
            
            fun {FiltreRepetitionNombre Nombre VA FullVA}
                case VA
                of H|T then
                    H|{FiltreRepetitionNombre Nombre T FullVA}
                [] nil then
                    if Nombre > 0 then
                        {FiltreRepetitionNombre Nombre-1 FullVA FullVA}
                    else
                        nil
                    end
                end
            end
            
            fun {FiltreRepetitionNbEch NbEch VA FullVA}
                if NbEch > 0 then
                    case VA
                    of H|T then
                        H|{FiltreRepetitionNombre NbEch-1 T FullVA}
                    [] nil then
                        {FiltreRepetitionNombre NbEch-1 FullVA FullVA}
                    end
                else
                    nil
                end
            end
            
            fun {FiltreClip Bas Haut VA}
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
                        R|{FiltreClip Bas Haut T}
                    end
                [] nil then
                    nil
                end
            end
            
            fun {EchoIntensiteTotale Decadence Repetition A1 A2}
                if Repetition == 0 then
                    A1
                else
                    local R=A2*Decadence in
                        {EchoIntensiteTotale Decadence Repetition-1 A1+R R}
                    end
                end
            end
            
            fun {FiltreFondueOuverture Duree VA Pos}
                case VA
                of H|T then
                    if Pos < Duree then
                        H*(Pos/Duree)|{FiltreFondueOuverture Duree T Pos+(1.0/Project.hz)}
                    else
                        H|T
                    end
                [] nil then
                    nil
                end
            end
            
            fun {FiltreFondueOuverture Duree VA Pos}
                case VA
                of H|T then
                    local NextPos Rest in
                        Pos = NextPos+(1.0/Project.hz)
                        if Pos < Duree then
                            H*(Pos/Duree)|Rest
                        else
                            H
                        end
                        % This is weird but it's necessary for tail-recursivity
                        Rest = {FiltreFondueOuverture Duree T NextPos}
                    end
                [] nil then
                    Pos = 0.0
                    nil
                end
            end
            
            fun {MorceauToAudio Morceau}
                case Morceau
                of voix(V) then
                    {VoixToAudio V}
                [] partition(P) then
                    {VoixToAudio voix({Interprete P})}
                [] wave(F) then
                    {Project.readFile F}
                %[] merge(M) then
                %    
                
                %filtres
                [] renverser(M) then
                    {FiltreRenverser {MorceauToAudio M} nil} 
                [] repetition(nombre:N M) then
                    local Audio={MorceauToAudio M} in
                        {FiltreRepetitionNombre N Audio Audio}
                    end
                [] repetition(duree:D M) then
                    local Audio={MorceauToAudio M} in
                        {FiltreRepetitionNbEch {FloatToInt D*{IntToFloat Projet.hz}} Audio Audio}
                    end
                [] clip(bas:B haut:H M) then
                    {FiltreClip B H {MorceauToAudio M}}
                %[] echo(delai:D M) then
                %    {MorceauToAudio merge([0.5#M 0.5#[voix([silence(duree:D)]) M]])}
                %[] echo(delai:D decadence:Dc M) then
                %[] echo(delai:D decadence:Dc repetition:R M) then
                %    local IntensiteTotale={EchoIntensiteTotale D R 1.0 1.0} in
                %    end
                [] fondue(ouverture:O fermeture:F M) then
                    {FiltreFondueFermeture F
                        {FiltreFondueOuverture O {MorceauToAudio M} 0.0}
                        _}
                %[] fondue_enchaine(duree:D M1 M2) then
                %[] couper(debut:D fin:F M) then
                end
            end
            
            fun {MusiqueToAudio Musique End}
                case Musique
                of H|T then
                    {MorceauToAudio H}|{MusiqueToAudio T End}
                [] nil then
                    End
                else
                    {MorceauToAudio Musique}|End
                end 
            end
            
            {MusicToAudio Music nil}
        end
    end

    % Interprete doit interpréter une partition
    fun {Interprete Partition}
        ToNote
        NoteHauteur
        MakeMuet
        MakeEtirer
        CalculerDuree
        MakeDuree
        MakeBourdon
        MakeTranspose
        Composer
        InterpreteRecursive
    in
        fun {ToNote Note}
           case Note
           of Nom#Octave then note(nom:Nom octave:Octave alteration:'#')
           [] Atom then
              case {AtomToString Atom}
              of [_] then note(nom:Atom octave:4 alteration:none)
              [] [N O] then note(nom:{StringToAtom [N]}
                                 octave:{StringToInt [O]}
                                 alteration:none)
              end
           end
        end

        fun {NoteHauteur Note}
            Base
        in
            case Note.nom
            of c then Base=0
            [] d then Base=2
            [] e then Base=4
            [] f then Base=5
            [] g then Base=7
            [] a then Base=9
            [] b then Base=11
            end
            
            case Note.alteration
            of '#' then Base-9 + (Note.octave-4)*12 + 1
            [] none then Base-9 + (Note.octave-4)*12
            end
        end

        fun {MakeMuet}
            fun {$ Echantillon }
                case Echantillon
                of silence(duree:_) then
                    Echantillon
                [] echantillon(hauteur:_ duree:D instrument:_) then
                    silence(duree:D)
                end
            end
        end

        fun {MakeEtirer Facteur}
            fun {$ Echantillon}
                case Echantillon
                of silence(duree:D) then
                    silence(duree:D*Facteur)
                [] echantillon(hauteur:H duree:D instrument:I) then
                    echantillon(hauteur:H
                                duree:D*Facteur
                                instrument:I)
                end
            end
        end

        fun {CalculerDuree Partition}
            case Partition
            
            % suite de partitions
            of nil then
                0.0
            [] H|T then
                {CalculerDuree H} + {CalculerDuree T}

            % transformation
            [] muet(P) then
                {CalculerDuree P}
            [] duree(secondes:D _) then
                D
            [] etirer(facteur:F P) then
                F*{CalculerDuree P}
            [] bourdon(note:_ P) then
                {CalculerDuree P}
            [] transpose(demitons:_ P) then
                {CalculerDuree P}

            % note
            else
                1.0
            end
        end

        fun {MakeDuree Partition DureeTotale}
            {MakeEtirer DureeTotale/{CalculerDuree Partition}}
        end

        fun {MakeBourdon Note}
            case Note
            of silence then
                fun {$ Echantillon}
                    silence(duree:Echantillon.duree)
                end
            else
                fun {$ Echantillon}
                    echantillon(hauteur:{NoteHauteur {ToNote Note}}
                                duree:Echantillon.duree
                                instrument:none)
                end
            end
        end

        fun {MakeTranspose Demitons}
            fun {$ Echantillon}
                case Echantillon
                of silence(duree:_) then
                    Echantillon
                [] echantillon(hauteur:H duree:D instrument:I) then
                    echantillon(hauteur:H+Demitons
                                duree:D
                                instrument:I)
                end
            end
        end

        fun {Composer F1 F2}
            fun {$ A}
                {F1 {F2 A}}
            end
        end

        fun {InterpreteRecursive Partition Mod Next}
            case Partition
            
            % suite de partitions
            of nil then
                Next
            [] H|T then
                {InterpreteRecursive H Mod {InterpreteRecursive T Mod Next}}

            % transformation
            [] muet(P) then
                {InterpreteRecursive P {Composer {MakeMuet} Mod} Next}
            [] duree(secondes:D P) then
                {InterpreteRecursive P {Composer {MakeDuree P D} Mod} Next}
            [] etirer(facteur:F P) then
                {InterpreteRecursive P {Composer {MakeEtirer F} Mod} Next}
            [] bourdon(note:N P) then
                {InterpreteRecursive P {Composer {MakeBourdon N} Mod} Next}
            [] transpose(demitons:DT P) then
                {InterpreteRecursive P {Composer {MakeTranspose DT} Mod} Next}

            % note
            [] silence then
                {Mod silence(duree:1.0)}|Next
            else
                {Mod echantillon(hauteur:{NoteHauteur {ToNote Partition}}
                                 duree:1.0
                                 instrument:none)}|Next
            end
        end

        {InterpreteRecursive Partition fun {$ Echantillon} Echantillon end nil}
    end

    local 
        Music = {Projet.load 'joie.dj.oz'}      
    in
        % Votre code DOIT appeler Projet.run UNE SEULE fois.  Lors de cet appel,
        % vous devez mixer une musique qui démontre les fonctionalités de votre
        % programme.
        %
        % Si votre code devait ne pas passer nos tests, cet exemple serait le
        % seul qui ateste de la validité de votre implémentation.
        %{Browse {Projet.run Mix Interprete Music 'out.wav'}}
        {Browse {Projet.run Mix Interprete partition(Music) 'out.wav'}}
    end
end

