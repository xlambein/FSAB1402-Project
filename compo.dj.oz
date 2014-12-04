% Fichier joie.dj.oz

% Hymne à la joie :-)
local
    P1 = [a#3 d g d a#3]
    P2 = [a#3 c#4 f#4 c#4 a#3]
    
    Top = partition(etirer(facteur:0.2
                           [silence P1 g3 P1
                            silence P1 f3 P1
                            silence P1 d#3 P1
                            silence P2 f#3 P2]))
    Bottom = partition(etirer(facteur:2.4 [g3 f3 d#3 f#3]))
in
    fondu(ouverture:0.0 fermeture:1.2
           repetition(nombre:4 merge([0.6#Bottom 0.4#Top])))
end

