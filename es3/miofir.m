function y = miofir(h, x)
    M = length(h);
    N = length(x);
    dlx = zeros(1, M);
    y = zeros(1, N);
    for i = 1:N
        lpi = i - M + 1; % last possible index
        if lpi > 1
            dlx(1:M) = x(i:-1:lpi);
        else
            dlx(1:i) = x(i:-1:1);
        end
        y(i) = sum(h.*dlx);
    end

end