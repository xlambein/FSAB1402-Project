% Vous ne pouvez pas utiliser le mot-clé 'declare'.
local Mix Interprete Projet ProcBenchmark FunBenchmark in
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

    \insert 'mix.oz'
    \insert 'interprete.oz'
    
    proc {ProcBenchmark Proc Description}
        Start End
    in
        Start = {Time.time}
        {Proc}
        End = {Time.time}
        {Browse {VirtualString.toAtom Description#': '#(End-Start)#' seconds.'}}
    end
    fun {FunBenchmark Fun Description}
        Start End Result
    in
        Start = {Time.time}
        Result = {Fun}
        End = {Time.time}
        {Browse {VirtualString.toAtom Description#': '#(End-Start)#' seconds.'}}
        Result
    end

    local 
        %[Joie JoieShort] = \insert 'joie.dj.oz'
        %Soupe = \insert 'soupe.dj.oz'
        %Compo = \insert 'compo.dj.oz'
        Zelda = \insert 'zelda.dj.oz'
    in
        % Votre code DOIT appeler Projet.run UNE SEULE fois.  Lors de cet appel,
        % vous devez mixer une musique qui démontre les fonctionalités de votre
        % programme.
        %
        % Si votre code devait ne pas passer nos tests, cet exemple serait le
        % seul qui ateste de la validité de votre implémentation.
        
        {ProcBenchmark proc {$}
        
        %{Browse {Projet.run Mix Interprete partition(Joie) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete partition(JoieShort) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete partition(Soupe) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete Compo 'compo.wav'}}
        {Browse {Projet.run Mix Interprete Zelda 'out.wav'}}
        
        %{Browse {Projet.run Mix Interprete partition([silence a]) 'out.wav'}}
        %{Browse {Interprete bourdon(note:a muet(b))}}
        %{Browse {Projet.run Mix Interprete renverser(partition(Soupe)) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete repetition(nombre:3 partition([a b])) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete repetition(duree:5.0 partition([a b])) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete repetition(nombre:2 partition(Soupe)) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete clip(bas:~0.1 haut:0.1 partition(Soupe)) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete merge([0.5#partition(e) 0.5#partition(a)]) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete echo(delai:1.1 decadence:0.3 repetition:3 partition(a)) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete echo(delai:0.56 partition([Soupe Soupe])) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete fondu(ouverture:2.0 fermeture:2.0 partition(Soupe)) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete fondu_enchaine(duree:2.0 partition(Joie) partition(Soupe)) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete couper(debut:~2.0 fin:6.0 partition(Soupe)) 'out.wav'}}
	    %{Browse {Projet.run Mix Interprete partition(etirer(facteur:0.15 instrument(nom:'8bit_stab' [c3 c#3 d3 d#3 e3 f3 f#3 g3 instrument(nom:'woody' [g#3 a3 a#3 b3]) c c#4 d d#4 e f f#4 g g#4 a a#4 b]))) 'out.wav'}}
        
        end 'Projet.run'}
    end
end

