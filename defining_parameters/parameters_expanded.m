% This file sets all parameters for FlySongClusterSegment.
%
% Lines that __begin__ with percent (%) will be ignored as comments.
% - Other lines that do not contain an equal sign (=) will also be ignored.
%
% Do not add any parameters that are not listed in the comments.
% - Parameters are explicitly defined in the loadParameters() function.
%
% Parameter lines can be removed. If a parameter is not specified, then the
%    loadParameters() function will assign that parameter an empty list [].
%
% Paths can be absolute, or they can be relative to the .m script containing
%    the loadParameters() function.


% The following line must be the first non-comment line. Do not remove or comment.
Parameter=Value

% prevtempfile: The .mat templates file (relative or absolute path).
prevtempfile=/global/home/users/mattnalley/scripts/flysong/templates/EA_EB_combined.wav_dataTemplatesFromEA_EB_combined.wavFs6000Filt.mat

% whichsignal: A Matlab style list of templates that identify signals.
whichsignal=[7 11 12]

% minpulse: The minimum minimum number of pulses in a pulse train to consider
%    it when calculating summary statistics.
minpulse=10

% maxIPI: The maximum gap between pulses (seconds).
maxIPI=0.08

% ipiptl: Calculate IPI, PTL, or both (ipi / ptl / both).
ipiptl=both

% doplots: (TRUE / FALSE) Whether to generate plots showing the assignment of
%    templates to peaks in the .wav file. For parallel runs, I usually switch
%    this to FALSE.
doplots=FALSE

% remnoise: (TRUE / FALSE) Whether to filter out peaks that were found in the
%    control (empty) channel from this day's recording. This depends on having
%    already generated a noise file from the empty channel, which is a bit
%    difficult to automate, so I've left it as FALSE.
remnoise=FALSE

% numpulsemax: The maximum number of pulses in a train.
numpulsemax=100

% diffThreshold: Used to generate the templates.
diffThreshold=50

% pulsetrainmax: The maximum length of a pulse train (seconds).
pulsetrainmax=1.5

% sigmaThreshold: Multiple of noise amplitude stdev to cut off when filtering.
sigmaThreshold=10

% filtcut: Frequency for high-pass filter (Hz).
filtcut=400

% fs: Frequency of recording (Hz). This may be unnecessary if the frequency is
%    pulled from the .wav file using the audioinfo() function.
fs=6000

% femalecut: If trying to separate male and female pulse trains (see the
%    domalefemale parameter), the minimum threshold for median IPI for a pulse
%    train to be considered female, rather than male.
femalecut=0.025

% baseline_quantile: The quantile of all likelihoods for a given signal template
%    to be used as a baseline for that template; increase this to increase how
%    similar a peak must be to a given template to be assigned to that template.
baseline_quantile=0.95

% template_pca_dimension: Number of principal components to use for transforming
%    templates; cannot be larger than 2*diffThreshold.
template_pca_dimension=10

% domalefemale: Whether to attempt to split pulse trains into male-generated and
%    female-generated, based on their median IPI.
domalefemale=FALSE

% plotanalyzerdir: Location of cluster functions (absolute path).
plotanalyzerdir=/global/home/users/wynn/repos/FlySongClusterSegment/

% segmenterdir: Location of segmenter functions (absolute path).
segmenterdir=/global/home/users/wynn/repos/FlySongSegmenter/

% chronuxdir: Location of chronux (?) functions (absolute path).
chronuxdir=/global/home/users/wynn/repos/FlySongSegmenter/chronux/

% butterdir: Location of filter functions (absolute path).
butterdir=/global/home/users/wynn/repos/bachtroglabsong/

%The following are optional parameters:
%song_range: If desired, can specify start and end times within a song
%            (provided as [start end] in terms of sampling points).
song_range=[]

%noiseLevel: Estimated level of background noise for a given song.
%            Will be estimated from data if negative.
noiseLevel=-1

%The following may be relevant for the next version of assignTemplates:
%isNoise: A nx1 vector with 0 or 1 indicating whether each template is
%         signal or noise. Should be the same height as the number
%         of templates. Will eventually replace whichsignal.
isNoise=[1 1 1 1 1 1 0 1 1 1 0 0]'

%minNoiseLevel: Amplitude threshold below which to filter noise.
minNoiseLevel=0

%The following are relevant for createTemplates:
%use_likelihood_threhold: Whether to use the same baseline threshold for
%                         all templates. 
use_likelihood_threhold=1

%baseline_threshold: Likelihood threshold for signal templates (if this threshold
%                    is not exceeded a peak will be categorized as noise).
baseline_threshold=-90

%min_template_size: Minimum number of observations of a template in
%                   the data to retain it.
min_template_size=5

%IPI_guess: An estimate of the expected IPI (currently in terms of sampling points).
IPI_guess=80

% The following parameters appear to be deprecated.

% Simpler: The output folder will always be where this parameters file is.
%    When these parameters are loaded, the script automatically sets outdir.
% outdir: All output files will be saved here (relative or absolute path).
%%%outdir=./ %%% deprecated

% segopts: A .mat options file (absolute path).
%%%segopts=/global/scratch/mattnalley/chaya_test/athabascaoptions.mat %%% deprecated

% isshort: Unclear what this does.
%%%isshort=n %%% deprecated

% analyzerdir: Location of cluster functions (absolute path).
%%%analyzerdir=/global/home/users/wynn/repos/FlySongClusterSegment/ %%% deprecated

