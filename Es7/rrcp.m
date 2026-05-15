function ris=rrcp(t,tp,beta,fo)
    % root raised cosine pulse as IEEE802.15.4a
    % tp is the pulse duration parameter
    % beta is the roll-off factor
    % fo the center frequency
    if t==0
        ris=(pi+4*beta-pi*beta)/(pi*sqrt(tp));
    else
        ris=4*beta/(pi*sqrt(tp))*(cos((1+beta)*pi*t./tp)+sin((1-beta)*pi*t./tp)./(4*beta*t./tp))./(1-(4*beta*t./tp).^2).*cos(2*pi*fo*t);
    end
end