function folderMap = getfolderMap(FOLDERMAPFILE)
    % Create folderMap to point each species recording channel to a
    % specific path.
    % Optional: Load in folderMap from a file.
    % global FOLDERMAPFILE;
    if exist(FOLDERMAPFILE, 'file') == 2
        fprintf('Loading %s from %s\n',FOLDERMAPFILE,pwd)
        load(FOLDERMAPFILE);
    else
        folderMap = containers.Map();
        folderMap('albomicans') = {'albomicans', 'alb', 'D. albomicans'};
        folderMap('americana') = {'americana', 'ameri'};
        folderMap('ananassae') = {'ananassae', 'ana'};
        %folderMap('athabasca5') = {'athabasca x5 (F1)'};
        %folderMap('athabasca13') = {'athabasca x13 (F1)'};
        %folderMap('athabasca16') = {'athabasca x16 (F1)'};
        folderMap('Cross1') = {'x1','A1','A1a','A1b','F1 (albomicans/nasuta)'};
        folderMap('Cross2') = {'x2','A2','A2a','A2b','F1 (s. bilimbata/s. albostrigata)','F1 (s. albostrigata/s. bilimbata)'};
        folderMap('Cross3') = {'x3','A3','A3a','A3b','F1 (s. sulfurigaster/s. bilimbata)',...
                               'F1 (s. bilimbata/s. sulfurigaster)'};
        folderMap('Cross4') = {'x4','A4','A4a','A4b','F1 (s. sulfurigaster/s. albostrigata',...
                               'F1 (s. albostrigata/s. sulfurigaster)'};
        folderMap('Cross5') = {'x5','A5','A5a','A5b','F1 (s. albostrigata/s. neonasuta)',...
                               'F1 (s. neonasuta/s. albostrigata)','F1 (s. neonasuta/s. albomicans)'};
        folderMap('Cross6') = {'x6','A6','A6a','A6b','F1 (s. bilimbata/s. neonasuta)'};
        folderMap('Cross7') = {'x7','A7','A7a','A7b','F1 (s. bilimbata/pulaua)'};
        folderMap('Cross8') = {'x8','A8','A8a','A8b','Cross8','F1 (pulaua/pallidifrons)'};
        folderMap('Cross9') = {'x9','x9 or albomicans','F1 (albomicans/kepuluana)'};
        x10arr = {'x10','A10','A10a','A10b'};
        for i = 1:100
            x10arr{length(x10arr)+1} = strcat('FC', num2str(i));
        end
        %folderMap('Cross10') = {'x10','A10','A10a','A10b'};
        folderMap('Cross10') = x10arr;
        folderMap('Cross11') = {'x11'};
        folderMap('Cross12') = {'x12'};
        folderMap('Cross13') = {'x13','A13','A13a','A13b'};
        folderMap('Cross14') = {'x14','A14','A14a','A14b'};
        folderMap('Cross15') = {'F1 (kohkoa/pulaua)'};
        folderMap('Cross16') = {'x16','F1 (pulaua/s. neonasuta)'}; %Determine how to include 'neonas/x16'... replace / before saving.
        folderMap('Cross17') = {'x17', 'F1 (nasuta/kepuluana)'};
        folderMap('Cross18') = {'x18','A18','A18a','A18b','A18 or s. sulfurigaster','F1 (s. sulfurigaster/pulaua)'};
        folderMap('Cross19') = {'F1 (s. bilimbata/pallidifrons)'};
        folderMap('Cross20') = {'x20','A20','A20a','A20b'};
        folderMap('Cross21') = {'x21', 'x21?'};
        folderMap('Cross22') = {'x22'};
        folderMap('kepuluana') = {'kepuluana', 'kep', 'Kep'};
        folderMap('kohkoa') = {'kohkoa', 'koh', 'D. kohkoa', 'Kohkoa', 'koh .01'};
        folderMap('nasuta') = {'nasuta', 'nas', 'D. nasuta'};
        folderMap('OtherF1') = {'F1 (s. albostrigata/pulaua)'};
        folderMap('novomexicana') = {'novomexicana', 'novo', 'Novo'};
        folderMap('pallidifrons') = {'pallidifrons', 'D. pallidifrons'};
        %palli if strain is pn175
        folderMap('pallidosa') = {'pallidosa'};
        %palli if with x10 and strain is 20001 or '01' (i think)
        folderMap('pulaua') = {'pulaua', 'pul', 'pulau', 'pul.'};
        folderMap('salb') = {'s alb', 's. alb', 's albostrigata', ...
            's. albostrigata','s alb. ','s alb.', 's. albomicans', 's.albos', 's. alb.', 'sulfurigaster albostrigata'};
        folderMap('sbilim') = {'s bilim', 's. bilim', 's. bilimbata', 's bilimbata', ...
                               'bilim', 's. bil', 's bil', 's.bilim','s.bilimbata', 'sulfurigaster bilimbata'};
        folderMap('sneonasuta') = {'s neonasuta', 's. neonasuta', 's neonas', ...
                                   's. neonas', 'neonas', 'neo nas', 'neo. nas', 'sulfurigaster neonasuta'};
        folderMap('ssulf') = {'s sulf', 's. sulf', 'sulf', 's. sulfurigaster', ...
                              's sulfurigaster', 's. sulf .02', 'sulfurigaster sulfurigaster'};
        folderMap('TaxonF') = {'TaxonF', 'Taxon F', 'D. Taxon F'};
        folderMap('TaxonG') = {'TaxonG', 'Taxon G', 'D. Taxon G'};
        folderMap('TaxonI') = {'TaxonI', 'Taxon I', 'D. Taxon I'};
        folderMap('TaxonJ') = {'TaxonJ', 'Taxon J', 'D. Taxon J'};
        folderMap('virilis') = {'virilis', 'virilis.', 'Virilis'};
        folderMap('lummei') = {'lummei'};
        folderMap('athabasca') = {'athabasca','athabasca x13 (F1)', 'athabasca x 16 (F1)', ...
                                  'athabasca x5 (F1)'};
        folderMap('melanogaster') = {'D. melanogaster', 'melanogaster', 'mel'};
        fprintf('Saving %s in %s\n',FOLDERMAPFILE,pwd)
        save(FOLDERMAPFILE,'folderMap');
    end
end
