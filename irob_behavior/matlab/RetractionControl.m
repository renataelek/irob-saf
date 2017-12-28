
classdef RetractionControl < handle
    
    properties (Constant)
        FUZZY = 1;
        HMM = 2;
        STRAIGHT = 3;
    end
    
    properties
        
        ctrl_srv;
        fis;
        method;
        
        % States
        angles;
        tensions;
        angles_HMM;
        tensions_HMM;
        visible_sizes;
        
        % Proportional crtl
        p;
        angle_des;
        tension_des;
        
    end
    
    methods
        
        % Init ------------------------------------------------------------
        function obj = RetractionControl
            
            rosshutdown;
            rosinit;
            
            obj.angles = double(zeros(0));
            obj.tensions = double(zeros(0));
            obj.angles_HMM = double(zeros(0));
            obj.tensions_HMM = double(zeros(0));
            obj.visible_sizes = double(zeros(0));
            
            obj.p = 10.0;
            obj.angle_des = 90.0;
            obj.tension_des = 170.0;
            
            
            obj.method = RetractionControl.FUZZY;
            
            obj.fis = readfis('retract_2.fis');
            
            obj.ctrl_srv = rossvcserver(...
                '/ias/behavior/retract_ctrl_srv',...
                'irob_msgs/GetControlVariables', @obj.getControlVariables)
            
            pause(2) % Wait to ensure publisher is registered
            
            
        end
        
        
        % Callback for crtl query -----------------------------------------
        function response = getControlVariables(...
                obj,server,reqmsg,defaultrespmsg)
            
            response = defaultrespmsg;
            
            % Build the response message here
            % [angle, tension, visible_size]
            
            if (isnan(reqmsg.Input(1)) | isnan(reqmsg.Input(2)) |isnan(reqmsg.Input(3)))
                response.Output(1) = -5.0;   % y
                response.Output(2) = 5.0;   % z
            else
                obj.angles =  [obj.angles reqmsg.Input(1)];
                obj.tensions =   [obj.tensions reqmsg.Input(2)];
                obj.visible_sizes =  [obj.visible_sizes reqmsg.Input(3)];
                
                if obj.angles(end) > 190
                       obj.angles(end) = 190;
                end
                if obj.angles(end) <1
                       obj.angles(end) = 1;
                end
                
                if obj.tensions(end) > 190
                       obj.tensions(end) = 190;
                end
                if obj.tensions(end) <1 
                       obj.tensions(end) = 1;
                end
                
                if obj.method == RetractionControl.FUZZY
                    
                    [ y, z ] = retractonCtrlFuzzy(obj.fis, ...
                        obj.angles(end), ...
                        obj.tensions(end));
                    
                elseif obj.method == RetractionControl.HMM
                    
                    [ y, z, angle_HMM, tension_HMM ] = retractonCtrlHMM( obj.angles, obj.tensions, ...
                        obj.visible_sizes, obj.p, obj.angle_des, obj.tension_des );
                    
                    obj.angles_HMM =  [obj.angles_HMM angle_HMM];
                    obj.tensions_HMM =   [obj.tensions_HMM tension_HMM];
                    
                   % obj.angles
                   % obj.tensions
                   % obj.angles_HMM
                    %obj.tensions_HMM
                    
                elseif obj.method == RetractionControl.STRAIGHT
                    
                    [ y, z ] = retractonCtrlProportional(obj.p, obj.angle_des, ...
                        obj.tension_des, obj.angles(end), obj.tensions(end));
                    
                end
                
                response.Output(1) = y;   % y
                response.Output(2) = z;   % z
            end
            
        end
        
    end
end


