function [softbits,sampinst] = campionatore(A, synchwave)
% Ritorna il segnale A campionato sui fronti (+) di synchwave
%   La synchwave viene traslata tra 0 e 1. Vengono poi individuati i fronti
%   positivi o negativi mediante diff che effettua la differenza tra
%   elementi adiacenti di un array. Con find vengono trovati gli istanti di
%   campionamento, i quali sono poi passati come indici di A.
    sample = [0, diff(synchwave > 0)];
    sampinst = find(sample == 1);
    softbits = A(sampinst);
end