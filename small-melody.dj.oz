local
    Tune = [e5 d5 c5 silence c5 silence b silence a b c5 silence c5 d5 e5 silence
        e5 d5 c5 silence c5 b a c5 b a b g etirer(facteur:3.0 e) silence]
    
    Inter = [f g a silence a b c5 silence]
    InterEnd1 = [c5 d5 e5 silence e5 f5 g5 silence]
    InterEnd2 = [c5 silence g silence etirer(facteur:3.0 g) silence]
    Inter1 = [Inter InterEnd1]
    Inter2 = [Inter InterEnd2]
    
    Trille = [e5 f5]
    Trille4 = etirer(facteur:0.5 [Trille Trille Trille Trille])
    End = [f5 silence f5 e5 d5 e5 f5 b
        Trille4 etirer(facteur:3.0 e5) silence]
in
    etirer(facteur:0.15 [Tune Tune Inter1 Inter2 Inter1 End])
end
