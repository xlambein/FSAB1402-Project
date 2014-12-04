fun {EnvTrapezoid Dur}
    Ts = 0.03
in
    fun {$ Pos}
        if Pos < Ts then
            Pos/Ts
        elseif Dur-Pos < Ts then
            (Dur-Pos)/Ts
        else
            1.0
        end
    end
end

fun {EnvADSR Dur}
    A = 0.02
    D = 0.01
    S = 0.8
    R = 0.02
in
    fun {$ Pos}
        if Pos < A then
            Pos/A
        elseif Pos-A < D then
            1.0 + (S-1.0)*(Pos-A)/D
        elseif Dur-Pos < R then
            S * (Dur-Pos)/R
        else
            S
        end
    end
end

fun {EnvHyperbola Dur}
    Ts = 0.05
    Scaling = ((Dur+2.0*Ts)*(Dur+2.0*Ts)) / (Dur*Dur)
in
    fun {$ Pos}
        Scaling * Pos/(Pos+Ts) * (Dur-Pos)/(Dur-Pos+Ts)
    end
end
