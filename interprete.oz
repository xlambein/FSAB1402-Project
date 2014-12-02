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
