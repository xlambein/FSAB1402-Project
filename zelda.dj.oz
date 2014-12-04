local
    Tune = [
        g silence etirer(facteur:2.0 d)
        silence g etirer(facteur:0.5 [g a b c5])
        etirer(facteur:4.0 d5)
        silence d5 etirer(facteur:2.0/3.0 [d5 d#5 f5])
        etirer(facteur:4.0 g5)
        silence g5 etirer(facteur:2.0/3.0 [g5 f5 d#5])
        f5 etirer(facteur:0.5 [silence d#5]) etirer(facteur:2.0 d5)
        etirer(facteur:2.0 [silence d5])
        c5 etirer(facteur:0.5 [c5 d5]) etirer(facteur:2.0 d#5)
        etirer(facteur:2.0 silence) d5 c5
        a#4 etirer(facteur:0.5 [a#4 c5]) etirer(facteur:2.0 d5)
        etirer(facteur:2.0 silence) c5 a#4
        a4 etirer(facteur:0.5 [a4 b4]) etirer(facteur:2.0 c#5)
        etirer(facteur:2.0 [silence e5])
        etirer(facteur:4.0 d5)
    ]
    Bass = [
        g3 d3 g2 d3
        f3 c3 f2 c3
        d#3 a#2 d#2 a#2
        %a#2 f3 a#3 f3
        f3 a#2 f2 a#2
        g#3 d#3 g#2 d#3
        g3 d3 g2 d3
        e3 a2 e2 a2
        d3 a2 d2 a2
    ]
in
    merge([
        0.5#echo(delai:0.8 decadence:0.4 partition(etirer(facteur:0.2 Tune)))
        0.5#partition(etirer(facteur:0.4 Bass))
    ])
end
