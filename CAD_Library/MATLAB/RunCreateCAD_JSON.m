%% RunCreateCAD_JSON.m
% Simple script to generate all CAD JSON files
%
% Run this script to create JSON files for all CAD classes

% Output directory for JSON files
outputDir = fullfile(pwd, 'CAD_JSON_Output');

% Generate all JSON files
fprintf('Generating CAD JSON files...\n');
fprintf('Output directory: %s\n\n', outputDir);

CreateCAD_JSON(outputDir);

fprintf('\n\nDone! JSON files saved to: %s\n', outputDir);
