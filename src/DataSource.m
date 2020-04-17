classdef (Abstract) DataSource < handle

    properties (SetAccess = private, GetAccess = protected)
        URL
    end

    properties (Hidden, Constant)
        DATA_DIR = [fileparts(fileparts(mfilename('fullpath'))), filesep, 'data', filesep];
    end

    methods 
        function obj = DataSource(url)
            obj.URL = url;
        end
    end

    methods (Static)
        function tf = isSemifull(col)
            % ISSEMIFULL  Whether column is semifull cell array
            if isa(col, 'cell') && nnz(cellfun(@isempty, col)) > 0
                tf = true;
            else
                tf = false;
            end
        end

        function opts = getWebOptions()
            % GETWEBOPTIONS  Preferences for webread
            opts = weboptions('Timeout', 120,...
                'ContentType', 'json',...
                'ContentReader', @loadjson);
        end
    end
end