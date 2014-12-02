% Transforme une partition en une suite d'échantillons.
fun {Interprete Partition}
    
    % Calculs de notes
    ToNote
    NoteHauteur
    
    % Calculs de transformations
    CalculerDuree
    MakeDuree
    MakeEtirer
    MakeBourdon
    MakeMuet
    MakeTranspose
    
    % Interprétation
    Composer
    InterpreteRecursive
    
in
    
    % Exprime une note a, b3, e#2, ... comme un record note(...).
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
    
    % Donne la hauteur d'une note par rapport à a4, en demi-tons.
    fun {NoteHauteur Note}
        Base
    in
        % Hauteur de la note dans l'octave
        case Note.nom
        of c then Base=0
        [] d then Base=2
        [] e then Base=4
        [] f then Base=5
        [] g then Base=7
        [] a then Base=9
        [] b then Base=11
        end
        
        % La différence des hauteurs dépend de la différence à l'intérieur de
        % l'octave, de la différence d'octave et de l'altération.
        case Note.alteration
        of '#' then Base-9 + (Note.octave-4)*12 + 1
        [] none then Base-9 + (Note.octave-4)*12
        end
    end
    
    
    % Calcule la durée d'une partition.
    fun {CalculerDuree Partition}
        
        % Le calcul dépend du type de partition.
        case Partition
        
        % Si c'est une suite de partitions, on la décompose.
        of nil then
            0.0
        [] H|T then
            {CalculerDuree H} + {CalculerDuree T}
        
        
        % Si c'est une transformation qui modifie la durée, on la prend en
        % compte.
        [] duree(secondes:D _) then
            D
        [] etirer(facteur:F P) then
            F * {CalculerDuree P}
        
        % Sinon, la durée est celle de la partition intégrée.
        [] bourdon(note:_ P) then
            {CalculerDuree P}
        [] muet(P) then
            {CalculerDuree P}
        [] transpose(demitons:_ P) then
            {CalculerDuree P}

        % Enfin, si c'est une note, sa durée est de 1.
        else
            1.0
        end
    end
    
    % Renvoie une fonction qui raccourcit ou allonge les échantillons d'une
    % partition pour que cette dernière atteigne une durée donnée.
    fun {MakeDuree Partition DureeTotale}
        {MakeEtirer DureeTotale/{CalculerDuree Partition}}
    end
    
    % Renvoie une fonction qui étire un échantillon par un certain facteur.
    fun {MakeEtirer Facteur}
        fun {$ Echantillon}
            case Echantillon
            of silence(duree:D) then
                silence(duree:D*Facteur)
            [] echantillon(hauteur:H duree:D instrument:I) then
                echantillon(hauteur:H duree:D*Facteur instrument:I)
            end
        end
    end
    
    % Renvoie une fonction qui change la note d'un échantillon.
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
    
    % Renvoie une fonction qui transforme un échantillon en un silence.
    fun {MakeMuet}
        {MakeBourdon silence}
    end
    
    % Renvoie une fonction qui transpose un échantillon d'un nombre de demi-tons
    % donné.
    fun {MakeTranspose Demitons}
        fun {$ Echantillon}
            case Echantillon
            % Si c'est un silence, il ne faut rien changer.
            of silence(duree:_) then
                Echantillon
            % Sinon, on augmente la hauteur du nombre donné.
            [] echantillon(hauteur:H duree:D instrument:I) then
                echantillon(hauteur:H+Demitons duree:D instrument:I)
            end
        end
    end
    
    
    % Composée de deux transformations.
    fun {Composer F1 F2}
        fun {$ A}
            {F1 {F2 A}}
        end
    end
    
    % Interprète une partition de manière récursive, où Mod est une ou plusieurs
    % transformations à appliquer aux échantillons, et Next un accumulateur
    % d'échantillons déjà calculés à ajouter à la fin.
    fun {InterpreteRecursive Partition Mod Next}
        
        % La prochaine opération dépend du type de partition
        case Partition
        
        % Si c'est une suite de partitions, on la décompose.
        of nil then
            Next
        [] H|T then
            {InterpreteRecursive H Mod {InterpreteRecursive T Mod Next}}

        % Si c'est une transformation, on l'ajoute aux transformations Mod à
        % appliquer par après.
        [] duree(secondes:D P) then
            {InterpreteRecursive P {Composer Mod {MakeDuree P D}} Next}
        [] etirer(facteur:F P) then
            {InterpreteRecursive P {Composer Mod {MakeEtirer F}} Next}
        [] bourdon(note:N P) then
            {InterpreteRecursive P {Composer Mod {MakeBourdon N}} Next}
        [] muet(P) then
            {InterpreteRecursive P {Composer Mod {MakeMuet}} Next}
        [] transpose(demitons:DT P) then
            {InterpreteRecursive P {Composer Mod {MakeTranspose DT}} Next}

        % Si c'est une note, on prend un échantillon de durée 1 correspondant,
        % on applique les transformations, et on l'ajoute en tête de liste.
        [] silence then
            {Mod silence(duree:1.0)}|Next
        else
            {Mod echantillon(hauteur:{NoteHauteur {ToNote Partition}}
                             duree:1.0
                             instrument:none)}|Next
        end
    end
    
    
    % On appelle la fonction récursive avec une transformation identité et un
    % accumulateur vide.
    {InterpreteRecursive Partition fun {$ Echantillon} Echantillon end nil}
end
