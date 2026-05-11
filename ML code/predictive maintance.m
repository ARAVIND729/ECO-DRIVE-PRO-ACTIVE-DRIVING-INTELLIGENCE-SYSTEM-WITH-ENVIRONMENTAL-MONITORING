classdef SensorMonitorApp < matlab.apps.AppBase

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

        voltHistory = []
        currHistory = []

        lastAlertTime datetime = datetime(0,0,0)
        alertCooldown = 2 % minutes
    end

    %------------------------------------------------------
    % INITIALIZATION
    %------------------------------------------------------
    methods (Access = private)

        function startupFcn(app)
            app.timerObj = timer( ...
                'ExecutionMode', 'fixedRate', ...
                'Period', 30, ...
                'TimerFcn', @(~,~) readAndCheck(app));
        end


        %------------------------------------------------------
        % MAIN MAINTENANCE FUNCTION
        %------------------------------------------------------
        function readAndCheck(app)

            try
                % Read all maintenance-related fields
                data = thingSpeakRead(app.channelID, ...
                    'Fields', [2 3 4 5 6 7], ...
                    'NumPoints', 1, ...
                    'ReadKey', app.readAPI);

                gas  = data(1);
                temp = data(2);
                hum  = data(3);
                volt = data(4);
                curr = data(5);
                ir   = data(6);

                fprintf("Gas: %.2f | Temp: %.2f | Hum: %.2f | Volt: %.2f | Curr: %.2f | IR: %.2f\n", ...
                        gas, temp, hum, volt, curr, ir);

                % ---------------- HISTORY STORAGE ----------------
                app.voltHistory = [app.voltHistory; volt];
                app.currHistory = [app.currHistory; curr];

                if length(app.voltHistory) > 30
                    app.voltHistory(1) = [];
                    app.currHistory(1) = [];
                end

                % ---------------- ANALYSIS ----------------
                status = "NORMAL";
                message = "";

                % --------- 1. BATTERY DEGRADATION ---------
                if length(app.voltHistory) >= 10
                    voltMean = mean(app.voltHistory);
                    currStd  = std(app.currHistory);

                    x = (1:length(app.voltHistory))';
                    p = polyfit(x, app.voltHistory, 1);
                    slope = p(1);

                    if slope < -0.02
                        status = "BATTERY WARNING";
                        message = "Gradual battery voltage decay detected.";
                    end

                    if voltMean < 10 || slope < -0.05
                        status = "BATTERY FAILURE RISK";
                        message = "Severe battery degradation detected.";
                    end

                    if currStd > 0.3
                        status = "ELECTRICAL INSTABILITY";
                        message = "Current fluctuations detected.";
                    end
                end

                % --------- 2. OVERHEATING ---------
                if temp > 60
                    status = "OVERHEATING";
                    message = "High temperature detected. Check motor and cooling.";
                end

                % --------- 3. GAS LEAKAGE ---------
                if gas > 500
                    status = "GAS HAZARD";
                    message = "Possible gas leakage detected.";
                end

                % --------- 4. OBSTACLE DETECTION ---------
                if ir == 0
                    status = "OBSTACLE DETECTED";
                    message = "Vehicle too close to object.";
                end

                % --------- 5. LOW HUMIDITY OR HIGH HUMIDITY ---------
                if hum > 90
                    status = "HIGH HUMIDITY WARNING";
                    message = "Excess moisture may affect electronics.";
                end

                fprintf("Maintenance Status: %s\n", status);

                % ---------------- ALERT CONTROL ----------------
                if status ~= "NORMAL"

                    nowTime = datetime('now');

                    if minutes(nowTime - app.lastAlertTime) > app.alertCooldown

                        app.lastAlertTime = nowTime;

                        uialert(app.UIFigure, ...
                            sprintf("VEHICLE MAINTENANCE ALERT\n\nStatus: %s\n\nGas: %.2f\nTemp: %.2f\nHumidity: %.2f\nVoltage: %.2f\nCurrent: %.2f\nIR: %.2f\n\n%s", ...
                            status, gas, temp, hum, volt, curr, ir, message), ...
                            'Vehicle Maintenance System');

                        fprintf("ALERT: %s\n", status);
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
            if strcmp(app.timerObj.Running, 'off')
                start(app.timerObj);
                disp("Vehicle Maintenance Monitoring Started");
            end
        end

        function StopButtonPushed(app, ~)
            if strcmp(app.timerObj.Running, 'on')
                stop(app.timerObj);
                disp("Vehicle Maintenance Monitoring Stopped");
            end
        end
    end


    %------------------------------------------------------
    % APP CREATION
    %------------------------------------------------------
    methods (Access = public)

        function app = SensorMonitorApp
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
                'Position',[100 100 360 250], ...
                'Name','Vehicle Maintenance Monitoring System');

            app.StartButton = uibutton(app.UIFigure, 'push');
            app.StartButton.Position = [80 150 200 40];
            app.StartButton.Text = 'Start Maintenance Monitoring';
            app.StartButton.ButtonPushedFcn = ...
                @(btn,event) StartButtonPushed(app,event);

            app.StopButton = uibutton(app.UIFigure, 'push');
            app.StopButton.Position = [80 90 200 40];
            app.StopButton.Text = 'Stop Monitoring';
            app.StopButton.ButtonPushedFcn = ...
                @(btn,event) StopButtonPushed(app,event);
        end
    end
end
