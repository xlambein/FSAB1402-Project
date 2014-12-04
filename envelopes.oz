fun {EnvTrapezoid Dur}
    Att = 0.03
    Rel = 0.03
in
    fun {$ Pos}
        if Pos < Att then
            Pos/Att
        elseif Dur-Pos < Rel then
            (Dur-Pos)/Rel
        else
            1.0
        end
    end
end

fun {EnvADSR Dur}
    Att = 0.02
    Dec = 0.01
    Sus = 0.8
    Rel = 0.02
in
    fun {$ Pos}
        if Pos < Att then
            Pos/Att
        elseif Pos-Att < Dec then
            1.0 + (Sus-1.0)*(Pos-Att)/Dec
        elseif Dur-Pos < Rel then
            Sus * (Dur-Pos)/Rel
        else
            Sus
        end
    end
end

fun {EnvHyperbola Dur}
    Att = 0.05
    Scaling = ((Dur+2.0*Att)*(Dur+2.0*Att)) / (Dur*Dur)
in
    fun {$ Pos}
        Scaling * Pos/(Pos+Att) * (Dur-Pos)/(Dur-Pos+Att)
    end
end
