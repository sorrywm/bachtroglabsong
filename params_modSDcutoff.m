%put custom changes to default the parameters in FetchParams here
%the parameters actually used are returned by FlySongSegmenter in Params

%note that dealing with github is MUCH easier if you DO NOT modify this
%params file, but rather copy it, modify the copy, use the copy to process
%data, and don't check the copy into git

%e.g.
%Parms.Fs = 10000;
Params.Fs = 6000;
Params.cutoff_sd = 5;                 % exclude data above this multiple of the std. deviation
Params.find_sine = false;