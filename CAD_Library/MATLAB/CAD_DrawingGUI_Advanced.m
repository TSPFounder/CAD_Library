%% CAD_DrawingGUI_Advanced.m
% Advanced MATLAB GUI for managing CAD_Drawing objects
%
% Usage:
%   CAD_DrawingGUI_Advanced()              - Opens the GUI
%   drawings = CAD_DrawingGUI_Advanced()   - Opens GUI and returns drawing list
%
% Features:
%   - Create and manage multiple drawings
%   - Add sheets, views, dimensions
%   - Manage drawing elements and annotations
%   - Import/Export drawing collections

function varargout = CAD_DrawingGUI_Advanced()
    % Create the main figure
    fig = uifigure('Name', 'CAD Drawing Manager (Advanced)', ...
                   'Position', [50 50 1000 800], ...
                   'Resize', 'on');

    % Store data in figure's UserData
    data = struct();
    data.drawings = {};
    data.selectedIndex = 0;
    fig.UserData = data;

    % Create main grid layout
    mainGL = uigridlayout(fig, [1, 2]);
    mainGL.ColumnWidth = {'0.30x', '0.70x'};
    mainGL.Padding = [10 10 10 10];

    % Left panel - Drawing list
    leftPanel = uipanel(mainGL, 'Title', 'Drawings');
    leftGL = uigridlayout(leftPanel, [5, 1]);
    leftGL.RowHeight = {'1x', 35, 35, 35, 35};
    leftGL.Padding = [5 5 5 5];

    % Drawing listbox
    drawingListBox = uilistbox(leftGL, 'Items', {});

    % Quick-add buttons
    quickBtnPanel = uigridlayout(leftGL, [1, 3]);
    quickBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    quickBtnPanel.Padding = [0 0 0 0];

    newDrawingBtn = uibutton(quickBtnPanel, 'Text', 'New Drawing', ...
                             'BackgroundColor', [0.3 0.6 0.3]);
    duplicateBtn = uibutton(quickBtnPanel, 'Text', 'Duplicate', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    deleteBtn = uibutton(quickBtnPanel, 'Text', 'Delete', ...
                         'BackgroundColor', [0.7 0.3 0.3]);

    % Template buttons
    templatePanel = uigridlayout(leftGL, [1, 3]);
    templatePanel.ColumnWidth = {'1x', '1x', '1x'};
    templatePanel.Padding = [0 0 0 0];

    detailBtn = uibutton(templatePanel, 'Text', 'Detail Dwg', ...
                         'BackgroundColor', [0.6 0.8 0.6]);
    assemblyBtn = uibutton(templatePanel, 'Text', 'Assembly Dwg', ...
                           'BackgroundColor', [0.6 0.8 0.6]);
    schematicBtn = uibutton(templatePanel, 'Text', 'Schematic', ...
                            'BackgroundColor', [0.6 0.8 0.6]);

    % Import/Export
    ioBtnPanel = uigridlayout(leftGL, [1, 2]);
    ioBtnPanel.ColumnWidth = {'1x', '1x'};
    ioBtnPanel.Padding = [0 0 0 0];

    importBtn = uibutton(ioBtnPanel, 'Text', 'Import JSON', ...
                         'BackgroundColor', [0.4 0.6 0.8]);
    exportBtn = uibutton(ioBtnPanel, 'Text', 'Export All', ...
                         'BackgroundColor', [0.6 0.4 0.8]);

    % Print/PDF button
    printBtn = uibutton(leftGL, 'Text', 'Export to PDF (Placeholder)', ...
                        'BackgroundColor', [0.8 0.6 0.4]);

    % Right panel - Drawing editor with tabs
    rightPanel = uipanel(mainGL, 'Title', 'Drawing Editor');
    rightGL = uigridlayout(rightPanel, [2, 1]);
    rightGL.RowHeight = {35, '1x'};
    rightGL.Padding = [5 5 5 5];

    % Status/action bar
    actionPanel = uigridlayout(rightGL, [1, 4]);
    actionPanel.ColumnWidth = {'1x', '1x', '1x', '2x'};
    actionPanel.Padding = [0 0 0 0];

    updateBtn = uibutton(actionPanel, 'Text', 'Update Drawing', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    saveFileBtn = uibutton(actionPanel, 'Text', 'Save to File', ...
                           'BackgroundColor', [0.5 0.3 0.7]);
    copyJsonBtn = uibutton(actionPanel, 'Text', 'Copy JSON', ...
                           'BackgroundColor', [0.3 0.5 0.7]);
    statusLabel = uilabel(actionPanel, 'Text', 'Ready', ...
                          'FontColor', [0.2 0.2 0.8]);

    % Tab group
    tabGroup = uitabgroup(rightGL);

    % Tab 1: Basic Info
    basicTab = uitab(tabGroup, 'Title', 'Basic Info');
    basicGL = uigridlayout(basicTab, [10, 2]);
    basicGL.RowHeight = repmat({30}, 1, 10);
    basicGL.ColumnWidth = {'0.35x', '0.65x'};
    basicGL.Padding = [10 10 10 10];

    uilabel(basicGL, 'Text', 'Title:', 'HorizontalAlignment', 'right');
    titleEdit = uieditfield(basicGL, 'text', 'Value', '');

    uilabel(basicGL, 'Text', 'Drawing Number:', 'HorizontalAlignment', 'right');
    drawingNumEdit = uieditfield(basicGL, 'text', 'Value', '');

    uilabel(basicGL, 'Text', 'Revision:', 'HorizontalAlignment', 'right');
    revisionEdit = uieditfield(basicGL, 'text', 'Value', 'A');

    uilabel(basicGL, 'Text', 'Standard:', 'HorizontalAlignment', 'right');
    standardDropdown = uidropdown(basicGL, 'Items', {'ANSI'}, 'Value', 'ANSI');

    uilabel(basicGL, 'Text', 'Drawing Size:', 'HorizontalAlignment', 'right');
    sizeDropdown = uidropdown(basicGL, ...
        'Items', {'E', 'D', 'C', 'B', 'A', 'A1', 'A2', 'A3'}, 'Value', 'B');

    uilabel(basicGL, 'Text', 'Format:', 'HorizontalAlignment', 'right');
    formatDropdown = uidropdown(basicGL, ...
        'Items', {'CAD_File', 'DWG', 'PDF', 'PNG', 'JPG', 'Other'}, 'Value', 'CAD_File');

    % Summary labels
    uilabel(basicGL, 'Text', 'Sheets:', 'HorizontalAlignment', 'right');
    sheetsCountLabel = uilabel(basicGL, 'Text', '0 sheets');

    uilabel(basicGL, 'Text', 'Views:', 'HorizontalAlignment', 'right');
    viewsCountLabel = uilabel(basicGL, 'Text', '0 views');

    uilabel(basicGL, 'Text', 'Dimensions:', 'HorizontalAlignment', 'right');
    dimensionsCountLabel = uilabel(basicGL, 'Text', '0 dimensions');

    uilabel(basicGL, 'Text', 'Elements:', 'HorizontalAlignment', 'right');
    elementsCountLabel = uilabel(basicGL, 'Text', '0 elements');

    % Tab 2: Sheets
    sheetsTab = uitab(tabGroup, 'Title', 'Sheets');
    sheetsGL = uigridlayout(sheetsTab, [3, 1]);
    sheetsGL.RowHeight = {'1x', 35, 35};
    sheetsGL.Padding = [10 10 10 10];

    sheetListBox = uilistbox(sheetsGL, 'Items', {});

    sheetBtnPanel = uigridlayout(sheetsGL, [1, 4]);
    sheetBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    sheetBtnPanel.Padding = [0 0 0 0];

    addSheetBtn = uibutton(sheetBtnPanel, 'Text', 'Add Sheet', ...
                           'BackgroundColor', [0.3 0.6 0.3]);
    editSheetBtn = uibutton(sheetBtnPanel, 'Text', 'Edit', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    removeSheetBtn = uibutton(sheetBtnPanel, 'Text', 'Remove', ...
                              'BackgroundColor', [0.7 0.3 0.3]);
    orientationDropdown = uidropdown(sheetBtnPanel, ...
        'Items', {'Landscape', 'Portrait'}, 'Value', 'Landscape');

    sheetSummaryLabel = uilabel(sheetsGL, 'Text', 'Add sheets to organize drawing views', ...
                                'HorizontalAlignment', 'center');

    % Tab 3: Views
    viewsTab = uitab(tabGroup, 'Title', 'Views');
    viewsGL = uigridlayout(viewsTab, [3, 1]);
    viewsGL.RowHeight = {'1x', 35, 35};
    viewsGL.Padding = [10 10 10 10];

    viewListBox = uilistbox(viewsGL, 'Items', {});

    viewBtnPanel = uigridlayout(viewsGL, [1, 4]);
    viewBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    viewBtnPanel.Padding = [0 0 0 0];

    addViewBtn = uibutton(viewBtnPanel, 'Text', 'Add View', ...
                          'BackgroundColor', [0.3 0.6 0.3]);
    editViewBtn = uibutton(viewBtnPanel, 'Text', 'Edit', ...
                           'BackgroundColor', [0.5 0.5 0.7]);
    removeViewBtn = uibutton(viewBtnPanel, 'Text', 'Remove', ...
                             'BackgroundColor', [0.7 0.3 0.3]);
    viewTypeDropdown = uidropdown(viewBtnPanel, ...
        'Items', {'OrthoTop', 'OrthoFront', 'OrthoRightSide', 'OrthoBottom', ...
                  'OrthoBack', 'OrthoLeftSide', 'Isometric', 'CrossSection', ...
                  'Detail', 'Other'}, 'Value', 'OrthoFront');

    viewSummaryLabel = uilabel(viewsGL, 'Text', 'Add views to display model geometry', ...
                               'HorizontalAlignment', 'center');

    % Tab 4: Dimensions
    dimensionsTab = uitab(tabGroup, 'Title', 'Dimensions');
    dimensionsGL = uigridlayout(dimensionsTab, [3, 1]);
    dimensionsGL.RowHeight = {'1x', 35, 35};
    dimensionsGL.Padding = [10 10 10 10];

    dimensionListBox = uilistbox(dimensionsGL, 'Items', {});

    dimBtnPanel = uigridlayout(dimensionsGL, [1, 4]);
    dimBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    dimBtnPanel.Padding = [0 0 0 0];

    addDimBtn = uibutton(dimBtnPanel, 'Text', 'Add Dimension', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    editDimBtn = uibutton(dimBtnPanel, 'Text', 'Edit', ...
                          'BackgroundColor', [0.5 0.5 0.7]);
    removeDimBtn = uibutton(dimBtnPanel, 'Text', 'Remove', ...
                            'BackgroundColor', [0.7 0.3 0.3]);
    dimGuiBtn = uibutton(dimBtnPanel, 'Text', 'Open Dim GUI', ...
                         'BackgroundColor', [0.4 0.6 0.8]);

    dimSummaryLabel = uilabel(dimensionsGL, 'Text', 'Add dimensions to annotate views', ...
                              'HorizontalAlignment', 'center');

    % Tab 5: Elements (Tables, Notes, PMI)
    elementsTab = uitab(tabGroup, 'Title', 'Elements');
    elementsGL = uigridlayout(elementsTab, [3, 1]);
    elementsGL.RowHeight = {'1x', 35, 35};
    elementsGL.Padding = [10 10 10 10];

    elementListBox = uilistbox(elementsGL, 'Items', {});

    elemBtnPanel = uigridlayout(elementsGL, [1, 4]);
    elemBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    elemBtnPanel.Padding = [0 0 0 0];

    addElemBtn = uibutton(elemBtnPanel, 'Text', 'Add Element', ...
                          'BackgroundColor', [0.3 0.6 0.3]);
    editElemBtn = uibutton(elemBtnPanel, 'Text', 'Edit', ...
                           'BackgroundColor', [0.5 0.5 0.7]);
    removeElemBtn = uibutton(elemBtnPanel, 'Text', 'Remove', ...
                             'BackgroundColor', [0.7 0.3 0.3]);
    elemTypeDropdown = uidropdown(elemBtnPanel, ...
        'Items', {'DrawingView', 'Dimension', 'Table', 'BoM', 'PMI', ...
                  'ConstructionGeometry', 'Note', 'Other'}, 'Value', 'Note');

    elemSummaryLabel = uilabel(elementsGL, 'Text', 'Add tables, notes, and annotations', ...
                               'HorizontalAlignment', 'center');

    % Tab 6: JSON Preview
    jsonTab = uitab(tabGroup, 'Title', 'JSON');
    jsonGL = uigridlayout(jsonTab, [1, 1]);
    jsonGL.Padding = [10 10 10 10];

    jsonArea = uitextarea(jsonGL, 'Value', '', 'Editable', 'off', ...
                          'FontName', 'Consolas', 'FontSize', 9);

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.drawingListBox = drawingListBox;
    ui.titleEdit = titleEdit;
    ui.drawingNumEdit = drawingNumEdit;
    ui.revisionEdit = revisionEdit;
    ui.standardDropdown = standardDropdown;
    ui.sizeDropdown = sizeDropdown;
    ui.formatDropdown = formatDropdown;
    ui.sheetsCountLabel = sheetsCountLabel;
    ui.viewsCountLabel = viewsCountLabel;
    ui.dimensionsCountLabel = dimensionsCountLabel;
    ui.elementsCountLabel = elementsCountLabel;
    ui.sheetListBox = sheetListBox;
    ui.orientationDropdown = orientationDropdown;
    ui.sheetSummaryLabel = sheetSummaryLabel;
    ui.viewListBox = viewListBox;
    ui.viewTypeDropdown = viewTypeDropdown;
    ui.viewSummaryLabel = viewSummaryLabel;
    ui.dimensionListBox = dimensionListBox;
    ui.dimSummaryLabel = dimSummaryLabel;
    ui.elementListBox = elementListBox;
    ui.elemTypeDropdown = elemTypeDropdown;
    ui.elemSummaryLabel = elemSummaryLabel;
    ui.jsonArea = jsonArea;
    ui.statusLabel = statusLabel;

    % Set up callbacks
    drawingListBox.ValueChangedFcn = @(~,~) onDrawingSelected(ui);

    newDrawingBtn.ButtonPushedFcn = @(~,~) addNewDrawing(ui);
    duplicateBtn.ButtonPushedFcn = @(~,~) duplicateDrawing(ui);
    deleteBtn.ButtonPushedFcn = @(~,~) deleteDrawing(ui);

    detailBtn.ButtonPushedFcn = @(~,~) createTemplateDrawing(ui, 'Detail');
    assemblyBtn.ButtonPushedFcn = @(~,~) createTemplateDrawing(ui, 'Assembly');
    schematicBtn.ButtonPushedFcn = @(~,~) createTemplateDrawing(ui, 'Schematic');

    importBtn.ButtonPushedFcn = @(~,~) importDrawings(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportAllDrawings(ui);
    printBtn.ButtonPushedFcn = @(~,~) exportToPDF(ui);

    updateBtn.ButtonPushedFcn = @(~,~) updateCurrentDrawing(ui);
    saveFileBtn.ButtonPushedFcn = @(~,~) saveDrawingToFile(ui);
    copyJsonBtn.ButtonPushedFcn = @(~,~) copyDrawingJson(ui);

    addSheetBtn.ButtonPushedFcn = @(~,~) addSheet(ui);
    editSheetBtn.ButtonPushedFcn = @(~,~) editSheet(ui);
    removeSheetBtn.ButtonPushedFcn = @(~,~) removeSheet(ui);

    addViewBtn.ButtonPushedFcn = @(~,~) addView(ui);
    editViewBtn.ButtonPushedFcn = @(~,~) editView(ui);
    removeViewBtn.ButtonPushedFcn = @(~,~) removeView(ui);

    addDimBtn.ButtonPushedFcn = @(~,~) addDimension(ui);
    editDimBtn.ButtonPushedFcn = @(~,~) editDimension(ui);
    removeDimBtn.ButtonPushedFcn = @(~,~) removeDimension(ui);
    dimGuiBtn.ButtonPushedFcn = @(~,~) openDimensionGUI(ui);

    addElemBtn.ButtonPushedFcn = @(~,~) addElement(ui);
    editElemBtn.ButtonPushedFcn = @(~,~) editElement(ui);
    removeElemBtn.ButtonPushedFcn = @(~,~) removeElement(ui);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.drawings;
            close(fig);
        else
            varargout{1} = {};
        end
    end
end

%% Create default drawing struct
function drawing = createDefaultDrawing()
    drawing = struct();
    drawing.Title = '';
    drawing.DrawingNumber = '';
    drawing.Revision = 'A';
    drawing.DrawingStandard = 0; % ANSI
    drawing.MyDrawingSize = 3; % B size
    drawing.MyFormat = 0; % CAD_File
    drawing.MyDrawingSheets = {};
    drawing.DrawingElements = {};
    drawing.MyCAD_Sketches = {};
    drawing.MyViews = {};
    drawing.MyParts = {};
    drawing.MyParameters = {};
    drawing.MyDimensions = {};
    drawing.MyConstructionGeometry = {};
end

%% Add new drawing
function addNewDrawing(ui)
    drawings = ui.fig.UserData.drawings;

    drawing = createDefaultDrawing();
    drawing.Title = sprintf('Drawing_%d', length(drawings) + 1);
    drawing.DrawingNumber = sprintf('DWG-%03d', length(drawings) + 1);

    drawings{end+1} = drawing;
    ui.fig.UserData.drawings = drawings;
    ui.fig.UserData.selectedIndex = length(drawings);

    updateDrawingList(ui);
    loadDrawingToEditor(ui, drawing);

    ui.statusLabel.Text = 'New drawing added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Create template drawing
function createTemplateDrawing(ui, templateType)
    drawings = ui.fig.UserData.drawings;

    drawing = createDefaultDrawing();
    drawing.Title = sprintf('%s Drawing %d', templateType, length(drawings) + 1);
    drawing.DrawingNumber = sprintf('DWG-%s-%03d', upper(templateType(1:3)), length(drawings) + 1);

    switch templateType
        case 'Detail'
            drawing.MyDrawingSize = 3; % B size
            % Add a sheet
            sheet = struct();
            sheet.Name = 'Sheet 1';
            sheet.SheetNumber = 1;
            sheet.Orientation = 0; % Landscape
            drawing.MyDrawingSheets{1} = sheet;

            % Add standard views
            views = {'OrthoFront', 'OrthoTop', 'OrthoRightSide', 'Isometric'};
            viewEnums = [1, 0, 2, 6];
            for i = 1:4
                view = struct();
                view.Name = views{i};
                view.ViewType = viewEnums(i);
                view.Scale = 1.0;
                drawing.MyViews{i} = view;
            end

        case 'Assembly'
            drawing.MyDrawingSize = 1; % D size
            sheet = struct();
            sheet.Name = 'Sheet 1';
            sheet.SheetNumber = 1;
            sheet.Orientation = 0; % Landscape
            drawing.MyDrawingSheets{1} = sheet;

            % Add isometric and exploded views
            view1 = struct();
            view1.Name = 'Isometric';
            view1.ViewType = 6;
            view1.Scale = 0.5;
            drawing.MyViews{1} = view1;

            % Add BOM element
            elem = struct();
            elem.Name = 'Bill of Materials';
            elem.MyType = 3; % BoM
            drawing.DrawingElements{1} = elem;

        case 'Schematic'
            drawing.MyDrawingSize = 2; % C size
            drawing.MyFormat = 1; % DWG
            sheet = struct();
            sheet.Name = 'Schematic';
            sheet.SheetNumber = 1;
            sheet.Orientation = 0;
            drawing.MyDrawingSheets{1} = sheet;

            % Add note
            note = struct();
            note.Name = 'General Notes';
            note.MyType = 6; % Note
            drawing.DrawingElements{1} = note;
    end

    drawings{end+1} = drawing;
    ui.fig.UserData.drawings = drawings;
    ui.fig.UserData.selectedIndex = length(drawings);

    updateDrawingList(ui);
    loadDrawingToEditor(ui, drawing);

    ui.statusLabel.Text = sprintf('%s drawing created', templateType);
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Update drawing list display
function updateDrawingList(ui)
    drawings = ui.fig.UserData.drawings;
    items = cell(1, length(drawings));

    for i = 1:length(drawings)
        d = drawings{i};
        rev = '';
        if isfield(d, 'Revision') && ~isempty(d.Revision)
            rev = sprintf(' Rev.%s', d.Revision);
        end
        items{i} = sprintf('%d. %s%s', i, d.DrawingNumber, rev);
    end

    ui.drawingListBox.Items = items;

    idx = ui.fig.UserData.selectedIndex;
    if idx > 0 && idx <= length(items)
        ui.drawingListBox.Value = items{idx};
    end
end

%% On drawing selected
function onDrawingSelected(ui)
    if isempty(ui.drawingListBox.Value)
        return;
    end

    selStr = ui.drawingListBox.Value;
    dotPos = strfind(selStr, '.');
    if ~isempty(dotPos)
        idx = str2double(selStr(1:dotPos(1)-1));
        ui.fig.UserData.selectedIndex = idx;

        drawings = ui.fig.UserData.drawings;
        if idx > 0 && idx <= length(drawings)
            loadDrawingToEditor(ui, drawings{idx});
        end
    end
end

%% Load drawing to editor
function loadDrawingToEditor(ui, drawing)
    % Basic info
    ui.titleEdit.Value = drawing.Title;
    ui.drawingNumEdit.Value = drawing.DrawingNumber;
    ui.revisionEdit.Value = drawing.Revision;

    % Settings
    ui.sizeDropdown.Value = getDrawingSizeName(drawing.MyDrawingSize);
    ui.formatDropdown.Value = getFormatName(drawing.MyFormat);

    % Counts
    ui.sheetsCountLabel.Text = sprintf('%d sheets', length(drawing.MyDrawingSheets));
    ui.viewsCountLabel.Text = sprintf('%d views', length(drawing.MyViews));
    ui.dimensionsCountLabel.Text = sprintf('%d dimensions', length(drawing.MyDimensions));
    ui.elementsCountLabel.Text = sprintf('%d elements', length(drawing.DrawingElements));

    % Sheet list
    sheetItems = {};
    for i = 1:length(drawing.MyDrawingSheets)
        s = drawing.MyDrawingSheets{i};
        sheetItems{i} = sprintf('%d. %s', i, s.Name);
    end
    ui.sheetListBox.Items = sheetItems;

    % View list
    viewItems = {};
    for i = 1:length(drawing.MyViews)
        v = drawing.MyViews{i};
        vtype = getViewTypeName(v.ViewType);
        viewItems{i} = sprintf('%d. %s (%s)', i, v.Name, vtype);
    end
    ui.viewListBox.Items = viewItems;

    % Dimension list
    dimItems = {};
    for i = 1:length(drawing.MyDimensions)
        d = drawing.MyDimensions{i};
        if isfield(d, 'Name')
            dimItems{i} = sprintf('%d. %s', i, d.Name);
        else
            dimItems{i} = sprintf('%d. Dimension_%d', i, i);
        end
    end
    ui.dimensionListBox.Items = dimItems;

    % Element list
    elemItems = {};
    for i = 1:length(drawing.DrawingElements)
        e = drawing.DrawingElements{i};
        etype = getElementTypeName(e.MyType);
        elemItems{i} = sprintf('%d. %s (%s)', i, e.Name, etype);
    end
    ui.elementListBox.Items = elemItems;

    % JSON preview
    jsonStr = jsonencode(drawing, 'PrettyPrint', true);
    ui.jsonArea.Value = jsonStr;
end

%% Get drawing size name
function name = getDrawingSizeName(val)
    sizes = {'E', 'D', 'C', 'B', 'A', 'A1', 'A2', 'A3'};
    if val >= 0 && val < length(sizes)
        name = sizes{val + 1};
    else
        name = 'B';
    end
end

%% Get format name
function name = getFormatName(val)
    formats = {'CAD_File', 'DWG', 'PDF', 'PNG', 'JPG', 'Other'};
    if val >= 0 && val < length(formats)
        name = formats{val + 1};
    else
        name = 'CAD_File';
    end
end

%% Get view type name
function name = getViewTypeName(val)
    types = {'OrthoTop', 'OrthoFront', 'OrthoRightSide', 'OrthoBottom', ...
             'OrthoBack', 'OrthoLeftSide', 'Isometric', 'CrossSection', ...
             'Detail', 'Other'};
    if val >= 0 && val < length(types)
        name = types{val + 1};
    else
        name = 'Other';
    end
end

%% Get view type value
function val = getViewTypeValue(name)
    types = containers.Map(...
        {'OrthoTop', 'OrthoFront', 'OrthoRightSide', 'OrthoBottom', ...
         'OrthoBack', 'OrthoLeftSide', 'Isometric', 'CrossSection', ...
         'Detail', 'Other'}, ...
        {0, 1, 2, 3, 4, 5, 6, 7, 8, 9});
    val = types(name);
end

%% Get element type name
function name = getElementTypeName(val)
    types = {'DrawingView', 'Dimension', 'Table', 'BoM', 'PMI', ...
             'ConstructionGeometry', 'Note', 'Other'};
    if val >= 0 && val < length(types)
        name = types{val + 1};
    else
        name = 'Other';
    end
end

%% Get element type value
function val = getElementTypeValue(name)
    types = containers.Map(...
        {'DrawingView', 'Dimension', 'Table', 'BoM', 'PMI', ...
         'ConstructionGeometry', 'Note', 'Other'}, ...
        {0, 1, 2, 3, 4, 5, 6, 7});
    val = types(name);
end

%% Get size enum value
function val = getSizeValue(name)
    sizes = containers.Map(...
        {'E', 'D', 'C', 'B', 'A', 'A1', 'A2', 'A3'}, ...
        {0, 1, 2, 3, 4, 5, 6, 7});
    val = sizes(name);
end

%% Get format enum value
function val = getFormatValue(name)
    formats = containers.Map(...
        {'CAD_File', 'DWG', 'PDF', 'PNG', 'JPG', 'Other'}, ...
        {0, 1, 2, 3, 4, 5});
    val = formats(name);
end

%% Update current drawing
function updateCurrentDrawing(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'No drawing selected!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    try
        drawings = ui.fig.UserData.drawings;
        drawing = drawings{idx};

        drawing.Title = ui.titleEdit.Value;
        drawing.DrawingNumber = ui.drawingNumEdit.Value;
        drawing.Revision = ui.revisionEdit.Value;
        drawing.MyDrawingSize = getSizeValue(ui.sizeDropdown.Value);
        drawing.MyFormat = getFormatValue(ui.formatDropdown.Value);

        drawings{idx} = drawing;
        ui.fig.UserData.drawings = drawings;

        updateDrawingList(ui);

        jsonStr = jsonencode(drawing, 'PrettyPrint', true);
        ui.jsonArea.Value = jsonStr;

        ui.statusLabel.Text = 'Drawing updated!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Duplicate drawing
function duplicateDrawing(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a drawing first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    drawings = ui.fig.UserData.drawings;
    newDwg = drawings{idx};
    newDwg.DrawingNumber = [newDwg.DrawingNumber '-COPY'];

    drawings{end+1} = newDwg;
    ui.fig.UserData.drawings = drawings;
    ui.fig.UserData.selectedIndex = length(drawings);

    updateDrawingList(ui);
    loadDrawingToEditor(ui, newDwg);

    ui.statusLabel.Text = 'Drawing duplicated';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Delete drawing
function deleteDrawing(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a drawing first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    drawings = ui.fig.UserData.drawings;
    drawings(idx) = [];
    ui.fig.UserData.drawings = drawings;

    if idx > length(drawings)
        idx = length(drawings);
    end
    ui.fig.UserData.selectedIndex = idx;

    updateDrawingList(ui);

    if idx > 0
        loadDrawingToEditor(ui, drawings{idx});
    else
        clearEditor(ui);
    end

    ui.statusLabel.Text = 'Drawing deleted';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Clear editor
function clearEditor(ui)
    ui.titleEdit.Value = '';
    ui.drawingNumEdit.Value = '';
    ui.revisionEdit.Value = 'A';
    ui.sheetListBox.Items = {};
    ui.viewListBox.Items = {};
    ui.dimensionListBox.Items = {};
    ui.elementListBox.Items = {};
    ui.jsonArea.Value = '';
end

%% Add sheet
function addSheet(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a drawing first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    drawings = ui.fig.UserData.drawings;
    drawing = drawings{idx};

    sheet = struct();
    sheet.Name = sprintf('Sheet %d', length(drawing.MyDrawingSheets) + 1);
    sheet.SheetNumber = length(drawing.MyDrawingSheets) + 1;
    if strcmp(ui.orientationDropdown.Value, 'Landscape')
        sheet.Orientation = 0;
    else
        sheet.Orientation = 1;
    end

    drawing.MyDrawingSheets{end+1} = sheet;
    drawings{idx} = drawing;
    ui.fig.UserData.drawings = drawings;

    loadDrawingToEditor(ui, drawing);

    ui.statusLabel.Text = 'Sheet added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit sheet (placeholder)
function editSheet(ui)
    ui.statusLabel.Text = 'Select orientation before adding new sheet';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove sheet
function removeSheet(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    sheetSel = ui.sheetListBox.Value;
    if isempty(sheetSel)
        ui.statusLabel.Text = 'Select a sheet first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(sheetSel, '.');
    if isempty(dotPos), return; end
    sheetIdx = str2double(sheetSel(1:dotPos(1)-1));

    drawings = ui.fig.UserData.drawings;
    drawing = drawings{idx};
    drawing.MyDrawingSheets(sheetIdx) = [];
    drawings{idx} = drawing;
    ui.fig.UserData.drawings = drawings;

    loadDrawingToEditor(ui, drawing);

    ui.statusLabel.Text = 'Sheet removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Add view
function addView(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a drawing first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    drawings = ui.fig.UserData.drawings;
    drawing = drawings{idx};

    view = struct();
    view.Name = ui.viewTypeDropdown.Value;
    view.ViewType = getViewTypeValue(ui.viewTypeDropdown.Value);
    view.Scale = 1.0;

    drawing.MyViews{end+1} = view;
    drawings{idx} = drawing;
    ui.fig.UserData.drawings = drawings;

    loadDrawingToEditor(ui, drawing);

    ui.statusLabel.Text = 'View added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit view (placeholder)
function editView(ui)
    ui.statusLabel.Text = 'Select view type before adding';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove view
function removeView(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    viewSel = ui.viewListBox.Value;
    if isempty(viewSel)
        ui.statusLabel.Text = 'Select a view first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(viewSel, '.');
    if isempty(dotPos), return; end
    viewIdx = str2double(viewSel(1:dotPos(1)-1));

    drawings = ui.fig.UserData.drawings;
    drawing = drawings{idx};
    drawing.MyViews(viewIdx) = [];
    drawings{idx} = drawing;
    ui.fig.UserData.drawings = drawings;

    loadDrawingToEditor(ui, drawing);

    ui.statusLabel.Text = 'View removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Add dimension
function addDimension(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a drawing first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    drawings = ui.fig.UserData.drawings;
    drawing = drawings{idx};

    dim = struct();
    dim.DimensionID = sprintf('DIM_%d', length(drawing.MyDimensions) + 1);
    dim.Name = sprintf('Dimension_%d', length(drawing.MyDimensions) + 1);
    dim.DimensionNominalValue = 0;
    dim.MyDimensionType = 0; % Length

    drawing.MyDimensions{end+1} = dim;
    drawings{idx} = drawing;
    ui.fig.UserData.drawings = drawings;

    loadDrawingToEditor(ui, drawing);

    ui.statusLabel.Text = 'Dimension added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit dimension (placeholder)
function editDimension(ui)
    ui.statusLabel.Text = 'Use Dimension GUI for detailed editing';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove dimension
function removeDimension(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    dimSel = ui.dimensionListBox.Value;
    if isempty(dimSel)
        ui.statusLabel.Text = 'Select a dimension first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(dimSel, '.');
    if isempty(dotPos), return; end
    dimIdx = str2double(dimSel(1:dotPos(1)-1));

    drawings = ui.fig.UserData.drawings;
    drawing = drawings{idx};
    drawing.MyDimensions(dimIdx) = [];
    drawings{idx} = drawing;
    ui.fig.UserData.drawings = drawings;

    loadDrawingToEditor(ui, drawing);

    ui.statusLabel.Text = 'Dimension removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Open Dimension GUI
function openDimensionGUI(ui)
    try
        CAD_DimensionGUI_Advanced();
        ui.statusLabel.Text = 'Dimension GUI opened';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];
    catch
        ui.statusLabel.Text = 'Could not open Dimension GUI';
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Add element
function addElement(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a drawing first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    drawings = ui.fig.UserData.drawings;
    drawing = drawings{idx};

    elem = struct();
    elemType = ui.elemTypeDropdown.Value;
    elem.Name = sprintf('%s_%d', elemType, length(drawing.DrawingElements) + 1);
    elem.MyType = getElementTypeValue(elemType);

    drawing.DrawingElements{end+1} = elem;
    drawings{idx} = drawing;
    ui.fig.UserData.drawings = drawings;

    loadDrawingToEditor(ui, drawing);

    ui.statusLabel.Text = 'Element added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit element (placeholder)
function editElement(ui)
    ui.statusLabel.Text = 'Select element type before adding';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove element
function removeElement(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    elemSel = ui.elementListBox.Value;
    if isempty(elemSel)
        ui.statusLabel.Text = 'Select an element first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(elemSel, '.');
    if isempty(dotPos), return; end
    elemIdx = str2double(elemSel(1:dotPos(1)-1));

    drawings = ui.fig.UserData.drawings;
    drawing = drawings{idx};
    drawing.DrawingElements(elemIdx) = [];
    drawings{idx} = drawing;
    ui.fig.UserData.drawings = drawings;

    loadDrawingToEditor(ui, drawing);

    ui.statusLabel.Text = 'Element removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Import drawings
function importDrawings(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files'}, 'Import Drawings');
    if filename == 0, return; end

    try
        jsonStr = fileread(fullfile(pathname, filename));
        imported = jsondecode(jsonStr);

        if isfield(imported, 'Drawings')
            for i = 1:length(imported.Drawings)
                drawings = ui.fig.UserData.drawings;
                drawings{end+1} = imported.Drawings(i);
                ui.fig.UserData.drawings = drawings;
            end
        else
            drawings = ui.fig.UserData.drawings;
            drawings{end+1} = imported;
            ui.fig.UserData.drawings = drawings;
        end

        updateDrawingList(ui);
        ui.statusLabel.Text = 'Drawings imported!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Import error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Export all drawings
function exportAllDrawings(ui)
    drawings = ui.fig.UserData.drawings;
    if isempty(drawings)
        ui.statusLabel.Text = 'No drawings to export!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Export All Drawings', 'CAD_Drawings.json');
    if filename == 0, return; end

    try
        collection = struct();
        collection.ExportDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        collection.DrawingCount = length(drawings);
        collection.Drawings = drawings;

        jsonStr = jsonencode(collection, 'PrettyPrint', true);
        fid = fopen(fullfile(pathname, filename), 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = sprintf('Exported %d drawings!', length(drawings));
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Export error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Save drawing to file
function saveDrawingToFile(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a drawing first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    drawings = ui.fig.UserData.drawings;
    drawing = drawings{idx};

    defaultName = [drawing.DrawingNumber '.json'];

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Save Drawing', defaultName);
    if filename == 0, return; end

    try
        jsonStr = jsonencode(drawing, 'PrettyPrint', true);
        fid = fopen(fullfile(pathname, filename), 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = ['Saved: ' filename];
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Save error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Copy drawing JSON
function copyDrawingJson(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a drawing first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    drawings = ui.fig.UserData.drawings;
    drawing = drawings{idx};

    jsonStr = jsonencode(drawing, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Export to PDF (placeholder)
function exportToPDF(ui)
    ui.statusLabel.Text = 'PDF export requires CAD application integration';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end
