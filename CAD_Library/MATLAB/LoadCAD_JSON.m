%% LoadCAD_JSON.m
% Loads a CAD class JSON file back into a MATLAB struct
%
% Usage:
%   obj = LoadCAD_JSON(filePath)
%   obj = LoadCAD_JSON(className, jsonDir)
%
% Examples:
%   part = LoadCAD_JSON('C:\JSON\CAD_Part.json')
%   part = LoadCAD_JSON('CAD_Part', 'C:\JSON')

function obj = LoadCAD_JSON(filePathOrClassName, jsonDir)
    if nargin == 1
        % Single argument - full file path
        filePath = filePathOrClassName;
    else
        % Two arguments - class name and directory
        filePath = fullfile(jsonDir, [filePathOrClassName '.json']);
    end

    if ~exist(filePath, 'file')
        error('JSON file not found: %s', filePath);
    end

    % Read JSON file
    fid = fopen(filePath, 'r');
    jsonStr = fread(fid, '*char')';
    fclose(fid);

    % Decode JSON to struct
    obj = jsondecode(jsonStr);

    fprintf('Loaded: %s\n', filePath);
end
