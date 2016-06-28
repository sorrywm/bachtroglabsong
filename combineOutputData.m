function combineOutputData(odfilein1, odfilein2, odfileout)
    %combine the outputData files from two different runs
    %of createTemplates + reassignTemplateBaselines
    od1=load(odfilein1);
    od2=load(odfilein2);
    outputData.isNoise=[od1.outputData.isNoise; od2.outputData.isNoise];
    outputData.templates=[od1.outputData.templates; od2.outputData.templates];
    outputData.amplitudes=[od1.outputData.amplitudes; od2.outputData.amplitudes];
    outputData.coeffs=[od1.outputData.coeffs; od2.outputData.coeffs];
    outputData.projStds=[od1.outputData.projStds; od2.outputData.projStds];
    outputData.L_templates=[od1.outputData.L_templates; od2.outputData.L_templates];
    outputData.means=[od1.outputData.means; od2.outputData.means];
    outputData.baselines=[od1.outputData.baselines; od2.outputData.baselines];
    save(odfileout,'outputData');
end