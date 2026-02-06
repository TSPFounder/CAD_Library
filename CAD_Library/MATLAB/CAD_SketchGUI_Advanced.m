%% CAD_SketchGUI_Advanced.m
% Advanced MATLAB GUI for managing CAD_Sketch objects
%
% Usage:
%   CAD_SketchGUI_Advanced()              - Opens the GUI
%   sketches = CAD_SketchGUI_Advanced()   - Opens GUI and returns sketch list
%
% Features:
%   - Create and manage multiple sketches
%   - Add points, segments, dimensions, constraints
%   - Interactive geometry creation
%   - Import/Export sketch collections

function varargout = CAD_SketchGUI_Advanced()
    % Create the main figure
    fig = uifigure('Name', 'CAD Sketch Manager (Advanced)', ...
                   'Position', [50 50 1050 800], ...
                   'Resize', 'on');

    % Store data in figure's UserData
    data = struct();
    data.sketches = {};
    data.selectedIndex = 0;
    fig.UserData = data;

    % Create main grid layout
    mainGL = uigridlayout(fig, [1, 2]);
    mainGL.ColumnWidth = {'0.28x', '0.72x'};
    mainGL.Padding = [10 10 10 10];

    % Left panel - Sketch list
    leftPanel = uipanel(mainGL, 'Title', 'Sketches');
    leftGL = uigridlayout(leftPanel, [5, 1]);
    leftGL.RowHeight = {'1x', 35, 35, 35, 35};
    leftGL.Padding = [5 5 5 5];

    % Sketch listbox
    sketchListBox = uilistbox(leftGL, 'Items', {});

    % Management buttons
    mgmtBtnPanel = uigridlayout(leftGL, [1, 3]);
    mgmtBtnPanel.ColumnWidth = {'1x', '1x', '1x'};
    mgmtBtnPanel.Padding = [0 0 0 0];

    newBtn = uibutton(mgmtBtnPanel, 'Text', 'New Sketch', ...
                      'BackgroundColor', [0.3 0.6 0.3]);
    duplicateBtn = uibutton(mgmtBtnPanel, 'Text', 'Duplicate', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    deleteBtn = uibutton(mgmtBtnPanel, 'Text', 'Delete', ...
                         'BackgroundColor', [0.7 0.3 0.3]);

    % Template buttons
    templatePanel = uigridlayout(leftGL, [1, 3]);
    templatePanel.ColumnWidth = {'1x', '1x', '1x'};
    templatePanel.Padding = [0 0 0 0];

    rectBtn = uibutton(templatePanel, 'Text', 'Rectangle', ...
                       'BackgroundColor', [0.6 0.8 0.6]);
    circleBtn = uibutton(templatePanel, 'Text', 'Circle', ...
                         'BackgroundColor', [0.6 0.8 0.6]);
    polygonBtn = uibutton(templatePanel, 'Text', 'Polygon', ...
                          'BackgroundColor', [0.6 0.8 0.6]);

    % Import/Export
    ioBtnPanel = uigridlayout(leftGL, [1, 2]);
    ioBtnPanel.ColumnWidth = {'1x', '1x'};
    ioBtnPanel.Padding = [0 0 0 0];

    importBtn = uibutton(ioBtnPanel, 'Text', 'Import JSON', ...
                         'BackgroundColor', [0.4 0.6 0.8]);
    exportBtn = uibutton(ioBtnPanel, 'Text', 'Export All', ...
                         'BackgroundColor', [0.6 0.4 0.8]);

    % Validate button
    validateBtn = uibutton(leftGL, 'Text', 'Validate All Sketches', ...
                           'BackgroundColor', [0.8 0.6 0.4]);

    % Right panel - Sketch editor with tabs
    rightPanel = uipanel(mainGL, 'Title', 'Sketch Editor');
    rightGL = uigridlayout(rightPanel, [2, 1]);
    rightGL.RowHeight = {35, '1x'};
    rightGL.Padding = [5 5 5 5];

    % Status/action bar
    actionPanel = uigridlayout(rightGL, [1, 5]);
    actionPanel.ColumnWidth = {'1x', '1x', '1x', '1x', '2x'};
    actionPanel.Padding = [0 0 0 0];

    updateBtn = uibutton(actionPanel, 'Text', 'Update', ...
                         'BackgroundColor', [0.3 0.6 0.3]);
    saveFileBtn = uibutton(actionPanel, 'Text', 'Save File', ...
                           'BackgroundColor', [0.5 0.3 0.7]);
    copyJsonBtn = uibutton(actionPanel, 'Text', 'Copy JSON', ...
                           'BackgroundColor', [0.3 0.5 0.7]);
    clearSketchBtn = uibutton(actionPanel, 'Text', 'Clear Geom', ...
                              'BackgroundColor', [0.8 0.5 0.2]);
    statusLabel = uilabel(actionPanel, 'Text', 'Ready', ...
                          'FontColor', [0.2 0.2 0.8]);

    % Tab group
    tabGroup = uitabgroup(rightGL);

    % Tab 1: Basic Info
    basicTab = uitab(tabGroup, 'Title', 'Basic Info');
    basicGL = uigridlayout(basicTab, [8, 2]);
    basicGL.RowHeight = repmat({30}, 1, 8);
    basicGL.ColumnWidth = {'0.35x', '0.65x'};
    basicGL.Padding = [10 10 10 10];

    uilabel(basicGL, 'Text', 'Sketch ID:', 'HorizontalAlignment', 'right');
    sketchIdEdit = uieditfield(basicGL, 'text', 'Value', '');

    uilabel(basicGL, 'Text', 'Version:', 'HorizontalAlignment', 'right');
    versionEdit = uieditfield(basicGL, 'text', 'Value', '1.0');

    uilabel(basicGL, 'Text', 'Is 2D:', 'HorizontalAlignment', 'right');
    is2DCheck = uicheckbox(basicGL, 'Text', '', 'Value', true);

    uilabel(basicGL, 'Text', 'Area:', 'HorizontalAlignment', 'right');
    areaPanel = uigridlayout(basicGL, [1, 2]);
    areaPanel.ColumnWidth = {'1x', 60};
    areaPanel.Padding = [0 0 0 0];
    areaEdit = uieditfield(areaPanel, 'numeric', 'Value', 0);
    uilabel(areaPanel, 'Text', 'mm^2');

    uilabel(basicGL, 'Text', 'Perimeter:', 'HorizontalAlignment', 'right');
    perimeterPanel = uigridlayout(basicGL, [1, 2]);
    perimeterPanel.ColumnWidth = {'1x', 60};
    perimeterPanel.Padding = [0 0 0 0];
    perimeterEdit = uieditfield(perimeterPanel, 'numeric', 'Value', 0);
    uilabel(perimeterPanel, 'Text', 'mm');

    uilabel(basicGL, 'Text', 'Closed Loop:', 'HorizontalAlignment', 'right');
    closedLoopLabel = uilabel(basicGL, 'Text', 'Unknown');

    uilabel(basicGL, 'Text', 'Contiguous:', 'HorizontalAlignment', 'right');
    contiguousLabel = uilabel(basicGL, 'Text', 'Unknown');

    % Summary row
    summaryLabel = uilabel(basicGL, 'Text', 'Points: 0 | Segments: 0 | Dims: 0 | Constraints: 0', ...
                           'HorizontalAlignment', 'center');
    summaryLabel.Layout.Column = [1 2];

    % Tab 2: Points
    pointsTab = uitab(tabGroup, 'Title', 'Points');
    pointsGL = uigridlayout(pointsTab, [3, 1]);
    pointsGL.RowHeight = {'1x', 35, 35};
    pointsGL.Padding = [10 10 10 10];

    pointListBox = uilistbox(pointsGL, 'Items', {});

    pointBtnPanel = uigridlayout(pointsGL, [1, 4]);
    pointBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    pointBtnPanel.Padding = [0 0 0 0];

    addPointBtn = uibutton(pointBtnPanel, 'Text', 'Add Point', ...
                           'BackgroundColor', [0.3 0.6 0.3]);
    editPointBtn = uibutton(pointBtnPanel, 'Text', 'Edit', ...
                            'BackgroundColor', [0.5 0.5 0.7]);
    removePointBtn = uibutton(pointBtnPanel, 'Text', 'Remove', ...
                              'BackgroundColor', [0.7 0.3 0.3]);
    clearPointsBtn = uibutton(pointBtnPanel, 'Text', 'Clear All', ...
                              'BackgroundColor', [0.8 0.5 0.2]);

    pointInputPanel = uigridlayout(pointsGL, [1, 4]);
    pointInputPanel.ColumnWidth = {'1x', '1x', '1x', 80};
    pointInputPanel.Padding = [0 0 0 0];

    pointXEdit = uieditfield(pointInputPanel, 'numeric', 'Value', 0, 'Tooltip', 'X');
    pointYEdit = uieditfield(pointInputPanel, 'numeric', 'Value', 0, 'Tooltip', 'Y');
    pointZEdit = uieditfield(pointInputPanel, 'numeric', 'Value', 0, 'Tooltip', 'Z');
    uilabel(pointInputPanel, 'Text', 'X, Y, Z');

    % Tab 3: Segments
    segmentsTab = uitab(tabGroup, 'Title', 'Segments');
    segmentsGL = uigridlayout(segmentsTab, [3, 1]);
    segmentsGL.RowHeight = {'1x', 35, 35};
    segmentsGL.Padding = [10 10 10 10];

    segmentListBox = uilistbox(segmentsGL, 'Items', {});

    segBtnPanel = uigridlayout(segmentsGL, [1, 4]);
    segBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    segBtnPanel.Padding = [0 0 0 0];

    addSegmentBtn = uibutton(segBtnPanel, 'Text', 'Add Segment', ...
                             'BackgroundColor', [0.3 0.6 0.3]);
    editSegmentBtn = uibutton(segBtnPanel, 'Text', 'Edit', ...
                              'BackgroundColor', [0.5 0.5 0.7]);
    removeSegmentBtn = uibutton(segBtnPanel, 'Text', 'Remove', ...
                                'BackgroundColor', [0.7 0.3 0.3]);
    clearSegmentsBtn = uibutton(segBtnPanel, 'Text', 'Clear All', ...
                                'BackgroundColor', [0.8 0.5 0.2]);

    segmentInfoLabel = uilabel(segmentsGL, 'Text', 'Click Add to create segment from last two points', ...
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

    dimInfoLabel = uilabel(dimensionsGL, 'Text', 'Add dimensions to constrain sketch geometry', ...
                           'HorizontalAlignment', 'center');

    % Tab 5: Constraints
    constraintsTab = uitab(tabGroup, 'Title', 'Constraints');
    constraintsGL = uigridlayout(constraintsTab, [3, 1]);
    constraintsGL.RowHeight = {'1x', 35, 35};
    constraintsGL.Padding = [10 10 10 10];

    constraintListBox = uilistbox(constraintsGL, 'Items', {});

    constrBtnPanel = uigridlayout(constraintsGL, [1, 4]);
    constrBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    constrBtnPanel.Padding = [0 0 0 0];

    addConstraintBtn = uibutton(constrBtnPanel, 'Text', 'Add Constraint', ...
                                'BackgroundColor', [0.3 0.6 0.3]);
    editConstraintBtn = uibutton(constrBtnPanel, 'Text', 'Edit', ...
                                 'BackgroundColor', [0.5 0.5 0.7]);
    removeConstraintBtn = uibutton(constrBtnPanel, 'Text', 'Remove', ...
                                   'BackgroundColor', [0.7 0.3 0.3]);
    constraintTypeDropdown = uidropdown(constrBtnPanel, ...
        'Items', {'Horizontal', 'Vertical', 'Distance', 'Coincident', 'Tangent', ...
                  'Angle', 'Equal', 'Parallel', 'Perpendicular', 'Fixed', ...
                  'Midpoint', 'Concentric', 'Collinear', 'Symmetry', 'Other'}, ...
        'Value', 'Horizontal');

    constraintInfoLabel = uilabel(constraintsGL, 'Text', 'Select constraint type before adding', ...
                                  'HorizontalAlignment', 'center');

    % Tab 6: Elements
    elementsTab = uitab(tabGroup, 'Title', 'Elements');
    elementsGL = uigridlayout(elementsTab, [3, 1]);
    elementsGL.RowHeight = {'1x', 35, 35};
    elementsGL.Padding = [10 10 10 10];

    elementListBox = uilistbox(elementsGL, 'Items', {});

    elemBtnPanel = uigridlayout(elementsGL, [1, 4]);
    elemBtnPanel.ColumnWidth = {'1x', '1x', '1x', '1x'};
    elemBtnPanel.Padding = [0 0 0 0];

    addElementBtn = uibutton(elemBtnPanel, 'Text', 'Add Element', ...
                             'BackgroundColor', [0.3 0.6 0.3]);
    editElementBtn = uibutton(elemBtnPanel, 'Text', 'Edit', ...
                              'BackgroundColor', [0.5 0.5 0.7]);
    removeElementBtn = uibutton(elemBtnPanel, 'Text', 'Remove', ...
                                'BackgroundColor', [0.7 0.3 0.3]);
    elementTypeDropdown = uidropdown(elemBtnPanel, ...
        'Items', {'StartPoint', 'EndPoint', 'MidPoint', 'ControlPoint', ...
                  'Line', 'Rectangle', 'Circle', 'Parabola', 'Ellipse', ...
                  'Contour', 'Arc', 'Spline', 'Slot', 'Centerline', 'Centerpoint'}, ...
        'Value', 'Line');

    elementInfoLabel = uilabel(elementsGL, 'Text', 'Add sketch elements (lines, arcs, circles, etc.)', ...
                               'HorizontalAlignment', 'center');

    % Tab 7: JSON Preview
    jsonTab = uitab(tabGroup, 'Title', 'JSON');
    jsonGL = uigridlayout(jsonTab, [1, 1]);
    jsonGL.Padding = [10 10 10 10];

    jsonArea = uitextarea(jsonGL, 'Value', '', 'Editable', 'off', ...
                          'FontName', 'Consolas', 'FontSize', 9);

    % Store UI components
    ui = struct();
    ui.fig = fig;
    ui.sketchListBox = sketchListBox;
    ui.sketchIdEdit = sketchIdEdit;
    ui.versionEdit = versionEdit;
    ui.is2DCheck = is2DCheck;
    ui.areaEdit = areaEdit;
    ui.perimeterEdit = perimeterEdit;
    ui.closedLoopLabel = closedLoopLabel;
    ui.contiguousLabel = contiguousLabel;
    ui.summaryLabel = summaryLabel;
    ui.pointListBox = pointListBox;
    ui.pointXEdit = pointXEdit;
    ui.pointYEdit = pointYEdit;
    ui.pointZEdit = pointZEdit;
    ui.segmentListBox = segmentListBox;
    ui.segmentInfoLabel = segmentInfoLabel;
    ui.dimensionListBox = dimensionListBox;
    ui.dimInfoLabel = dimInfoLabel;
    ui.constraintListBox = constraintListBox;
    ui.constraintTypeDropdown = constraintTypeDropdown;
    ui.constraintInfoLabel = constraintInfoLabel;
    ui.elementListBox = elementListBox;
    ui.elementTypeDropdown = elementTypeDropdown;
    ui.elementInfoLabel = elementInfoLabel;
    ui.jsonArea = jsonArea;
    ui.statusLabel = statusLabel;

    % Set up callbacks
    sketchListBox.ValueChangedFcn = @(~,~) onSketchSelected(ui);

    % Management
    newBtn.ButtonPushedFcn = @(~,~) addNewSketch(ui);
    duplicateBtn.ButtonPushedFcn = @(~,~) duplicateSketch(ui);
    deleteBtn.ButtonPushedFcn = @(~,~) deleteSketch(ui);

    % Templates
    rectBtn.ButtonPushedFcn = @(~,~) createTemplateSketch(ui, 'Rectangle');
    circleBtn.ButtonPushedFcn = @(~,~) createTemplateSketch(ui, 'Circle');
    polygonBtn.ButtonPushedFcn = @(~,~) createTemplateSketch(ui, 'Polygon');

    % Import/Export
    importBtn.ButtonPushedFcn = @(~,~) importSketches(ui);
    exportBtn.ButtonPushedFcn = @(~,~) exportAllSketches(ui);
    validateBtn.ButtonPushedFcn = @(~,~) validateAllSketches(ui);

    % Editor actions
    updateBtn.ButtonPushedFcn = @(~,~) updateCurrentSketch(ui);
    saveFileBtn.ButtonPushedFcn = @(~,~) saveSketchToFile(ui);
    copyJsonBtn.ButtonPushedFcn = @(~,~) copySketchJson(ui);
    clearSketchBtn.ButtonPushedFcn = @(~,~) clearSketchGeometry(ui);

    % Points
    addPointBtn.ButtonPushedFcn = @(~,~) addPoint(ui);
    editPointBtn.ButtonPushedFcn = @(~,~) editPoint(ui);
    removePointBtn.ButtonPushedFcn = @(~,~) removePoint(ui);
    clearPointsBtn.ButtonPushedFcn = @(~,~) clearAllPoints(ui);

    % Segments
    addSegmentBtn.ButtonPushedFcn = @(~,~) addSegment(ui);
    editSegmentBtn.ButtonPushedFcn = @(~,~) editSegment(ui);
    removeSegmentBtn.ButtonPushedFcn = @(~,~) removeSegment(ui);
    clearSegmentsBtn.ButtonPushedFcn = @(~,~) clearAllSegments(ui);

    % Dimensions
    addDimBtn.ButtonPushedFcn = @(~,~) addDimension(ui);
    editDimBtn.ButtonPushedFcn = @(~,~) editDimension(ui);
    removeDimBtn.ButtonPushedFcn = @(~,~) removeDimension(ui);
    dimGuiBtn.ButtonPushedFcn = @(~,~) openDimensionGUI(ui);

    % Constraints
    addConstraintBtn.ButtonPushedFcn = @(~,~) addConstraint(ui);
    editConstraintBtn.ButtonPushedFcn = @(~,~) editConstraint(ui);
    removeConstraintBtn.ButtonPushedFcn = @(~,~) removeConstraint(ui);

    % Elements
    addElementBtn.ButtonPushedFcn = @(~,~) addElement(ui);
    editElementBtn.ButtonPushedFcn = @(~,~) editElement(ui);
    removeElementBtn.ButtonPushedFcn = @(~,~) removeElement(ui);

    % Wait for figure to close if output requested
    if nargout > 0
        uiwait(fig);
        if isvalid(fig)
            varargout{1} = fig.UserData.sketches;
            close(fig);
        else
            varargout{1} = {};
        end
    end
end

%% Create default sketch struct
function sketch = createDefaultSketch()
    sketch = struct();
    sketch.SketchID = '';
    sketch.Version = '1.0';
    sketch.IsTwoD = true;
    sketch.MyPoints = {};
    sketch.MySegments = {};
    sketch.MyProfile = {};
    sketch.My2DGeometry = {};
    sketch.MyCoordinateSystems = {};
    sketch.MySketchElements = {};
    sketch.MyParameters = {};
    sketch.MyDimensions = {};
    sketch.MyConstraints = {};
end

%% Add new sketch
function addNewSketch(ui)
    sketches = ui.fig.UserData.sketches;

    sketch = createDefaultSketch();
    sketch.SketchID = sprintf('SK-%03d', length(sketches) + 1);

    sketches{end+1} = sketch;
    ui.fig.UserData.sketches = sketches;
    ui.fig.UserData.selectedIndex = length(sketches);

    updateSketchList(ui);
    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'New sketch added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Create template sketch
function createTemplateSketch(ui, templateType)
    sketches = ui.fig.UserData.sketches;

    sketch = createDefaultSketch();
    sketch.SketchID = sprintf('SK-%s-%03d', upper(templateType(1:3)), length(sketches) + 1);

    switch templateType
        case 'Rectangle'
            % Create rectangle with 4 points and 4 segments
            sketch.MyPoints{1} = createPoint(0, 0, 0);
            sketch.MyPoints{2} = createPoint(100, 0, 0);
            sketch.MyPoints{3} = createPoint(100, 50, 0);
            sketch.MyPoints{4} = createPoint(0, 50, 0);

            sketch.MySegments{1} = createSegment(sketch.MyPoints{1}, sketch.MyPoints{2}, 'Bottom');
            sketch.MySegments{2} = createSegment(sketch.MyPoints{2}, sketch.MyPoints{3}, 'Right');
            sketch.MySegments{3} = createSegment(sketch.MyPoints{3}, sketch.MyPoints{4}, 'Top');
            sketch.MySegments{4} = createSegment(sketch.MyPoints{4}, sketch.MyPoints{1}, 'Left');

            % Add dimension
            dim = struct();
            dim.DimensionID = 'DIM_WIDTH';
            dim.Name = 'Width';
            dim.DimensionNominalValue = 100;
            dim.MyDimensionType = 0;
            sketch.MyDimensions{1} = dim;

            dim2 = struct();
            dim2.DimensionID = 'DIM_HEIGHT';
            dim2.Name = 'Height';
            dim2.DimensionNominalValue = 50;
            dim2.MyDimensionType = 0;
            sketch.MyDimensions{2} = dim2;

        case 'Circle'
            % Create circle with center and radius
            sketch.MyPoints{1} = createPoint(0, 0, 0); % Center

            elem = struct();
            elem.Name = 'Circle_1';
            elem.MySketchElemType = 6; % Circle
            elem.Radius = 25;
            elem.CenterPoint = sketch.MyPoints{1};
            sketch.MySketchElements{1} = elem;

            dim = struct();
            dim.DimensionID = 'DIM_RADIUS';
            dim.Name = 'Radius';
            dim.DimensionNominalValue = 25;
            dim.MyDimensionType = 2; % Radius
            sketch.MyDimensions{1} = dim;

        case 'Polygon'
            % Create hexagon
            n = 6;
            radius = 30;
            for i = 1:n
                angle = (i-1) * 2 * pi / n;
                x = radius * cos(angle);
                y = radius * sin(angle);
                sketch.MyPoints{i} = createPoint(x, y, 0);
            end

            for i = 1:n
                nextIdx = mod(i, n) + 1;
                sketch.MySegments{i} = createSegment(sketch.MyPoints{i}, sketch.MyPoints{nextIdx}, sprintf('Side_%d', i));
            end
    end

    sketches{end+1} = sketch;
    ui.fig.UserData.sketches = sketches;
    ui.fig.UserData.selectedIndex = length(sketches);

    updateSketchList(ui);
    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = sprintf('%s sketch created', templateType);
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Create point helper
function pt = createPoint(x, y, z)
    pt = struct();
    pt.X_Value = x;
    pt.Y_Value = y;
    pt.Z_Value_Cartesian = z;
end

%% Create segment helper
function seg = createSegment(startPt, endPt, name)
    seg = struct();
    seg.SegmentID = name;
    seg.StartPoint = startPt;
    seg.EndPoint = endPt;
end

%% Update sketch list display
function updateSketchList(ui)
    sketches = ui.fig.UserData.sketches;
    items = cell(1, length(sketches));

    for i = 1:length(sketches)
        s = sketches{i};
        nPts = length(s.MyPoints);
        nSegs = length(s.MySegments);
        items{i} = sprintf('%d. %s (P:%d S:%d)', i, s.SketchID, nPts, nSegs);
    end

    ui.sketchListBox.Items = items;

    idx = ui.fig.UserData.selectedIndex;
    if idx > 0 && idx <= length(items)
        ui.sketchListBox.Value = items{idx};
    end
end

%% On sketch selected
function onSketchSelected(ui)
    if isempty(ui.sketchListBox.Value)
        return;
    end

    selStr = ui.sketchListBox.Value;
    dotPos = strfind(selStr, '.');
    if ~isempty(dotPos)
        idx = str2double(selStr(1:dotPos(1)-1));
        ui.fig.UserData.selectedIndex = idx;

        sketches = ui.fig.UserData.sketches;
        if idx > 0 && idx <= length(sketches)
            loadSketchToEditor(ui, sketches{idx});
        end
    end
end

%% Load sketch to editor
function loadSketchToEditor(ui, sketch)
    ui.sketchIdEdit.Value = sketch.SketchID;
    ui.versionEdit.Value = sketch.Version;
    ui.is2DCheck.Value = sketch.IsTwoD;

    % Area and perimeter
    if isfield(sketch, 'Area') && isfield(sketch.Area, 'Value')
        ui.areaEdit.Value = sketch.Area.Value.DoubleValue;
    else
        ui.areaEdit.Value = 0;
    end

    if isfield(sketch, 'PerimeterLength') && isfield(sketch.PerimeterLength, 'Value')
        ui.perimeterEdit.Value = sketch.PerimeterLength.Value.DoubleValue;
    else
        ui.perimeterEdit.Value = 0;
    end

    % Check contiguity and closed loop
    [isClosed, isContig] = checkSketchGeometry(sketch);
    if isContig
        ui.contiguousLabel.Text = 'Yes';
        ui.contiguousLabel.FontColor = [0.2 0.7 0.2];
    else
        ui.contiguousLabel.Text = 'No';
        ui.contiguousLabel.FontColor = [0.7 0.3 0.3];
    end

    if isClosed
        ui.closedLoopLabel.Text = 'Yes';
        ui.closedLoopLabel.FontColor = [0.2 0.7 0.2];
    else
        ui.closedLoopLabel.Text = 'No';
        ui.closedLoopLabel.FontColor = [0.7 0.3 0.3];
    end

    % Summary
    ui.summaryLabel.Text = sprintf('Points: %d | Segments: %d | Dims: %d | Constraints: %d', ...
        length(sketch.MyPoints), length(sketch.MySegments), ...
        length(sketch.MyDimensions), length(sketch.MyConstraints));

    % Point list
    pointItems = {};
    for i = 1:length(sketch.MyPoints)
        p = sketch.MyPoints{i};
        pointItems{i} = sprintf('%d. (%.2f, %.2f, %.2f)', i, p.X_Value, p.Y_Value, p.Z_Value_Cartesian);
    end
    ui.pointListBox.Items = pointItems;

    % Segment list
    segItems = {};
    for i = 1:length(sketch.MySegments)
        s = sketch.MySegments{i};
        segItems{i} = sprintf('%d. %s', i, s.SegmentID);
    end
    ui.segmentListBox.Items = segItems;

    % Dimension list
    dimItems = {};
    for i = 1:length(sketch.MyDimensions)
        d = sketch.MyDimensions{i};
        dimItems{i} = sprintf('%d. %s = %.3f', i, d.Name, d.DimensionNominalValue);
    end
    ui.dimensionListBox.Items = dimItems;

    % Constraint list
    constrItems = {};
    for i = 1:length(sketch.MyConstraints)
        c = sketch.MyConstraints{i};
        if isfield(c, 'Name')
            constrItems{i} = sprintf('%d. %s', i, c.Name);
        else
            constrItems{i} = sprintf('%d. Constraint_%d', i, i);
        end
    end
    ui.constraintListBox.Items = constrItems;

    % Element list
    elemItems = {};
    for i = 1:length(sketch.MySketchElements)
        e = sketch.MySketchElements{i};
        if isfield(e, 'Name')
            elemItems{i} = sprintf('%d. %s', i, e.Name);
        else
            elemItems{i} = sprintf('%d. Element_%d', i, i);
        end
    end
    ui.elementListBox.Items = elemItems;

    % JSON preview
    jsonStr = jsonencode(sketch, 'PrettyPrint', true);
    ui.jsonArea.Value = jsonStr;
end

%% Check sketch geometry
function [isClosed, isContiguous] = checkSketchGeometry(sketch)
    isClosed = false;
    isContiguous = false;

    if isempty(sketch.MySegments)
        return;
    end

    % Check contiguity
    tol = 1e-9;
    isContiguous = true;

    for i = 2:length(sketch.MySegments)
        prevSeg = sketch.MySegments{i-1};
        currSeg = sketch.MySegments{i};

        if ~isfield(prevSeg, 'EndPoint') || ~isfield(currSeg, 'StartPoint')
            isContiguous = false;
            break;
        end

        dx = prevSeg.EndPoint.X_Value - currSeg.StartPoint.X_Value;
        dy = prevSeg.EndPoint.Y_Value - currSeg.StartPoint.Y_Value;
        dz = prevSeg.EndPoint.Z_Value_Cartesian - currSeg.StartPoint.Z_Value_Cartesian;

        if (dx*dx + dy*dy + dz*dz) > tol*tol
            isContiguous = false;
            break;
        end
    end

    % Check if closed
    if isContiguous && length(sketch.MySegments) >= 1
        firstSeg = sketch.MySegments{1};
        lastSeg = sketch.MySegments{end};

        if isfield(firstSeg, 'StartPoint') && isfield(lastSeg, 'EndPoint')
            dx = firstSeg.StartPoint.X_Value - lastSeg.EndPoint.X_Value;
            dy = firstSeg.StartPoint.Y_Value - lastSeg.EndPoint.Y_Value;
            dz = firstSeg.StartPoint.Z_Value_Cartesian - lastSeg.EndPoint.Z_Value_Cartesian;

            isClosed = (dx*dx + dy*dy + dz*dz) <= tol*tol;
        end
    end
end

%% Update current sketch
function updateCurrentSketch(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'No sketch selected!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    try
        sketches = ui.fig.UserData.sketches;
        sketch = sketches{idx};

        sketch.SketchID = ui.sketchIdEdit.Value;
        sketch.Version = ui.versionEdit.Value;
        sketch.IsTwoD = ui.is2DCheck.Value;

        if ui.areaEdit.Value > 0
            sketch.Area = struct();
            sketch.Area.Name = 'Area';
            sketch.Area.Value = struct('DoubleValue', ui.areaEdit.Value, 'ValueType', 0);
        end

        if ui.perimeterEdit.Value > 0
            sketch.PerimeterLength = struct();
            sketch.PerimeterLength.Name = 'PerimeterLength';
            sketch.PerimeterLength.Value = struct('DoubleValue', ui.perimeterEdit.Value, 'ValueType', 0);
        end

        sketches{idx} = sketch;
        ui.fig.UserData.sketches = sketches;

        updateSketchList(ui);
        loadSketchToEditor(ui, sketch);

        ui.statusLabel.Text = 'Sketch updated!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Duplicate sketch
function duplicateSketch(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a sketch first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    sketches = ui.fig.UserData.sketches;
    newSketch = sketches{idx};
    newSketch.SketchID = [newSketch.SketchID '-COPY'];

    sketches{end+1} = newSketch;
    ui.fig.UserData.sketches = sketches;
    ui.fig.UserData.selectedIndex = length(sketches);

    updateSketchList(ui);
    loadSketchToEditor(ui, newSketch);

    ui.statusLabel.Text = 'Sketch duplicated';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Delete sketch
function deleteSketch(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a sketch first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    sketches = ui.fig.UserData.sketches;
    sketches(idx) = [];
    ui.fig.UserData.sketches = sketches;

    if idx > length(sketches)
        idx = length(sketches);
    end
    ui.fig.UserData.selectedIndex = idx;

    updateSketchList(ui);

    if idx > 0
        loadSketchToEditor(ui, sketches{idx});
    else
        clearEditor(ui);
    end

    ui.statusLabel.Text = 'Sketch deleted';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Clear editor
function clearEditor(ui)
    ui.sketchIdEdit.Value = '';
    ui.versionEdit.Value = '1.0';
    ui.is2DCheck.Value = true;
    ui.areaEdit.Value = 0;
    ui.perimeterEdit.Value = 0;
    ui.pointListBox.Items = {};
    ui.segmentListBox.Items = {};
    ui.dimensionListBox.Items = {};
    ui.constraintListBox.Items = {};
    ui.elementListBox.Items = {};
    ui.jsonArea.Value = '';
end

%% Clear sketch geometry
function clearSketchGeometry(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};

    sketch.MyPoints = {};
    sketch.MySegments = {};
    sketch.MyDimensions = {};
    sketch.MyConstraints = {};
    sketch.MySketchElements = {};

    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'Sketch geometry cleared';
    ui.statusLabel.FontColor = [0.7 0.5 0.2];
end

%% Add point
function addPoint(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a sketch first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};

    pt = createPoint(ui.pointXEdit.Value, ui.pointYEdit.Value, ui.pointZEdit.Value);
    sketch.MyPoints{end+1} = pt;

    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = sprintf('Point added at (%.2f, %.2f, %.2f)', pt.X_Value, pt.Y_Value, pt.Z_Value_Cartesian);
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit point (placeholder)
function editPoint(ui)
    ui.statusLabel.Text = 'Edit point values in X, Y, Z fields, then add new point';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove point
function removePoint(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    ptSel = ui.pointListBox.Value;
    if isempty(ptSel)
        ui.statusLabel.Text = 'Select a point first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(ptSel, '.');
    if isempty(dotPos), return; end
    ptIdx = str2double(ptSel(1:dotPos(1)-1));

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};
    sketch.MyPoints(ptIdx) = [];
    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'Point removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Clear all points
function clearAllPoints(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};
    sketch.MyPoints = {};
    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'All points cleared';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Add segment
function addSegment(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a sketch first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};

    if length(sketch.MyPoints) < 2
        ui.statusLabel.Text = 'Need at least 2 points to create segment!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    % Use last two points
    startPt = sketch.MyPoints{end-1};
    endPt = sketch.MyPoints{end};

    seg = createSegment(startPt, endPt, sprintf('Segment_%d', length(sketch.MySegments) + 1));
    sketch.MySegments{end+1} = seg;

    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'Segment added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit segment (placeholder)
function editSegment(ui)
    ui.statusLabel.Text = 'Segment editing not yet implemented';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove segment
function removeSegment(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    segSel = ui.segmentListBox.Value;
    if isempty(segSel)
        ui.statusLabel.Text = 'Select a segment first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(segSel, '.');
    if isempty(dotPos), return; end
    segIdx = str2double(segSel(1:dotPos(1)-1));

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};
    sketch.MySegments(segIdx) = [];
    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'Segment removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Clear all segments
function clearAllSegments(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};
    sketch.MySegments = {};
    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'All segments cleared';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Add dimension
function addDimension(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a sketch first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};

    dim = struct();
    dim.DimensionID = sprintf('DIM_%d', length(sketch.MyDimensions) + 1);
    dim.Name = sprintf('Dimension_%d', length(sketch.MyDimensions) + 1);
    dim.DimensionNominalValue = 0;
    dim.MyDimensionType = 0;

    sketch.MyDimensions{end+1} = dim;
    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

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

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};
    sketch.MyDimensions(dimIdx) = [];
    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

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

%% Add constraint
function addConstraint(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a sketch first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};

    constraintTypes = containers.Map(...
        {'Horizontal', 'Vertical', 'Distance', 'Coincident', 'Tangent', ...
         'Angle', 'Equal', 'Parallel', 'Perpendicular', 'Fixed', ...
         'Midpoint', 'Concentric', 'Collinear', 'Symmetry', 'Other'}, ...
        {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 16});

    constr = struct();
    constr.Name = sprintf('%s_%d', ui.constraintTypeDropdown.Value, length(sketch.MyConstraints) + 1);
    constr.ConstraintType = constraintTypes(ui.constraintTypeDropdown.Value);

    sketch.MyConstraints{end+1} = constr;
    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'Constraint added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit constraint (placeholder)
function editConstraint(ui)
    ui.statusLabel.Text = 'Constraint editing not yet implemented';
    ui.statusLabel.FontColor = [0.2 0.2 0.8];
end

%% Remove constraint
function removeConstraint(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1, return; end

    constrSel = ui.constraintListBox.Value;
    if isempty(constrSel)
        ui.statusLabel.Text = 'Select a constraint first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    dotPos = strfind(constrSel, '.');
    if isempty(dotPos), return; end
    constrIdx = str2double(constrSel(1:dotPos(1)-1));

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};
    sketch.MyConstraints(constrIdx) = [];
    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'Constraint removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Add element
function addElement(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a sketch first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};

    elemTypes = containers.Map(...
        {'StartPoint', 'EndPoint', 'MidPoint', 'ControlPoint', ...
         'Line', 'Rectangle', 'Circle', 'Parabola', 'Ellipse', ...
         'Contour', 'Arc', 'Spline', 'Slot', 'Centerline', 'Centerpoint'}, ...
        {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15});

    elem = struct();
    elem.Name = sprintf('%s_%d', ui.elementTypeDropdown.Value, length(sketch.MySketchElements) + 1);
    elem.MySketchElemType = elemTypes(ui.elementTypeDropdown.Value);

    sketch.MySketchElements{end+1} = elem;
    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'Element added';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end

%% Edit element (placeholder)
function editElement(ui)
    ui.statusLabel.Text = 'Element editing not yet implemented';
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

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};
    sketch.MySketchElements(elemIdx) = [];
    sketches{idx} = sketch;
    ui.fig.UserData.sketches = sketches;

    loadSketchToEditor(ui, sketch);

    ui.statusLabel.Text = 'Element removed';
    ui.statusLabel.FontColor = [0.7 0.3 0.3];
end

%% Validate all sketches
function validateAllSketches(ui)
    sketches = ui.fig.UserData.sketches;
    if isempty(sketches)
        ui.statusLabel.Text = 'No sketches to validate!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    validCount = 0;
    for i = 1:length(sketches)
        [isClosed, isContig] = checkSketchGeometry(sketches{i});
        if isContig
            validCount = validCount + 1;
        end
    end

    ui.statusLabel.Text = sprintf('Validation: %d/%d sketches have contiguous geometry', validCount, length(sketches));
    if validCount == length(sketches)
        ui.statusLabel.FontColor = [0.2 0.7 0.2];
    else
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
    end
end

%% Import sketches
function importSketches(ui)
    [filename, pathname] = uigetfile({'*.json', 'JSON Files'}, 'Import Sketches');
    if filename == 0, return; end

    try
        jsonStr = fileread(fullfile(pathname, filename));
        imported = jsondecode(jsonStr);

        if isfield(imported, 'Sketches')
            for i = 1:length(imported.Sketches)
                sketches = ui.fig.UserData.sketches;
                sketches{end+1} = imported.Sketches(i);
                ui.fig.UserData.sketches = sketches;
            end
        else
            sketches = ui.fig.UserData.sketches;
            sketches{end+1} = imported;
            ui.fig.UserData.sketches = sketches;
        end

        updateSketchList(ui);
        ui.statusLabel.Text = 'Sketches imported!';
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Import error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Export all sketches
function exportAllSketches(ui)
    sketches = ui.fig.UserData.sketches;
    if isempty(sketches)
        ui.statusLabel.Text = 'No sketches to export!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Export All Sketches', 'CAD_Sketches.json');
    if filename == 0, return; end

    try
        collection = struct();
        collection.ExportDate = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        collection.SketchCount = length(sketches);
        collection.Sketches = sketches;

        jsonStr = jsonencode(collection, 'PrettyPrint', true);
        fid = fopen(fullfile(pathname, filename), 'w');
        fprintf(fid, '%s', jsonStr);
        fclose(fid);

        ui.statusLabel.Text = sprintf('Exported %d sketches!', length(sketches));
        ui.statusLabel.FontColor = [0.2 0.7 0.2];

    catch ex
        ui.statusLabel.Text = ['Export error: ' ex.message];
        ui.statusLabel.FontColor = [0.8 0.2 0.2];
    end
end

%% Save sketch to file
function saveSketchToFile(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a sketch first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};

    defaultName = [sketch.SketchID '.json'];

    [filename, pathname] = uiputfile({'*.json', 'JSON Files'}, ...
                                      'Save Sketch', defaultName);
    if filename == 0, return; end

    try
        jsonStr = jsonencode(sketch, 'PrettyPrint', true);
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

%% Copy sketch JSON
function copySketchJson(ui)
    idx = ui.fig.UserData.selectedIndex;
    if idx < 1
        ui.statusLabel.Text = 'Select a sketch first!';
        ui.statusLabel.FontColor = [0.8 0.5 0.2];
        return;
    end

    sketches = ui.fig.UserData.sketches;
    sketch = sketches{idx};

    jsonStr = jsonencode(sketch, 'PrettyPrint', true);
    clipboard('copy', jsonStr);

    ui.statusLabel.Text = 'JSON copied to clipboard!';
    ui.statusLabel.FontColor = [0.2 0.7 0.2];
end
