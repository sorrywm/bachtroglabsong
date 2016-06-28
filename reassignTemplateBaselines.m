function outputData = reassignTemplateBaselines(outputData, isNoise, options)
    %re-calculate template baselines using new noise assignments
    %generate options
    if nargin < 3 || isempty(options)
        options.setAll = true;
    else
        options.setAll = false;
    end
    options = makeDefaultOptions(options);
    %find baseline noise levels
    fprintf(1,'   Calculating Baseline Noise Levels\n');
    [baselines,~] = findTemplateBaselines(outputData.templates,...
        outputData.coeffs,outputData.means,outputData.projStds,...
        isNoise, options.baseline_quantile);
    
    outputData.baselines = baselines;

    outputData.isNoise = isNoise;
end