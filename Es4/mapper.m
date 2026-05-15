function ba = mapper( bk, a )
%ba = mapper( bk, a )
%
% Funzione che ri-mappa i valori del vettore in ingresso, sostituendo 'a' a
% quelli diversi da 0 e '-a' a quelli uguali a 0.

    ba = bk; % allocazione memoria
    for cur = 1 : length( bk )
        if bk(cur) == 0
            ba(cur) = -a;
        else
            ba(cur) = a;
        end
    end
end