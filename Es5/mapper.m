function ba = mapper( bk, a )
    ba = zeros(1, length(bk));
    for cur = 1 : length( bk )
        if bk(cur) == 0
            ba(cur) = -a;
        else
            ba(cur) = a;
        end
    end
end