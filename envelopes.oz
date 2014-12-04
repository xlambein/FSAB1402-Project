% Suggestions:
%   Att = 0.03
%   Rel = 0.03
fun {EnvTrapezoid Att Rel Dur}
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

% Suggestions:
%   Att = 0.02
%   Dec = 0.01
%   Sus = 0.8
%   Rel = 0.02
fun {EnvADSR Att Dec Sus Rel Dur}
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
% Suggestion:
%   soft: Att = 0.05
%   hard: Att = 0.02
fun {EnvHyperbola Att Dur}
    Scaling = ((Dur+2.0*Att)*(Dur+2.0*Att)) / (Dur*Dur)
in
    fun {$ Pos}
        Scaling * Pos/(Pos+Att) * (Dur-Pos)/(Dur-Pos+Att)
    end
end
