function fig = NewtonRaphsonApp(varargin)
% NEWTONRAPHSONAPP Interactive Newton-Raphson solver and visualizer.
%
% Run:
%   NewtonRaphsonApp
%
% Optional verification mode:
%   NewtonRaphsonApp('SelfTest', true)
%
% The app contains 18 predefined teaching scenarios and a custom
% scientific-calculator-style expression builder. Selecting a scenario only
% loads it. Newton-Raphson iterations start only when RUN is pressed.

%% Startup options
parser = inputParser;
parser.FunctionName = 'NewtonRaphsonApp';
addParameter(parser, 'Visible', 'on', ...
    @(value) ischar(value) || (isstring(value) && isscalar(value)));
addParameter(parser, 'SelfTest', false, ...
    @(value) islogical(value) && isscalar(value));
parse(parser, varargin{:});

appVisible = char(validatestring(parser.Results.Visible, {'on','off'}));

if parser.Results.SelfTest
    runInternalSelfTests();
    fig = [];
    return;
end

%% Application state
state.stopRequested = false;
state.inRun = false;
state.currentScenario = 1;
state.customMode = false;
state.f = [];
state.df = [];
state.scenarioName = '';
state.fText = '';
state.dfText = '';

% Calculator expressions intentionally use familiar calculator notation.
% MATLAB element-wise operators are added only when a function is built.
state.customFExpression = 'x^2-2';
state.customDfExpression = '2*x';
state.customFCursor = length(state.customFExpression);
state.customDfCursor = length(state.customDfExpression);

builderFig = [];

%% Main window
screen = get(groot, 'ScreenSize');
windowWidth = max(1120, min(1700, screen(3) - 40));
windowHeight = max(720, min(960, screen(4) - 80));
windowLeft = max(1, floor((screen(3) - windowWidth) / 2));
windowBottom = max(1, floor((screen(4) - windowHeight) / 2));

fig = uifigure( ...
    'Name', 'Newton-Raphson Method Explorer', ...
    'Color', [0.06 0.06 0.06], ...
    'Position', [windowLeft windowBottom windowWidth windowHeight], ...
    'Visible', appVisible, ...
    'CloseRequestFcn', @closeMainWindow);

mainGrid = uigridlayout(fig, [1 3]);
mainGrid.ColumnWidth = {290, 320, '1x'};
mainGrid.RowHeight = {'1x'};
mainGrid.Padding = [10 10 10 10];
mainGrid.ColumnSpacing = 10;

%% Left panel: scenarios
scenarioPanel = uipanel(mainGrid, ...
    'Title', 'Newton-Raphson Modes', ...
    'ForegroundColor', 'w', ...
    'BackgroundColor', [0.10 0.10 0.10], ...
    'FontWeight', 'bold');

scenarioGrid = uigridlayout(scenarioPanel, [21 1]);
scenarioGrid.RowHeight = [{28}, {42}, repmat({32}, 1, 18), {'1x'}];
scenarioGrid.Padding = [8 8 8 8];
scenarioGrid.RowSpacing = 4;

uilabel(scenarioGrid, ...
    'Text', 'Select a mode or scenario:', ...
    'FontWeight', 'bold', ...
    'FontColor', 'w');

customButton = uibutton(scenarioGrid, ...
    'Text', 'CUSTOM FUNCTION', ...
    'BackgroundColor', [0.35 0.18 0.50], ...
    'FontColor', 'w', ...
    'FontWeight', 'bold', ...
    'FontSize', 13, ...
    'ButtonPushedFcn', @customPressed);

scenarioNames = { ...
    '01 - Zero derivative'
    '02 - Small derivative / Overshoot'
    '03 - Periodic cycle'
    '04 - No root, residual -> 0'
    '05 - No real root'
    '06 - Log domain violation'
    '07 - SQRT domain violation'
    '08 - Root exists but divergence'
    '09 - Double root'
    '10 - Seventh-order root'
    '11 - Multiple roots'
    '12 - Sine / Large jump'
    '13 - Exponential / Overflow'
    '14 - Asymptote / Escape to infinity'
    '15 - Step function'
    '16 - Non-differentiable point'
    '17 - Scaling problem'
    '18 - sin(1/x) sensitivity'};

scenarioButtons = gobjects(18, 1);
for index = 1:18
    scenarioButtons(index) = uibutton(scenarioGrid, ...
        'Text', scenarioNames{index}, ...
        'BackgroundColor', [0.18 0.18 0.18], ...
        'FontColor', 'w', ...
        'HorizontalAlignment', 'left', ...
        'ButtonPushedFcn', @(~,~) scenarioPressed(index));
end

%% Middle panel: controls
controlPanel = uipanel(mainGrid, ...
    'Title', 'Parameters', ...
    'ForegroundColor', 'w', ...
    'BackgroundColor', [0.10 0.10 0.10], ...
    'FontWeight', 'bold');

controlGrid = uigridlayout(controlPanel, [21 2]);
controlGrid.ColumnWidth = {'1x', '1.30x'};
controlGrid.RowHeight = { ...
    40, 34, 34, 42, ...
    28, 28, 28, 28, 28, ...
    28, 28, 28, 28, ...
    30, 42, 42, 28, 88, 26, 26, 26};
controlGrid.Padding = [10 10 10 10];
controlGrid.RowSpacing = 5;

scenarioTitle = uilabel(controlGrid, ...
    'Text', 'Scenario', ...
    'FontColor', [0.00 0.85 1.00], ...
    'FontWeight', 'bold', ...
    'FontSize', 14);
scenarioTitle.Layout.Column = [1 2];

uilabel(controlGrid, 'Text', 'f(x)', ...
    'FontColor', [0.00 0.85 1.00], 'FontWeight', 'bold');
functionInputField = uieditfield(controlGrid, 'text', ...
    'Value', 'x^2 - 2', 'Editable', 'off');

uilabel(controlGrid, 'Text', 'f''(x)', ...
    'FontColor', [1.00 0.85 0.00], 'FontWeight', 'bold');
derivativeInputField = uieditfield(controlGrid, 'text', ...
    'Value', '2*x', 'Editable', 'off');

calculatorButton = uibutton(controlGrid, ...
    'Text', 'OPEN FUNCTION CALCULATOR', ...
    'FontWeight', 'bold', ...
    'FontSize', 12, ...
    'BackgroundColor', [0.35 0.18 0.50], ...
    'FontColor', 'w', ...
    'Enable', 'off', ...
    'ButtonPushedFcn', @openFunctionBuilder);
calculatorButton.Layout.Column = [1 2];

uilabel(controlGrid, 'Text', 'Initial guess x0', 'FontColor', 'w');
x0Field = uieditfield(controlGrid, 'numeric', 'Value', 0);

uilabel(controlGrid, 'Text', 'Tolerance', 'FontColor', 'w');
tolField = uieditfield(controlGrid, 'numeric', 'Value', 1e-12);

uilabel(controlGrid, 'Text', 'Max iterations', 'FontColor', 'w');
maxIterField = uieditfield(controlGrid, 'numeric', 'Value', 50);

uilabel(controlGrid, 'Text', 'Delay [s]', 'FontColor', 'w');
pauseField = uieditfield(controlGrid, 'numeric', 'Value', 0.5);

uilabel(controlGrid, 'Text', 'Derivative', 'FontColor', 'w');
derivativeDrop = uidropdown(controlGrid, ...
    'Items', {'Analytical', 'Numerical'}, ...
    'Value', 'Analytical', ...
    'ValueChangedFcn', @derivativeModeChanged);

uilabel(controlGrid, 'Text', 'X min', 'FontColor', 'w');
xMinField = uieditfield(controlGrid, 'numeric');

uilabel(controlGrid, 'Text', 'X max', 'FontColor', 'w');
xMaxField = uieditfield(controlGrid, 'numeric');

uilabel(controlGrid, 'Text', 'Y min', 'FontColor', 'w');
yMinField = uieditfield(controlGrid, 'numeric');

uilabel(controlGrid, 'Text', 'Y max', 'FontColor', 'w');
yMaxField = uieditfield(controlGrid, 'numeric');

controlHeader = uilabel(controlGrid, ...
    'Text', 'CONTROL', ...
    'FontWeight', 'bold', ...
    'FontColor', [1 0.85 0]);
controlHeader.Layout.Column = [1 2];

runButton = uibutton(controlGrid, ...
    'Text', 'RUN', ...
    'FontWeight', 'bold', ...
    'FontSize', 16, ...
    'BackgroundColor', [0.10 0.55 0.20], ...
    'FontColor', 'w', ...
    'ButtonPushedFcn', @runPressed);
runButton.Layout.Column = [1 2];

stopButton = uibutton(controlGrid, ...
    'Text', 'STOP', ...
    'FontWeight', 'bold', ...
    'FontSize', 15, ...
    'BackgroundColor', [0.65 0.12 0.12], ...
    'FontColor', 'w', ...
    'Enable', 'off', ...
    'ButtonPushedFcn', @stopPressed);
stopButton.Layout.Column = [1 2];

statusHeader = uilabel(controlGrid, ...
    'Text', 'STATUS', ...
    'FontColor', [0.00 0.85 1.00], ...
    'FontWeight', 'bold');
statusHeader.Layout.Column = [1 2];

statusArea = uitextarea(controlGrid, ...
    'Editable', 'off', ...
    'Value', {'Ready.'}, ...
    'FontColor', 'w', ...
    'BackgroundColor', [0.06 0.06 0.06]);
statusArea.Layout.Column = [1 2];

resultLabel1 = uilabel(controlGrid, 'Text', 'Final x: -', 'FontColor', 'w');
resultLabel1.Layout.Column = [1 2];
resultLabel2 = uilabel(controlGrid, 'Text', 'Iterations: -', 'FontColor', 'w');
resultLabel2.Layout.Column = [1 2];
resultLabel3 = uilabel(controlGrid, 'Text', 'Residual: -', 'FontColor', 'w');
resultLabel3.Layout.Column = [1 2];

%% Right side: formulas, plot, and table
rightGrid = uigridlayout(mainGrid, [3 1]);
rightGrid.RowHeight = {250, '3x', '1.2x'};
rightGrid.Padding = [0 0 0 0];
rightGrid.RowSpacing = 8;

infoPanel = uipanel(rightGrid, ...
    'BackgroundColor', [0.08 0.08 0.08], ...
    'ForegroundColor', 'w');
infoGrid = uigridlayout(infoPanel, [6 1]);
infoGrid.RowHeight = {68, 34, 34, 34, 34, 36};
infoGrid.Padding = [10 6 10 6];
infoGrid.RowSpacing = 3;

uilabel(infoGrid, ...
    'Text', '$\displaystyle x_{n+1}=x_n-\frac{f(x_n)}{f''(x_n)}$', ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 28, ...
    'FontColor', 'w');

functionFormulaLabel = uilabel(infoGrid, ...
    'Text', '$f(x)=-$', ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 18, ...
    'FontColor', [0.00 0.85 1.00]);

derivativeFormulaLabel = uilabel(infoGrid, ...
    'Text', '$f''(x)=-$', ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 18, ...
    'FontColor', [1.00 0.85 0.00]);

liveValueLabel = uilabel(infoGrid, ...
    'Text', '$x_n=-\qquad f(x_n)=-\qquad f''(x_n)=-$', ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 17, ...
    'FontColor', [0.00 0.85 1.00]);

liveStepLabel = uilabel(infoGrid, ...
    'Text', '$x_{n+1}=-$', ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 18, ...
    'FontColor', [1.00 0.85 0.00]);

liveMessageLabel = uilabel(infoGrid, ...
    'Text', 'Select a mode, then press RUN.', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'FontColor', 'w');

ax = uiaxes(rightGrid);
ax.Color = [0.02 0.02 0.02];
ax.XColor = 'w';
ax.YColor = 'w';
ax.GridColor = [0.55 0.55 0.55];
ax.MinorGridColor = [0.35 0.35 0.35];
ax.FontSize = 11;
ax.Box = 'on';

iterationTable = uitable(rightGrid, ...
    'Data', [], ...
    'ColumnName', {'n', 'x_n', 'f(x_n)', 'f''(x_n)', 'Step'}, ...
    'ColumnEditable', false(1, 5), ...
    'BackgroundColor', [0.12 0.12 0.12; 0.16 0.16 0.16], ...
    'ForegroundColor', 'w');

busyControls = [x0Field, tolField, maxIterField, pauseField, ...
    derivativeDrop, xMinField, xMaxField, yMinField, yMaxField];

%% Initial load (does not run Newton-Raphson)
loadScenario(1);
highlightScenarioButton(1);
resetRunDisplay();
statusArea.Value = {'Scenario loaded.', 'Press RUN to start.'};

%% Main callbacks
    function scenarioPressed(id)
        if state.inRun
            return;
        end
        loadScenario(id);
        highlightScenarioButton(id);
        resetRunDisplay();
        statusArea.Value = { ...
            sprintf('Scenario %02d loaded.', id), ...
            'Press RUN to start.'};
    end

    function customPressed(~, ~)
        if state.inRun
            return;
        end

        state.customMode = true;
        state.currentScenario = 0;
        state.scenarioName = 'Custom Function';
        state.fText = state.customFExpression;
        state.dfText = state.customDfExpression;

        try
            state.f = makeFunction(state.customFExpression);
            state.df = makeFunction(state.customDfExpression);
        catch
            state.f = [];
            state.df = [];
        end

        scenarioTitle.Text = 'CUSTOM FUNCTION';
        functionInputField.Value = state.customFExpression;
        updateDerivativeDisplay();
        calculatorButton.Enable = 'on';
        highlightScenarioButton(0);
        resetRunDisplay();
        statusArea.Value = { ...
            'CUSTOM FUNCTION MODE', ...
            'Open the calculator to build f(x) and f''(x).', ...
            'Press RUN only after applying the expressions.'};
    end

    function derivativeModeChanged(~, ~)
        updateDerivativeDisplay();
    end

    function updateDerivativeDisplay()
        if strcmp(derivativeDrop.Value, 'Numerical')
            derivativeInputField.Value = 'Numerical derivative (central difference)';
        elseif state.customMode
            derivativeInputField.Value = state.customDfExpression;
        else
            derivativeInputField.Value = state.dfText;
        end
        updateTopFunctionDisplays();
    end

    function updateTopFunctionDisplays()
        functionFormulaLabel.Text = sprintf( ...
            '$f(x)=%s$', expressionToLatex(state.fText));

        if strcmp(derivativeDrop.Value, 'Numerical')
            derivativeFormulaLabel.Text = ...
                '$f''(x)\approx\mathrm{central\ difference}$';
        else
            derivativeFormulaLabel.Text = sprintf( ...
                '$f''(x)=%s$', expressionToLatex(state.dfText));
        end
    end

    function runPressed(~, ~)
        if state.inRun
            return;
        end

        try
            validateRunInputs();

            if state.customMode
                state.f = makeFunction(state.customFExpression);
                if strcmp(derivativeDrop.Value, 'Analytical')
                    state.df = makeFunction(state.customDfExpression);
                end
            end
        catch exception
            statusArea.Value = {'Cannot start.', exception.message};
            uialert(fig, exception.message, 'Invalid settings');
            return;
        end

        state.stopRequested = false;
        setBusy(true);
        cleanupBusyState = onCleanup(@() setBusy(false));

        try
            runNewtonAnimation();
        catch exception
            statusArea.Value = {'Unexpected error:', exception.message};
            liveMessageLabel.Text = 'The run stopped because of an unexpected error.';
        end
        clear cleanupBusyState;
    end

    function stopPressed(~, ~)
        if state.inRun
            state.stopRequested = true;
            stopButton.Enable = 'off';
            statusArea.Value = {'STOP requested.', 'Finishing the current drawing step...'};
        end
    end

%% Scientific calculator with two independent cursor positions
    function openFunctionBuilder(~, ~)
        if ~state.customMode || state.inRun
            return;
        end

        if ~isempty(builderFig) && isvalid(builderFig)
            figure(builderFig);
            return;
        end

        workF = state.customFExpression;
        workDf = state.customDfExpression;
        cursorF = clampCursor(state.customFCursor, workF);
        cursorDf = clampCursor(state.customDfCursor, workDf);

        builderFig = uifigure( ...
            'Name', 'Scientific Function Calculator', ...
            'Color', [0.08 0.08 0.08], ...
            'Position', centeredChildPosition(fig.Position, 760, 650), ...
            'WindowStyle', 'modal', ...
            'CloseRequestFcn', @cancelBuilder);

        builderGrid = uigridlayout(builderFig, [5 1]);
        builderGrid.RowHeight = {42, 42, 66, '1x', 48};
        builderGrid.Padding = [12 12 12 12];
        builderGrid.RowSpacing = 8;

        uilabel(builderGrid, ...
            'Text', 'Build the expression with the calculator buttons. The | symbol is the cursor.', ...
            'FontColor', 'w', ...
            'FontWeight', 'bold', ...
            'FontSize', 14, ...
            'HorizontalAlignment', 'center');

        selectorGrid = uigridlayout(builderGrid, [1 2]);
        selectorGrid.ColumnWidth = {150, '1x'};
        selectorGrid.Padding = [0 0 0 0];
        uilabel(selectorGrid, 'Text', 'Expression to edit:', ...
            'FontColor', 'w', 'FontWeight', 'bold');
        targetDrop = uidropdown(selectorGrid, ...
            'Items', {'f(x)', 'f''(x)'}, ...
            'Value', 'f(x)', ...
            'ValueChangedFcn', @(~,~) refreshBuilderDisplay());

        expressionDisplay = uieditfield(builderGrid, 'text', ...
            'Editable', 'off', ...
            'FontName', 'Courier New', ...
            'FontSize', 18, ...
            'FontWeight', 'bold', ...
            'BackgroundColor', [0.96 0.96 0.96]);

        keyGrid = uigridlayout(builderGrid, [8 7]);
        keyGrid.RowHeight = repmat({'1x'}, 1, 8);
        keyGrid.ColumnWidth = repmat({'1x'}, 1, 7);
        keyGrid.Padding = [0 0 0 0];
        keyGrid.RowSpacing = 5;
        keyGrid.ColumnSpacing = 5;

        editorLabels = {'<', '>', 'DEL', 'FWD DEL', 'CLEAR', '(', ')'};
        editorActions = {'left', 'right', 'backspace', 'forward', 'clear', 'insert:(', 'insert:)'};
        for keyIndex = 1:numel(editorLabels)
            button = uibutton(keyGrid, ...
                'Text', editorLabels{keyIndex}, ...
                'FontWeight', 'bold', ...
                'FontSize', 12, ...
                'BackgroundColor', [0.30 0.30 0.36], ...
                'FontColor', 'w', ...
                'ButtonPushedFcn', @(~,~) editorAction(editorActions{keyIndex}));
            if keyIndex <= 5
                button.BackgroundColor = [0.42 0.20 0.20];
            end
        end

        keyLabels = { ...
            'sin(', 'cos(', 'tan(', 'asin(', 'acos(', 'atan(', 'sqrt('
            'sinh(', 'cosh(', 'tanh(', 'log(', 'log10(', 'exp(', 'abs('
            'sign(', 'round(', 'floor(', 'ceil(', 'x^2', 'x^3', '1/x'
            '7', '8', '9', '/', '^', 'pi', 'e'
            '4', '5', '6', '*', '+', '-', 'x'
            '1', '2', '3', '(', ')', '.', '10^'
            '0', '00', '1e-', ',', 'mod(', 'min(', 'max('};

        keyTokens = keyLabels;
        keyTokens{4,7} = 'exp(1)';

        for row = 1:size(keyLabels, 1)
            for column = 1:size(keyLabels, 2)
                label = keyLabels{row, column};
                token = keyTokens{row, column};
                button = uibutton(keyGrid, ...
                    'Text', label, ...
                    'FontWeight', 'bold', ...
                    'FontSize', 12, ...
                    'BackgroundColor', [0.18 0.18 0.18], ...
                    'FontColor', 'w', ...
                    'ButtonPushedFcn', @(~,~) insertKey(token));

                if any(strcmp(label, {'/', '^', '*', '+', '-'}))
                    button.BackgroundColor = [0.60 0.34 0.05];
                elseif contains(label, '(') && ~strcmp(label, '(')
                    button.BackgroundColor = [0.14 0.32 0.48];
                end
            end
        end

        actionGrid = uigridlayout(builderGrid, [1 3]);
        actionGrid.ColumnWidth = {'1x', '1x', '1.2x'};
        actionGrid.Padding = [0 0 0 0];
        uibutton(actionGrid, ...
            'Text', 'CANCEL', ...
            'FontWeight', 'bold', ...
            'BackgroundColor', [0.35 0.35 0.35], ...
            'FontColor', 'w', ...
            'ButtonPushedFcn', @cancelBuilder);
        uibutton(actionGrid, ...
            'Text', 'TEST EXPRESSIONS', ...
            'FontWeight', 'bold', ...
            'BackgroundColor', [0.12 0.42 0.58], ...
            'FontColor', 'w', ...
            'ButtonPushedFcn', @testBuilderExpressions);
        uibutton(actionGrid, ...
            'Text', 'APPLY AND CLOSE', ...
            'FontWeight', 'bold', ...
            'BackgroundColor', [0.12 0.55 0.22], ...
            'FontColor', 'w', ...
            'ButtonPushedFcn', @applyBuilder);

        refreshBuilderDisplay();

        function selected = editingFunction()
            selected = strcmp(targetDrop.Value, 'f(x)');
        end

        function refreshBuilderDisplay()
            if editingFunction()
                cursorF = clampCursor(cursorF, workF);
                expressionDisplay.Value = expressionWithCursor(workF, cursorF);
            else
                cursorDf = clampCursor(cursorDf, workDf);
                expressionDisplay.Value = expressionWithCursor(workDf, cursorDf);
            end
        end

        function insertKey(token)
            if editingFunction()
                [workF, cursorF] = insertExpression(workF, cursorF, token);
            else
                [workDf, cursorDf] = insertExpression(workDf, cursorDf, token);
            end
            refreshBuilderDisplay();
        end

        function editorAction(action)
            if startsWith(action, 'insert:')
                insertKey(action(8:end));
                return;
            end

            if editingFunction()
                switch action
                    case 'left'
                        cursorF = clampCursor(cursorF - 1, workF);
                    case 'right'
                        cursorF = clampCursor(cursorF + 1, workF);
                    case 'backspace'
                        [workF, cursorF] = backspaceExpression(workF, cursorF);
                    case 'forward'
                        [workF, cursorF] = forwardDeleteExpression(workF, cursorF);
                    case 'clear'
                        workF = '';
                        cursorF = 0;
                end
            else
                switch action
                    case 'left'
                        cursorDf = clampCursor(cursorDf - 1, workDf);
                    case 'right'
                        cursorDf = clampCursor(cursorDf + 1, workDf);
                    case 'backspace'
                        [workDf, cursorDf] = backspaceExpression(workDf, cursorDf);
                    case 'forward'
                        [workDf, cursorDf] = forwardDeleteExpression(workDf, cursorDf);
                    case 'clear'
                        workDf = '';
                        cursorDf = 0;
                end
            end
            refreshBuilderDisplay();
        end

        function testBuilderExpressions(~, ~)
            try
                ensureExpressionIsUsable(workF, 'f(x)');
                if strcmp(derivativeDrop.Value, 'Analytical')
                    ensureExpressionIsUsable(workDf, 'f''(x)');
                end
                uialert(builderFig, ...
                    'The expression syntax is valid.', ...
                    'Expression test', 'Icon', 'success');
            catch exception
                uialert(builderFig, exception.message, ...
                    'Expression test failed', 'Icon', 'error');
            end
        end

        function applyBuilder(~, ~)
            try
                newF = ensureExpressionIsUsable(workF, 'f(x)');
                if strcmp(derivativeDrop.Value, 'Analytical')
                    newDf = ensureExpressionIsUsable(workDf, 'f''(x)');
                else
                    newDf = [];
                    if ~isempty(strtrim(workDf))
                        try
                            newDf = makeFunction(workDf);
                        catch
                            newDf = [];
                        end
                    end
                end
            catch exception
                uialert(builderFig, exception.message, ...
                    'Cannot apply expressions', 'Icon', 'error');
                return;
            end

            state.customFExpression = workF;
            state.customDfExpression = workDf;
            state.customFCursor = clampCursor(cursorF, workF);
            state.customDfCursor = clampCursor(cursorDf, workDf);
            state.f = newF;
            state.df = newDf;
            state.fText = workF;
            state.dfText = workDf;

            functionInputField.Value = workF;
            updateDerivativeDisplay();
            resetRunDisplay();
            statusArea.Value = { ...
                'Custom expressions applied.', ...
                'Press RUN to start.'};

            delete(builderFig);
            builderFig = [];
        end

        function cancelBuilder(~, ~)
            if ~isempty(builderFig) && isvalid(builderFig)
                delete(builderFig);
            end
            builderFig = [];
        end
    end

%% Newton-Raphson engine and animation
    function runNewtonAnimation()
        tolerance = tolField.Value;
        maximumIterations = round(maxIterField.Value);
        delay = pauseField.Value;
        x = x0Field.Value;
        useAnalyticalDerivative = strcmp(derivativeDrop.Value, 'Analytical');

        resetRunDisplay();
        prepareAxes();
        drawFunctionCurve();
        title(ax, state.scenarioName, 'Color', 'w', 'Interpreter', 'none');

        fx = evaluateScalar(state.f, x);
        history = [0, x, fx, NaN, NaN];
        iterationTable.Data = history;

        converged = false;
        stopped = false;
        reason = '';

        if ~isValidRealScalar(fx)
            reason = 'The function is invalid at the initial guess.';
        elseif abs(fx) <= tolerance
            converged = true;
        end

        if isempty(reason) && ~converged
            for iteration = 1:maximumIterations
                drawnow;
                if state.stopRequested
                    stopped = true;
                    reason = 'Stopped by the user.';
                    break;
                end

                fx = evaluateScalar(state.f, x);
                if ~isValidRealScalar(fx)
                    reason = 'The function produced an invalid real value.';
                    break;
                end

                if useAnalyticalDerivative
                    dfx = evaluateScalar(state.df, x);
                else
                    dfx = numericalDerivative(state.f, x);
                end

                history(end, 4) = dfx;
                iterationTable.Data = history;

                if ~isValidRealScalar(dfx)
                    reason = 'The derivative produced an invalid real value.';
                    break;
                end

                derivativeThreshold = 1e-14 * max(1, abs(x));
                if abs(dfx) <= derivativeThreshold
                    reason = sprintf('Derivative is zero or too small at x = %.8g.', x);
                    break;
                end

                step = -fx / dfx;
                xNew = x + step;
                if ~isValidRealScalar(xNew)
                    reason = 'The Newton step produced an invalid real value.';
                    break;
                end

                fxNew = evaluateScalar(state.f, xNew);
                history(end, 5) = step;
                history(end + 1, :) = [iteration, xNew, fxNew, NaN, NaN]; %#ok<AGROW>
                iterationTable.Data = history;

                drawIteration(x, fx, dfx, xNew, fxNew, iteration - 1);
                statusArea.Value = { ...
                    sprintf('Running iteration %d of %d', iteration, maximumIterations), ...
                    sprintf('x = %.12g', xNew), ...
                    sprintf('|f(x)| = %.6e', abs(fxNew))};

                responsivePause(delay);
                if state.stopRequested
                    stopped = true;
                    reason = 'Stopped by the user.';
                    break;
                end

                x = xNew;
                fx = fxNew;

                if ~isValidRealScalar(fx)
                    reason = 'The new point is outside the valid real domain.';
                    break;
                end

                if abs(fx) <= tolerance
                    converged = true;
                    break;
                end

                if iteration == maximumIterations
                    reason = 'Maximum iteration count reached.';
                end
            end
        end

        iterationsUsed = size(history, 1) - 1;
        finalX = history(end, 2);
        finalFx = history(end, 3);

        resultLabel1.Text = sprintf('Final x: %.15g', finalX);
        resultLabel2.Text = sprintf('Iterations: %d', iterationsUsed);
        if isValidRealScalar(finalFx)
            resultLabel3.Text = sprintf('Residual: %.6e', abs(finalFx));
        else
            resultLabel3.Text = 'Residual: undefined';
        end

        if converged
            statusArea.Value = { ...
                'CONVERGED', ...
                sprintf('x = %.15g', finalX), ...
                sprintf('|f(x)| = %.6e', abs(finalFx))};
            liveMessageLabel.Text = 'Converged within the requested tolerance.';
            liveMessageLabel.FontColor = [0.20 1.00 0.35];
        elseif stopped
            statusArea.Value = {'STOPPED', reason};
            liveMessageLabel.Text = reason;
            liveMessageLabel.FontColor = [1.00 0.70 0.20];
        else
            if isempty(reason)
                reason = 'The method did not converge.';
            end
            statusArea.Value = {'NOT CONVERGED', reason};
            liveMessageLabel.Text = reason;
            liveMessageLabel.FontColor = [1.00 0.35 0.35];
        end
    end

    function drawIteration(x, fx, dfx, xNew, fxNew, iterationIndex)
        prepareAxes();
        drawFunctionCurve();
        hold(ax, 'on');

        plotRange = [xMinField.Value, xMaxField.Value];
        tangentY = fx + dfx .* (plotRange - x);
        plot(ax, plotRange, tangentY, ...
            'Color', [1.00 0.85 0.00], 'LineWidth', 2.2);
        plot(ax, x, fx, 'o', ...
            'MarkerSize', 8, 'MarkerFaceColor', [1 0 0], 'MarkerEdgeColor', 'w');
        plot(ax, [xNew xNew], [0 fxNew], '--', ...
            'Color', [0.20 1.00 0.30], 'LineWidth', 1.6);
        plot(ax, xNew, 0, 'o', ...
            'MarkerSize', 8, 'MarkerFaceColor', [1 0 1], 'MarkerEdgeColor', 'w');
        if isValidRealScalar(fxNew)
            plot(ax, xNew, fxNew, 'o', ...
                'MarkerSize', 7, 'MarkerFaceColor', [0.20 1.00 0.30], ...
                'MarkerEdgeColor', 'w');
        end

        title(ax, sprintf('%s | Iteration %d', state.scenarioName, iterationIndex + 1), ...
            'Color', 'w', 'Interpreter', 'none');

        liveValueLabel.Text = sprintf( ...
            '$x_{%d}=%.8g\qquad f(x_{%d})=%.5g\qquad f''(x_{%d})=%.5g$', ...
            iterationIndex, x, iterationIndex, fx, iterationIndex, dfx);
        liveStepLabel.Text = sprintf( ...
            '$x_{%d}=%.8g-\frac{%.5g}{%.5g}=%.8g$', ...
            iterationIndex + 1, x, fx, dfx, xNew);
        liveMessageLabel.Text = sprintf('Newton step: %+.6g', xNew - x);
        liveMessageLabel.FontColor = 'w';
        drawnow;
    end

    function prepareAxes()
        cla(ax);
        ax.Color = [0.02 0.02 0.02];
        ax.XColor = 'w';
        ax.YColor = 'w';
        ax.GridColor = [0.55 0.55 0.55];
        ax.MinorGridColor = [0.35 0.35 0.35];
        grid(ax, 'on');
        ax.XMinorGrid = 'on';
        ax.YMinorGrid = 'on';
        hold(ax, 'on');
        xlim(ax, [xMinField.Value xMaxField.Value]);
        ylim(ax, [yMinField.Value yMaxField.Value]);
        plot(ax, [xMinField.Value xMaxField.Value], [0 0], '--w', 'LineWidth', 1.2);
        plot(ax, [0 0], [yMinField.Value yMaxField.Value], '--w', 'LineWidth', 1.2);
        xlabel(ax, 'x', 'Color', 'w');
        ylabel(ax, 'f(x)', 'Color', 'w');
    end

    function drawFunctionCurve()
        xValues = linspace(xMinField.Value, xMaxField.Value, 1500);
        yValues = nan(size(xValues));
        for sampleIndex = 1:numel(xValues)
            value = evaluateScalar(state.f, xValues(sampleIndex));
            if isValidRealScalar(value)
                yValues(sampleIndex) = value;
            end
        end
        plot(ax, xValues, yValues, ...
            'Color', [0.00 0.85 1.00], 'LineWidth', 2.4);
    end

    function responsivePause(seconds)
        if seconds <= 0
            drawnow;
            return;
        end
        timerStart = tic;
        while toc(timerStart) < seconds && ~state.stopRequested
            drawnow;
            pause(min(0.03, max(0.001, seconds - toc(timerStart))));
        end
    end

%% Loading, layout, and validation helpers
    function loadScenario(id)
        scenario = getScenario(id);
        state.currentScenario = id;
        state.customMode = false;
        state.f = scenario.f;
        state.df = scenario.df;
        state.scenarioName = scenario.name;
        state.fText = scenario.fText;
        state.dfText = scenario.dfText;

        scenarioTitle.Text = sprintf('%02d - %s', id, scenario.name);
        functionInputField.Value = scenario.fText;
        x0Field.Value = scenario.x0;
        xMinField.Value = scenario.xRange(1);
        xMaxField.Value = scenario.xRange(2);
        yMinField.Value = scenario.yRange(1);
        yMaxField.Value = scenario.yRange(2);
        calculatorButton.Enable = 'off';
        updateDerivativeDisplay();
    end

    function highlightScenarioButton(id)
        customButton.BackgroundColor = [0.35 0.18 0.50];
        for buttonIndex = 1:numel(scenarioButtons)
            scenarioButtons(buttonIndex).BackgroundColor = [0.18 0.18 0.18];
        end

        if id == 0
            customButton.BackgroundColor = [0.62 0.30 0.82];
        else
            scenarioButtons(id).BackgroundColor = [0.00 0.48 0.68];
        end
    end

    function resetRunDisplay()
        resultLabel1.Text = 'Final x: -';
        resultLabel2.Text = 'Iterations: -';
        resultLabel3.Text = 'Residual: -';
        iterationTable.Data = [];
        liveValueLabel.Text = '$x_n=-\qquad f(x_n)=-\qquad f''(x_n)=-$';
        liveStepLabel.Text = '$x_{n+1}=-$';
        liveMessageLabel.Text = 'Press RUN to start.';
        liveMessageLabel.FontColor = 'w';
        prepareAxes();
        title(ax, state.scenarioName, 'Color', 'w', 'Interpreter', 'none');
    end

    function validateRunInputs()
        if isempty(state.f) || ~isa(state.f, 'function_handle')
            error('NewtonRaphsonApp:NoFunction', ...
                'No valid function is loaded. Apply the custom expressions first.');
        end
        if strcmp(derivativeDrop.Value, 'Analytical') && ...
                (isempty(state.df) || ~isa(state.df, 'function_handle'))
            error('NewtonRaphsonApp:NoDerivative', ...
                'No valid analytical derivative is loaded.');
        end
        if ~isfinite(x0Field.Value)
            error('NewtonRaphsonApp:BadInitialGuess', ...
                'Initial guess x0 must be finite.');
        end
        if ~isfinite(tolField.Value) || tolField.Value <= 0
            error('NewtonRaphsonApp:BadTolerance', ...
                'Tolerance must be a positive finite number.');
        end
        if ~isfinite(maxIterField.Value) || maxIterField.Value < 1 || ...
                abs(maxIterField.Value - round(maxIterField.Value)) > eps(maxIterField.Value)
            error('NewtonRaphsonApp:BadIterationCount', ...
                'Max iterations must be a positive integer.');
        end
        if ~isfinite(pauseField.Value) || pauseField.Value < 0
            error('NewtonRaphsonApp:BadDelay', ...
                'Delay must be a nonnegative finite number.');
        end
        if any(~isfinite([xMinField.Value xMaxField.Value])) || ...
                xMinField.Value >= xMaxField.Value
            error('NewtonRaphsonApp:BadXRange', ...
                'X min must be smaller than X max.');
        end
        if any(~isfinite([yMinField.Value yMaxField.Value])) || ...
                yMinField.Value >= yMaxField.Value
            error('NewtonRaphsonApp:BadYRange', ...
                'Y min must be smaller than Y max.');
        end
    end

    function setBusy(isBusy)
        state.inRun = isBusy;
        if isBusy
            commonEnable = 'off';
            stopButton.Enable = 'on';
        else
            commonEnable = 'on';
            stopButton.Enable = 'off';
            state.stopRequested = false;
        end

        runButton.Enable = commonEnable;
        customButton.Enable = commonEnable;
        derivativeDrop.Enable = commonEnable;
        for buttonIndex = 1:numel(scenarioButtons)
            scenarioButtons(buttonIndex).Enable = commonEnable;
        end
        for controlIndex = 1:numel(busyControls)
            busyControls(controlIndex).Enable = commonEnable;
        end

        if isBusy || ~state.customMode
            calculatorButton.Enable = 'off';
        else
            calculatorButton.Enable = 'on';
        end
    end

    function closeMainWindow(~, ~)
        state.stopRequested = true;
        if ~isempty(builderFig) && isvalid(builderFig)
            delete(builderFig);
        end
        delete(fig);
    end

end

%% Expression editor helpers
function [expression, cursor] = insertExpression(expression, cursor, token)
cursor = clampCursor(cursor, expression);
expression = [expression(1:cursor), token, expression(cursor + 1:end)];
cursor = cursor + length(token);
end

function [expression, cursor] = backspaceExpression(expression, cursor)
cursor = clampCursor(cursor, expression);
if cursor == 0
    return;
end

token = longestTokenEndingAt(expression, cursor);
if isempty(token)
    deleteCount = 1;
else
    deleteCount = length(token);
end

expression(cursor - deleteCount + 1:cursor) = [];
cursor = cursor - deleteCount;
end

function [expression, cursor] = forwardDeleteExpression(expression, cursor)
cursor = clampCursor(cursor, expression);
if cursor >= length(expression)
    return;
end

token = longestTokenStartingAt(expression, cursor + 1);
if isempty(token)
    deleteCount = 1;
else
    deleteCount = length(token);
end

expression(cursor + 1:cursor + deleteCount) = [];
end

function token = longestTokenEndingAt(expression, cursor)
token = '';
tokens = calculatorDeletionTokens();
for index = 1:numel(tokens)
    candidate = tokens{index};
    candidateLength = length(candidate);
    if candidateLength > length(token) && cursor >= candidateLength && ...
            strcmp(expression(cursor - candidateLength + 1:cursor), candidate)
        token = candidate;
    end
end
end

function token = longestTokenStartingAt(expression, startIndex)
token = '';
tokens = calculatorDeletionTokens();
for index = 1:numel(tokens)
    candidate = tokens{index};
    candidateLength = length(candidate);
    lastIndex = startIndex + candidateLength - 1;
    if candidateLength > length(token) && lastIndex <= length(expression) && ...
            strcmp(expression(startIndex:lastIndex), candidate)
        token = candidate;
    end
end
end

function tokens = calculatorDeletionTokens()
tokens = { ...
    'log10(', 'round(', 'floor(', 'sqrt(', 'sinh(', 'cosh(', 'tanh(', ...
    'asin(', 'acos(', 'atan(', 'sign(', 'ceil(', 'mod(', 'min(', 'max(', ...
    'sin(', 'cos(', 'tan(', 'log(', 'exp(', 'abs(', ...
    'exp(1)', 'x^2', 'x^3', '1/x', '10^', '1e-', '00', 'pi'};
end

function displayText = expressionWithCursor(expression, cursor)
cursor = clampCursor(cursor, expression);
displayText = [expression(1:cursor), '|', expression(cursor + 1:end)];
end

function cursor = clampCursor(cursor, expression)
cursor = max(0, min(length(expression), round(cursor)));
end

function matlabExpression = calculatorToMatlab(expression)
matlabExpression = strtrim(expression);
matlabExpression = strrep(matlabExpression, '^', '.^');
matlabExpression = strrep(matlabExpression, '*', '.*');
matlabExpression = strrep(matlabExpression, '/', './');
end

function latexExpression = expressionToLatex(expression)
% Convert calculator notation to a compact, Runtime-safe LaTeX display.
latexExpression = strtrim(expression);
latexExpression = strrep(latexExpression, '.^', '^');
latexExpression = strrep(latexExpression, '.*', '*');
latexExpression = strrep(latexExpression, './', '/');

% Placeholders prevent names such as "cos" from being replaced again after
% "acos" has already been converted.
functionNames = { ...
    'log10', 'asin', 'acos', 'atan', 'sinh', 'cosh', 'tanh', 'sqrt', ...
    'round', 'floor', 'ceil', 'sign', 'abs', 'mod', 'min', 'max', ...
    'exp', 'sin', 'cos', 'tan', 'log'};
placeholders = arrayfun(@(index) sprintf('@@F%d@@', index), ...
    1:numel(functionNames), 'UniformOutput', false);
latexNames = { ...
    '\mathrm{log}_{10}', '\sin^{-1}', '\cos^{-1}', '\tan^{-1}', ...
    '\sinh', '\cosh', '\tanh', '\mathrm{sqrt}', '\mathrm{round}', ...
    '\mathrm{floor}', '\mathrm{ceil}', '\mathrm{sign}', '\mathrm{abs}', ...
    '\mathrm{mod}', '\mathrm{min}', '\mathrm{max}', '\exp', '\sin', ...
    '\cos', '\tan', '\log'};

for replacementIndex = 1:numel(functionNames)
    latexExpression = strrep(latexExpression, ...
        functionNames{replacementIndex}, placeholders{replacementIndex});
end
for replacementIndex = 1:numel(functionNames)
    latexExpression = strrep(latexExpression, ...
        placeholders{replacementIndex}, latexNames{replacementIndex});
end

latexExpression = regexprep(latexExpression, '\^\(([^()]*)\)', '^{$1}');
latexExpression = strrep(latexExpression, 'pi', '\pi');
latexExpression = strrep(latexExpression, '*', '\cdot ');
end

function functionHandle = makeFunction(expression)
if isempty(strtrim(expression))
    error('NewtonRaphsonApp:EmptyExpression', 'The expression cannot be empty.');
end

matlabExpression = calculatorToMatlab(expression);
functionHandle = str2func(['@(x)(' matlabExpression ')']);

% Force MATLAB to parse and execute the expression once. Complex or
% non-finite values are acceptable here because they can be an intentional
% Newton failure case; the run-time engine handles them explicitly.
testValue = functionHandle(0.731);
if ~isnumeric(testValue) && ~islogical(testValue)
    error('NewtonRaphsonApp:NonNumericExpression', ...
        'The expression must return a numeric value.');
end
end

function functionHandle = ensureExpressionIsUsable(expression, label)
if isempty(strtrim(expression))
    error('NewtonRaphsonApp:EmptyExpression', '%s cannot be empty.', label);
end
try
    functionHandle = makeFunction(expression);
catch exception
    error('NewtonRaphsonApp:InvalidExpression', ...
        '%s is invalid: %s', label, exception.message);
end
end

%% Numeric helpers
function value = evaluateScalar(functionHandle, x)
try
    value = functionHandle(x);
    if ~isscalar(value)
        value = NaN;
    end
catch
    value = NaN;
end
end

function valid = isValidRealScalar(value)
valid = isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value);
end

function derivative = numericalDerivative(functionHandle, x)
h = eps^(1/3) * (1 + abs(x));
forward = evaluateScalar(functionHandle, x + h);
backward = evaluateScalar(functionHandle, x - h);
if ~isValidRealScalar(forward) || ~isValidRealScalar(backward)
    derivative = NaN;
else
    derivative = (forward - backward) / (2 * h);
end
end

function position = centeredChildPosition(parentPosition, width, height)
left = parentPosition(1) + max(0, (parentPosition(3) - width) / 2);
bottom = parentPosition(2) + max(0, (parentPosition(4) - height) / 2);
position = [left bottom width height];
end

%% Predefined scenarios
function scenario = getScenario(id)
switch id
    case 1
        scenario = buildScenario('Zero derivative', ...
            @(x) x.^3 - 1, @(x) 3*x.^2, ...
            'x^3-1', '3*x^2', 0, [-2 2], [-3 3]);
    case 2
        scenario = buildScenario('Small derivative / Overshoot', ...
            @(x) x.^3 - 1, @(x) 3*x.^2, ...
            'x^3-1', '3*x^2', 0.01, [-2 5], [-3 10]);
    case 3
        scenario = buildScenario('Periodic cycle: 0 <-> 1', ...
            @(x) x.^3 - 2*x + 2, @(x) 3*x.^2 - 2, ...
            'x^3-2*x+2', '3*x^2-2', 0, [-3 3], [-5 7]);
    case 4
        scenario = buildScenario('No root, residual -> 0', ...
            @(x) 1./(1 + x.^5), @(x) -5*x.^4./(1 + x.^5).^2, ...
            '1/(1+x^5)', '-5*x^4/(1+x^5)^2', 2, [-0.5 20], [-0.5 1.5]);
    case 5
        scenario = buildScenario('No real root', ...
            @(x) x.^2 + 1, @(x) 2*x, ...
            'x^2+1', '2*x', 1, [-3 3], [-1 10]);
    case 6
        scenario = buildScenario('Log domain violation', ...
            @(x) log(x) - 1, @(x) 1./x, ...
            'log(x)-1', '1/x', 10, [0.01 12], [-5 3]);
    case 7
        scenario = buildScenario('SQRT domain violation', ...
            @(x) sqrt(x) - 2, @(x) 1./(2*sqrt(x)), ...
            'sqrt(x)-2', '1/(2*sqrt(x))', 25, [0 30], [-3 5]);
    case 8
        scenario = buildScenario('Root exists but divergence', ...
            @(x) sign(x).*abs(x).^(1/3), @(x) (1/3).*abs(x).^(-2/3), ...
            'sign(x)*abs(x)^(1/3)', '(1/3)*abs(x)^(-2/3)', ...
            0.5, [-20 20], [-4 4]);
    case 9
        scenario = buildScenario('Double root / Slow convergence', ...
            @(x) (x - 1).^2, @(x) 2*(x - 1), ...
            '(x-1)^2', '2*(x-1)', 5, [-1 6], [-2 20]);
    case 10
        scenario = buildScenario('Seventh-order root / Very slow convergence', ...
            @(x) (x - 1).^7, @(x) 7*(x - 1).^6, ...
            '(x-1)^7', '7*(x-1)^6', 3, [-1 4], [-20 150]);
    case 11
        scenario = buildScenario('Multiple roots / Initial-guess dependence', ...
            @(x) x.^3 - x, @(x) 3*x.^2 - 1, ...
            'x^3-x', '3*x^2-1', 0.8, [-2 2], [-3 3]);
    case 12
        scenario = buildScenario('Sine / Small derivative / Large jump', ...
            @(x) sin(x), @(x) cos(x), ...
            'sin(x)', 'cos(x)', 1.55, [-50 10], [-2 2]);
    case 13
        scenario = buildScenario('Exponential / Overflow', ...
            @(x) exp(x) - 1000, @(x) exp(x), ...
            'exp(x)-1000', 'exp(x)', -10, [-15 15], [-1100 5000]);
    case 14
        scenario = buildScenario('Asymptote / Escape to infinity', ...
            @(x) 1./(x - 1), @(x) -1./(x - 1).^2, ...
            '1/(x-1)', '-1/(x-1)^2', 2, [1.1 20], [-1 10]);
    case 15
        scenario = buildScenario('Step function / Zero derivative', ...
            @(x) round(x) - 3, @(x) 0*x, ...
            'round(x)-3', '0*x', 1, [-1 6], [-5 5]);
    case 16
        scenario = buildScenario('Non-differentiable point', ...
            @(x) abs(x) + x.^2, @(x) sign(x) + 2*x, ...
            'abs(x)+x^2', 'sign(x)+2*x', 1, [-2 2], [-1 6]);
    case 17
        scenario = buildScenario('Scaling problem / False convergence', ...
            @(x) 1e-15*(x - 1), @(x) 1e-15 + 0*x, ...
            '1e-15*(x-1)', '1e-15', 100, [-10 110], [-2e-13 2e-13]);
    case 18
        scenario = buildScenario('sin(1/x) / Initial-guess sensitivity', ...
            @(x) sin(1./x), @(x) -cos(1./x)./x.^2, ...
            'sin(1/x)', '-cos(1/x)/x^2', 0.1, [0.02 0.20], [-1.5 1.5]);
    otherwise
        error('NewtonRaphsonApp:UnknownScenario', ...
            'Scenario id must be an integer from 1 through 18.');
end
end

function scenario = buildScenario(name, f, df, fText, dfText, x0, xRange, yRange)
scenario.name = name;
scenario.f = f;
scenario.df = df;
scenario.fText = fText;
scenario.dfText = dfText;
scenario.x0 = x0;
scenario.xRange = xRange;
scenario.yRange = yRange;
end

%% Internal verification
function runInternalSelfTests()
for id = 1:18
    scenario = getScenario(id);
    assert(isa(scenario.f, 'function_handle'));
    assert(isa(scenario.df, 'function_handle'));
    assert(numel(scenario.xRange) == 2 && scenario.xRange(1) < scenario.xRange(2));
    assert(numel(scenario.yRange) == 2 && scenario.yRange(1) < scenario.yRange(2));
end

expression = 'x^2-2';
[expression, cursor] = insertExpression(expression, 3, '+1');
assert(strcmp(expression, 'x^2+1-2'));
assert(cursor == 5);

[expression, cursor] = backspaceExpression('acos(x/2)', 5);
assert(strcmp(expression, 'x/2)'));
assert(cursor == 0);

[expression, cursor] = forwardDeleteExpression('sqrt(x)+1', 0);
assert(strcmp(expression, 'x)+1'));
assert(cursor == 0);

goatFunction = makeFunction( ...
    'x^2*acos(x/2)+acos(1-x^2/2)-x/2*sqrt(4-x^2)-pi/2');
goatDerivative = makeFunction('2*x*acos(x/2)');
root = 1.15872847301812;
assert(abs(goatFunction(root)) < 1e-10);
assert(abs(goatDerivative(root) - 2*root*acos(root/2)) < 1e-12);
assert(strcmp(expressionToLatex('3*x^2'), '3\cdot x^2'));
assert(strcmp(expressionToLatex('acos(x/2)'), '\cos^{-1}(x/2)'));

fprintf('NewtonRaphsonApp self-test passed.\n');
end
