
classdef MEMSMonitorApp < matlab.apps.AppBase

    % UI Components
    properties (Access = public)
        UIFigure matlab.ui.Figure
        StartButton matlab.ui.control.Button
        StopButton matlab.ui.control.Button
    end

    % App properties
    properties (Access = private)
        timerObj
        channelID = 32522;
        readAPI = '2528EIVI90ICY8';

        baseline = NaN
        lastAlertTime = datetime(0,0,0)
        alertCooldown = 2 % minutes
    end

    %------------------------------------------------------
    % INITIALIZATION
    %------------------------------------------------------
    methods (Access = private)

        function startupFcn(app)
            app.timerObj = timer( ...
                'ExecutionMode','fixedRate', ...
                'Period',30, ...
                'TimerFcn',@(~,~)readAndCheck(app));
        end


        %------------------------------------------------------
        % MAIN MONITOR FUNCTION
        %------------------------------------------------------
        function readAndCheck(app)

            try
                % Read last 15 MEMS samples
                data = thingSpeakRead(app.channelID, ...
                    'Fields',1, ...
                    'NumPoints',15, ...
                    'ReadKey',app.readAPI);

                data = data(~isnan(data));

                if numel(data) < 5
                    disp("Not enough MEMS samples");
                    return;
                end

                % ---------------- BASELINE LEARNING ----------------
                if isnan(app.baseline)
                    app.baseline = median(data);
                    fprintf("Baseline Learned: %.2f\n", app.baseline);
                    return;
                end

                % Slowly adapt baseline
                newBase = median(data);
                app.baseline = 0.9*app.baseline + 0.1*newBase;

                % ---------------- ANALYSIS ----------------
                current = data(end);
                deviation = abs(current - app.baseline);
                peakDeviation = max(abs(data - app.baseline));

                fprintf("Current: %.2f | Baseline: %.2f | Peak Dev: %.2f\n", ...
                        current, app.baseline, peakDeviation);

                % ---------------- EVENT CLASSIFICATION ----------------
                event = "NORMAL";
                message = "";
                severity = "";

                if peakDeviation > 900
                    event = "CRASH DETECTED";
                    severity = "HIGH SEVERITY IMPACT";
                    message = "Possible vehicle collision.\nImmediate inspection recommended.";
                elseif peakDeviation > 400
                    event = "POTHOLE / HARD SHOCK";
                    severity = "MEDIUM SEVERITY IMPACT";
                    message = "Severe road surface impact detected.\nCheck suspension and chassis.";
                elseif peakDeviation > 200
                    event = "HARSH BRAKING / ACCELERATION";
                    severity = "LOW SEVERITY EVENT";
                    message = "Aggressive driving behavior detected.\nMonitor driving pattern.";
                end

                % ---------------- ALERT CONTROL ----------------
                if event ~= "NORMAL"
                    nowTime = datetime('now');
                    if minutes(nowTime - app.lastAlertTime) > app.alertCooldown

                        app.lastAlertTime = nowTime;

                        uialert(app.UIFigure, ...
                            sprintf("VEHICLE EVENT ALERT\n\nEvent: %s\nSeverity: %s\nPeak Deviation: %.2f\n\n%s", ...
                            event, severity, peakDeviation, message), ...
                            'Crash Detection System');

                        fprintf("ALERT: %s | Severity: %s\n", event, severity);
                    end
                end

            catch ME
                disp("ThingSpeak Read Error:");
                disp(ME.message);
            end
        end
    end


    %------------------------------------------------------
    % BUTTON CALLBACKS
    %------------------------------------------------------
    methods (Access = private)

        function StartButtonPushed(app, ~)
            if strcmp(app.timerObj.Running,'off')
                start(app.timerObj);
                disp("Crash Detection Monitoring Started");
            end
        end

        function StopButtonPushed(app, ~)
            if strcmp(app.timerObj.Running,'on')
                stop(app.timerObj);
                disp("Crash Detection Monitoring Stopped");
            end
        end
    end


    %------------------------------------------------------
    % APP CREATION
    %------------------------------------------------------
    methods (Access = public)

        function app = MEMSMonitorApp
            createComponents(app)
            startupFcn(app)
        end

        function delete(app)
            if ~isempty(app.timerObj) && isvalid(app.timerObj)
                stop(app.timerObj);
                delete(app.timerObj);
            end
        end
    end


    %------------------------------------------------------
    % UI
    %------------------------------------------------------
    methods (Access = private)

        function createComponents(app)

            app.UIFigure = uifigure( ...
                'Position',[100 100 340 240], ...
                'Name','Vehicle MEMS Crash Detection System');

            app.StartButton = uibutton(app.UIFigure,'push');
            app.StartButton.Position = [70 140 200 40];
            app.StartButton.Text = 'Start Crash Monitoring';
            app.StartButton.ButtonPushedFcn = @(~,~)StartButtonPushed(app);

            app.StopButton = uibutton(app.UIFigure,'push');
            app.StopButton.Position = [70 80 200 40];
            app.StopButton.Text = 'Stop Monitoring';
            app.StopButton.ButtonPushedFcn = @(~,~)StopButtonPushed(app);
        end
    end
end
