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

    \insert 'mix.oz'
    \insert 'interprete.oz'

    local 
        %[Joie JoieShort] = \insert 'joie.dj.oz'
        Soupe = \insert 'soupe.dj.oz'
        Start End
    in
        % Votre code DOIT appeler Projet.run UNE SEULE fois.  Lors de cet appel,
        % vous devez mixer une musique qui démontre les fonctionalités de votre
        % programme.
        %
        % Si votre code devait ne pas passer nos tests, cet exemple serait le
        % seul qui ateste de la validité de votre implémentation.
        
        Start={Time.time}
        
        %{Browse {Projet.run Mix Interprete partition(Joie) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete partition(JoieShort) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete partition(Soupe) 'out.wav'}}
        
        %{Browse {Projet.run Mix Interprete partition([silence a]) 'out.wav'}}
        %{Browse {Interprete bourdon(note:a muet(b))}}
        %{Browse {Projet.run Mix Interprete repetition(nombre:3 partition([a b])) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete repetition(duree:5.0 partition([a b])) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete merge([0.5#partition(e) 0.5#partition(a)]) 'out.wav'}}
        %{Browse {Projet.run Mix Interprete echo(delai:1.1 decadence:0.3 repetition:3 partition(a)) 'out.wav'}}
        {Browse {Projet.run Mix Interprete fondu(ouverture:2.0 fermeture:2.0 partition(Soupe)) 'out.wav'}}
        
        End={Time.time}
        
        {Browse End-Start}
    end
end

