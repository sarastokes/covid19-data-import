classdef EuroCDC < DataSource
% EUROCDC
%
% Constructor:
%   obj = EuroCDC();
%
% Source:
%   https://www.ecdc.europa.eu/en/geographical-distribution-2019-ncov-cases
%
% History:
%   16Apr2020 - SSP
% ------------------------------------------------------------------------

    properties (SetAccess = private)
        data
    end

    methods 
        function obj = EuroCDC(useCache)
            url = 'https://opendata.ecdc.europa.eu/covid19/casedistribution/json/';
            obj@DataSource(url);

            if nargin == 0
                useCache = false;
            end

            obj.data = obj.getData(useCache);
        end

        function T = getData(obj, useCache)

            fprintf('\tEuroCDC: Importing data... ');
            if useCache
                importedData = obj.loadCache();
            else
                try
                    importedData = webread(obj.URL, obj.getWebOptions);
                catch
                    warning('EuroCDC data import failed! Loading cache...');
                    importedData = obj.loadCache();
                end
            end

            fprintf('Parsing data... ');
            data = cat(1, importedData.records{:});

            T = struct2table(data);
            T.dateRep = datetime(T.dateRep);
            T.day = str2double(T.day);
            T.month = str2double(T.month);
            T.year = str2double(T.year);
            T.cases = str2double(T.cases);
            T.deaths = str2double(T.deaths);
            T.popData2018 = str2double(T.popData2018);
            fprintf('Done!\n');
        end

        function cachedData = loadCache(obj)
            cachedData = loadjson([obj.DATA_DIR, 'european-countries.json']);
        end

        function saveRawData(obj, filePath)
            if nargin == 1
                filePath = [obj.DATA_DIR, 'european-countries.json'];
            end
            websave(filePath, obj.URL);
            fprintf('\tEuroCDC: Saved to %s\n', filePath);
        end
    end
end