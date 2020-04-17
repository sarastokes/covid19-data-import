classdef CovidTrackingProject < DataSource
% COVIDTRACKINGPROJECT
%
% Constructor:
%   obj = CovidTrackingProject();
%
% Methods:
%   data = obj.getData(dataName);
% where dataName can be 'state', 'state-daily', 'usa', 'usa-daily'
%
% Source:
%   https://covidtracking.com/api
%
% History:
%   16Apr2020 - SSP
% ------------------------------------------------------------------------

    properties (SetAccess = private)
        stateData
        nationData
    end

    properties (Constant, Hidden)
        ET_TIME_HEADERS = {'checkTimeEt', 'lastUpdateEt'};
        NUMERIC_TIME_HEADERS = 'date';
        UTC_TIME_HEADERS = {'dateModified', 'dateChecked', 'lastModified'};
    end

    methods
        function obj = CovidTrackingProject()

            % obj@DataSource([]]);
            fprintf('\tImporting state data...\n');
            obj.stateData = obj.parseStatesDaily();
            fprintf('\tImporting national data...\n')
            obj.nationData = obj.parseAmericaDaily();
        end

        function data = getData(obj, dataName)
            switch dataName
                case 'states'
                    data = obj.parseStates();
                case 'usa'
                    data = obj.parseAmerica();
                case 'usa-daily'
                    data = obj.parseAmericaDaily();
                case 'states-daily'
                    data = obj.parseStatesDaily();
                otherwise
                    % Parse a single state??
                    % https://covidtracking.com/api/states/daily?state=NY
                    error('COVIDTRACKINGPROJECT/GETDATA: Unrecognized data name!');
            end
        end
    end

    methods (Access = private)
        function data = parseAmerica(obj)
            % PARSEUSA
            url = 'https://covidtracking.com/api/us';
            importedData = webread(url, obj.getWebOptions());
            data = importedData{1};
            % Different format from usa-daily and states ISO 8601 times...
            data.dateModified = datestr(datenum8601(data.dateModified));
        end

        function T = parseAmericaDaily(obj)
            url = 'https://covidtracking.com/api/us/daily';
            importedData = webread(url, obj.getWebOptions());
            T = struct2table(cat(1, importedData{:}));

            T = obj.fixImportedData(T);
        end

        function T = parseStates(obj)
            % Current data for each state, DC and territory
            url = 'https://covidtracking.com/api/states';
            importedData = webread(url, obj.getWebOptions());
            missingFields = setdiff(fieldnames(importedData{1}),... 
                fieldnames(importedData{end}));

            data = importedData;  
            for i = numel(data)-3:numel(data)
                for j = 1:numel(missingFields)
                    data{i}.(missingFields{j}) = NaN;
                end
            end
            T = struct2table(cat(1, data{:}));

            T = obj.fixImportedData(T);

            T.total = []; 
            T.notes = [];
        end

        function T = parseStatesDaily(obj)
            % Daily data for each state, DC and territory
            url = 'https://covidtracking.com/api/states/daily';
            importedData = webread(url, obj.getWebOptions());

            data = importedData;
            maxFieldNames = fieldnames(data{1});
            maxFields = numel(maxFieldNames);

            for i = 1:numel(data)
                if numel(fieldnames(data{i})) ~= maxFields
                    missingFields = setdiff(maxFieldNames, fieldnames(data{i}));
                    for j = 1:numel(missingFields)
                        data{i}.(missingFields{j}) = NaN;
                    end
                end
            end

            T = struct2table(cat(1, data{:}));
            T = obj.fixImportedData(T);
        end

        function T = fixImportedData(obj, T)
            params = T.Properties.VariableNames;

            for i = 1:numel(params)
                if ismember(params{i}, obj.ET_TIME_HEADERS)
                    T.(params{i}) = datetime(datestr(T.(params{i})));
                elseif ismember(params{i}, obj.NUMERIC_TIME_HEADERS)
                    %T.(params{i}) = datestr(datenum(num2str(T.(params{i})), 'yyyymmdd'));
                    T.(params{i}) = datetime(num2str(T.(params{i})),... 
                        'InputFormat', 'yyyyMMdd');
                elseif ismember(params{i}, obj.UTC_TIME_HEADERS)
                    try
                        T.(params{i}) = datetime(T.(params{i}),... 
                            'InputFormat', 'uuuu-MM-dd''T''HH:mm:ssXXX',... 
                            'TimeZone', 'UTC');
                    catch
                        T.(params{i}) = datetime(T.(params{i}),...
                            'InputFormat', 'uuuu-MM-dd''T''HH:mm.sssXXX',...
                            'TimeZone', 'UTC');
                        fprintf('Used alternative format for parameter %s\n', params{i});
                    end
                    %T.(params{i}) = arrayfun(@(x) datestr(datenum8601(x{1})),... 
                    %    T.(params{i}), 'UniformOutput', false);
                elseif obj.isSemifull(T.(params{i}))
                    T.(params{i}) = semifullcells2doubles(T.(params{i}));
                end
            end
        end
    end
end