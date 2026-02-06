%% CAD_DrawingGUI.m
% MATLAB GUI for creating and editing CAD_Drawing objects
%
% Usage:
%   CAD_DrawingGUI()              - Opens the GUI
%   drawing = CAD_DrawingGUI()    - Opens GUI and returns created drawing
%
% The GUI allows you to:
%   - Enter all CAD_Drawing properties
%   - Create the drawing object
%   - Export to JSON
%   - Save JSON to file

function varargout = CAD_DrawingGUI()
    % Create the main figure
    fig = uifigure('Name', 'CAD Drawing Creator', ...
                   'Position', [100 100 550 700], ...
                   'Resize', 'off');

    % Store data in figure's UserData
    data = struct();
    data.drawing = [];
    fig.UserData = data;

    % Create grid layout
    gl = uigridlayout(fig, [19, 2]);
    gl.RowHeight = [35, repmat({28}, 1, 15), 10, 100, 35];
    gl.ColumnWidth = {'0.4x', '1x'};
    gl.Padding = [10 10 10 10];
    gl.RowSpacing = 4;

    % Row 1: Title
    titleLabel = uilabel(gl, 'Text', 'CAD Drawing Creator', ...
                         'FontSize', 16, 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center');
    titleLabel.Layout.Row = 1;
    titleLabel.Layout.Column = [1 2];

    % Row 2: Title
    uilabel(gl, 'Text', 'Title:', 'HorizontalAlignment', 'right');
    titleEdit = uieditfield(gl, 'text', 'Value', '', ...
                            'Placeholder', 'Drawing title');

    % Row 3: Drawing Number
    uilabel(gl, 'Text', 'Drawing Number:', 'HorizontalAlignment', 'right');
    drawingNumEdit = uieditfield(gl, 'text', 'Value', '', ...
                                 'Placeholder', 'e.g., DWG-001');

    % Row 4: Revision
    uilabel(gl, 'Text', 'Revision:', 'HorizontalAlignment', 'right');
    revisionEdit = uieditfield(gl, 'text', 'Value', 'A', ...
                               'Placeholder', 'e.g., A, B, C');

    % Row 5: Settings header
    settingsHeader = uilabel(gl, 'Text', '── Drawing Settings ──', ...
                             'HorizontalAlignment', 'center', ...
                             'FontWeight', 'bold', ...
                             'FontColor', [0.3 0.3 0.6]);
    settingsHeader.Layout.Column = [1 2];

    % Row 6: Drawing Standard
    uilabel(gl, 'Text', 'Standard:', 'HorizontalAlignment', 'right');
    standardDropdown = uidropdown(gl, ...
                                  'Items', {'ANSI'}, ...
                                  'Value', 'ANSI');

    % Row 7: Drawing Size
    uilabel(gl, 'Text', 'Drawing Size:', 'HorizontalAlignment', 'right');
    sizeDropdown = uidropdown(gl, ...
                              'Items', {'E', 'D', 'C', 'B', 'A', 'A1', 'A2', 'A3'}, ...
                              'Value', 'B');

    % Row 8: Format
    uilabel(gl, 'Text', 'Format:', 'HorizontalAlignment', 'right');
    formatDropdown = uidropdown(gl, ...
                                'Items', {'CAD_File', 'DWG', 'PDF', 'PNG', 'JPG', 'Other'}, ...
                                'Value', 'CAD_File');

    % Row 9: Content header
    contentHeader = uilabel(gl, 'Text', '── Drawing Contents ──', ...
                            'HorizontalAlignment', 'center', ...
                            'FontWeight', 'bold', ...
                            'FontColor', [0.3 0.3 0.6]);
    contentHeader.Layout.Column = [1 2];

    % Row 10: Sheets count
    uilabel(gl, 'Text', 'Sheets:', 'HorizontalAlignment', 'right');
    sheetsLabel = uilabel(gl, 'Text', '0 sheets', ...
                          'FontColor', [0.4 0.4 0.4]);

    % Row 11: Views count
    uilabel(gl, 'Text', 'Views:', 'HorizontalAlignment', 'right');
    viewsLabel = uilabel(gl, 'Text', '0 views', ...
                         'FontColor', [0.4 0.4 0.4]);

    % Row 12: Dimensions count
    uilabel(gl, 'Text', 'Dimensions:', 'HorizontalAlignment', 'right');
    dimensionsLabel = uilabel(gl, 'Text', '0 dimensions', ...
                              'FontColor', [0.4 0.4 0.4]);

    % Row 13: Parameters count
    uilabel(gl, 'Text', 'Parameters:', 'HorizontalAlignment', 'right');
    parametersLabel = uilabel(gl, 'Text', '0 parameters', ...
                              'FontColor', [0.4 0.4 0.4]);

    % Row 14: Elements count
    uilabel(gl, 'Text', 'Elements:', 'HorizontalAlignment', 'right');
    elementsLabel = uilabel(gl, 'Text', '0 elements', ...
                            'FontColor', [0.4 0.4 0.4]);

    % Row 15: Parts count
    uilabel(gl, 'Text', 'Parts:', 'HorizontalAlignment', 'right');
    partsLabel = uilabel(gl, 'Text', '0 parts', ...
                         'FontColor', [0.4 0.4 0.4]);

    % Row 16: Buttons
    buttonPanel = uigridlayout(gl, [1, 4]);
    buttonPanel.Layout.Row = 16;
    buttonPanel.Layout.Column = [1 2];
    buttonPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    buttonPanel.Padding = [0 0 0 0];

    createBtn = uibutton(buttonPanel, 'Text', 'Create', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    clearBtn = uibutton(buttonPanel, 'Text', 'Clear', ...
                        'BackgroundColor', [0.8 0.8 0.2]);
    exportBtn = uibutton(buttonPanel, 'Text', 'Copy JSON', ...
                         'BackgroundColor', [0.3 0.5 0.7]);
    saveBtn = uibutton(buttonPanel, 'Text', 'Save File', ...
                       'BackgroundColor', [0.5 0.3 0.7]);

    % Row 17: Status label
    statusLabel = uilabel(gl, 'Text', 'Ready', ...
                          'HorizontalAlignment', 'center', ...
                          'FontColor', [0.2 0.2 0.8]);
    statusLabel.Layout.Column = [1 2];

    % Row 18: JSON Preview Area
    jsonArea = uitextarea(gl, 'Value', '', ...
                          'Editable', 'off', ...
                          'FontName', 'Consolas', ...
                          'FontSize', 9);
    jsonArea.Layout.Row = 18;
    jsonArea.Layout.Column = [1 2];

    % Row 19: Close button
    closeBtn = uibutton(gl, 'Text', 'Close', ...
                        'BackgroundColor', [0.7 0.3 0.3]);
    closeBtn.Layout.Row = 19;
    closeBtn.Layout.Column = [1 2];

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.titleEdit = titleEdit;
    ui.drawingNumEdit = drawingNumEdit;
    ui.revisionEdit = revisionEdit;
    ui.standardDropdown = standardDropdown;
    ui.sizeDropdown = sizeDropdown;
    ui.formatDropdown = formatDropdown;
    ui.sheetsLabel = sheetsLabel;
    ui.viewsLabel = viewsLabel;
    ui.dimensionsLabel = dimensionsLabel;
    ui.parametersLabel = parametersLabel;
    ui.elementsLabel = elementsLabel;
    ui.partsLabel = partsLabel;
    ui.statusLabel = statusLabel;
    ui.jsonArea = jsonArea;

    % Set up callbacks
    createBtn.ButtonPushedFcn = @(~,~) createDrawing(ui);
    clearBtn.ButtonPushedFcn = @(~,~) clearForm(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportJSON(ui);
    saveBtn.ButtonPushedFcn = @(~,~) saveToFile(ui);
    closeBtn.ButtonPushedFcn = @(~,~) close(fig);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.drawing;
            close(fig);
        else
            varargout{1} = [];
        end
    end
end

%% Create Drawing callback
function createDrawing(ui)
    try
        % Build the drawing struct
        drawing = struct();

        % Identification
        drawing.Title = ui.titleEdit.Value;
        drawing.DrawingNumber = ui.drawingNumEdit.Value;
        drawing.Revision = ui.revisionEdit.Value;

        % Settings - map to enum values
        standardMap = containers.Map({'ANSI'}, {0});
        drawing.DrawingStandard = standardMap(ui.standardDropdown.Value);

        sizeMap = containers.Map(...
            {'E', 'D', 'C', 'B', 'A', 'A1', 'A2', 'A3'}, ...
            {0, 1, 2, 3, 4, 5, 6, 7});
        drawing.MyDrawingSize = sizeMap(ui.sizeDropdown.Value);

        formatMap = containers.Map(...
            {'CAD_File', 'DWG', 'PDF', 'PNG', 'JPG', 'Other'}, ...
            {0, 1, 2, 3, 4, 5});
        drawing.MyFormat = formatMap(ui.formatDropdown.Value);

        % Initialize empty collections
        drawing.MyDrawingSheets = {};
        drawing.DrawingElements = {};
        drawing.MyCAD_Sketches = {};
        drawing.MyViews = {};
        drawing.MyParts = {};
        drawing.MyParameters = {};
        drawing.MyDimensions = {};
        drawing.MyConstructionGeometry = {};

        % Store in figure UserData
        ui.fig.UserData.drawing = drawing;

        % Generate JSON preview
        jsonStr = jsonencode(drawing, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        % Update status
        ui.statusLabel.Text = 'Drawing created successfully!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Clear Form callback
function clearForm(ui)
    ui.titleEdit.Value = '';
    ui.drawingNumEdit.Value = '';
    ui.revisionEdit.Value = 'A';
    ui.standardDropdown.Value = 'ANSI';
    ui.sizeDropdown.Value = 'B';
    ui.formatDropdown.Value = 'CAD_File';
    ui.sheetsLabel.Text = '0 sheets';
    ui.viewsLabel.Text = '0 views';
    ui.dimensionsLabel.Text = '0 dimensions';
    ui.parametersLabel.Text = '0 parameters';
    ui.elementsLabel.Text = '0 elements';
    ui.partsLabel.Text = '0 parts';
    ui.jsonArea.Value = '';
    ui.statusLabel.Text = 'Form cleared';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
    ui.fig.UserData.drawing = [];
end

%% Export JSON callback
function exportJSON(ui)
    drawing = ui.fig.UserData.drawing;
    if isempty(drawing)
        ui.statusLabel.Text = 'No drawing created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Copy JSON to clipboard
    jsonStr = jsonencode(drawing, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Save to File callback
function saveToFile(ui)
    drawing = ui.fig.UserData.drawing;
    if isempty(drawing)
        ui.statusLabel.Text = 'No drawing created yet!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Prompt for file location
    defaultName = 'CAD_Drawing.json';
    if isfield(drawing, 'DrawingNumber') && ~isempty(drawing.DrawingNumber)
        defaultName = [drawing.DrawingNumber '.json'];
    elseif isfield(drawing, 'Title') && ~isempty(drawing.Title)
        defaultName = [drawing.Title '.json'];
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files (*.json)'}, ...
                                      'Save Drawing JSON', defaultName);

    if filename == 0
        return;
    end

    % Write JSON to file
    filePath = fullfile(pathname, filename);
    jsonStr = jsonencode(drawing, 'PrettyPrint', true);

    fid = fopen(filePath, 'w');
    if fid == -1
        ui.statusLabel.Text = 'Error: Could not write file!';
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
        return;
    end

    fprintf(fid, '%s', jsonStr);
    fclose(fid);

    ui.statusLabel.Text = ['Saved to: ' filename];
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end
