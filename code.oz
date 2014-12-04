% code.oz
%
% Authors: Xavier Lambein (54621300)
%          Victor Lecomte (65531300)
% Date: 2014-12-04

local Mix Interprete Projet ProcBenchmark FunBenchmark in
    [Projet] = {Link ['Projet2014_mozart2.ozf']}

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
        Zelda = \insert 'exemple.dj.oz'
    in
        {ProcBenchmark proc {$}
        
        {Browse {Projet.run Mix Interprete Zelda 'out.wav'}}
        
        % Code samples for testing:
        
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

