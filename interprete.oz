% Transforms a score into a list of samples (a voice)
fun {Interprete Score}
    
    % Note computations
    ToNote
    NotePitch
    
    % Transformations
    Duration
    MakeScale
    MakeResize
    MakeMute
    MakeConstant
    MakeTranspose
    MakeChangeInstrument
    
    % Interpretation
    Compose
    InterpreteRecursive
    
in
    
    % Expresses a note (a, b3, e#2, ...) as a record note(...).
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
    
    % Gives the pitch of a note relative a4, in semitones.
    fun {NotePitch Note}
        InOctave
    in
        % Pitch of the note within the octave
        case Note.nom
        of c then InOctave = 0
        [] d then InOctave = 2
        [] e then InOctave = 4
        [] f then InOctave = 5
        [] g then InOctave = 7
        [] a then InOctave = 9
        [] b then InOctave = 11
        end
        
        % The pitch difference depends on the difference within an octave,
        % and on the octave difference. A sharp (#) adds one semitone.
        case Note.alteration
        of '#' then InOctave-9 + (Note.octave-4)*12 + 1
        [] none then InOctave-9 + (Note.octave-4)*12
        end
    end
    
    
    % Computes the duration of a score
    fun {Duration Score}
        
        % Computation depends on the type of score.
        case Score
        
        % If it is a list of scores, we decompose it.
        of nil then
            0.0
        [] H|T then
            {Duration H} + {Duration T}
        
        
        % If it is a transformation that affects time, we take it into account.
        [] duree(secondes:D _) then
            D
        [] etirer(facteur:F S) then
            F * {Duration S}
        
        % For other transformations, it is the duration of the embedded score.
        [] bourdon(note:_ S) then
            {Duration S}
        [] muet(S) then
            {Duration S}
        [] transpose(demitons:_ S) then
            {Duration S}

        % Finally, if it's a note, duration is 1.
        else
            1.0
        end
    end
    
    % Makes a function that scales samples by some factor.
    fun {MakeScale Factor}
        fun {$ Sample}
            case Sample
            of silence(duree:D) then
                silence(duree:D*Factor)
            [] echantillon(hauteur:P duree:D instrument:I) then
                echantillon(hauteur:P duree:D*Factor instrument:I)
            end
        end
    end
    
    % Makes a function that resizes samples, so that the score can reach a
    % specified length.
    fun {MakeResize Score NewDuration}
        {MakeScale NewDuration/{Duration Score}}
    end
    
    % Make a function that changes any sample to a rest.
    fun {MakeMute}
        fun {$ Sample}
            silence(duree:Sample.duree)
        end
    end
    
    % Make a function that changes the notes of samples to a specified note.
    fun {MakeConstant Note}
        case Note
        of silence then
            {MakeMute}
        else
            Pitch = {NotePitch {ToNote Note}}
        in
            fun {$ Sample}
                echantillon(hauteur:Pitch
                            duree:Sample.duree
                            instrument:none)
            end
        end
    end
    
    % Makes a function that transposes a sample by some number of semitones.
    fun {MakeTranspose Semitones}
        fun {$ Sample}
            case Sample
            % If it is a silence, there is nothing to change.
            of silence(duree:_) then
                Sample
            % Otherwise we add the semitones to the pitch.
            [] echantillon(hauteur:P duree:D instrument:I) then
                echantillon(hauteur:P+Semitones duree:D instrument:I)
            end
        end
    end
    
    % Makes a function that changes a sample's instrument from none to Name.
    fun {MakeChangeInstrument Name}
        fun {$ Sample}
            case Sample
            % Only if it is a sample with instrument none we change it.
            of echantillon(hauteur:P duree:D instrument:none) then
                echantillon(hauteur:P duree:D instrument:Name)
            else
                Sample
            end
        end
    end
    
    
    % Transformation composition.
    fun {Compose F1 F2}
        fun {$ A}
            {F1 {F2 A}}
        end
    end
    
    % Interpretes a score recursively, where Mod is a series of transformations
    % to apply to samples, and Next is an accumulator of samples.
    fun {InterpreteRecursive Score Mod Next}
        
        % The next operation depends on the type of score.
        case Score
        
        % If it is a list of scores, we decompose it.
        of nil then
            Next
        [] H|T then
            {InterpreteRecursive H Mod {InterpreteRecursive T Mod Next}}
        
        % If it is a transformation, we add it at the beginning of Mod, since
        % it has to be performed first. (Beware of the composition order!)
        [] duree(secondes:D S) then
            {InterpreteRecursive S {Compose Mod {MakeResize S D}} Next}
        [] etirer(facteur:F S) then
            {InterpreteRecursive S {Compose Mod {MakeScale F}} Next}
        [] muet(S) then
            {InterpreteRecursive S {Compose Mod {MakeMute}} Next}
        [] bourdon(note:N S) then
            {InterpreteRecursive S {Compose Mod {MakeConstant N}} Next}
        [] transpose(demitons:St S) then
            {InterpreteRecursive S {Compose Mod {MakeTranspose St}} Next}
        [] instrument(nom:N S) then
            {InterpreteRecursive S {Compose Mod {MakeChangeInstrument N}} Next}
        
        % If it is a note, we create the right 1-second sample, we apply the
        % transformations, and we add it to the list.
        [] silence then
            {Mod silence(duree:1.0)}|Next
        [] RawNote then
            {Mod echantillon(hauteur:{NotePitch {ToNote RawNote}}
                             duree:1.0
                             instrument:none)}|Next
        end
    end
    
    % We call the recursive function with the identity transformation and an
    % empty accumulator.
    {FunBenchmark fun {$}
    {InterpreteRecursive Score fun {$ Sample} Sample end nil}
    end 'Interprete'}
end
