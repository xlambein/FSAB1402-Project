local
    Tune = [e5 d5 c5 b a silence g silence a b c5 silence c5 d5 e5 silence
        e5 d5 c5 b a silence a c5 b a b g etirer(facteur:3.0 e) silence]
    
    Inter = [f silence f g a b c5 silence]
    InterEnd1 = [c5 d5 e5 silence e5 f5 g5 silence]
    InterEnd2 = [silence silence g silence etirer(facteur:3.0 g) silence]
    Inter1 = [Inter InterEnd1]
    Inter2 = [Inter InterEnd2]
    
    Trille = [e5 f5]
    Trille4 = etirer(facteur:0.5 [Trille Trille Trille Trille])
    End = [f5 e5 d5 c5 b c5 d5 b
        Trille4 etirer(facteur:3.0 e5) silence]
in
    transpose(demitons:7 etirer(facteur:0.14
        [Tune Tune Inter1 Inter2 Inter1 End]
    ))
end
