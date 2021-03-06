% Init ROS ----------------------------------------------------------------
clear all;
close all;
rosshutdown;
rosinit;

left_marker_sub = rossubscriber('/saf/vision/left/markers', 'irob_msgs/MarkerArray');
right_marker_sub = rossubscriber('/saf/vision/right/markers', 'irob_msgs/MarkerArray');

disparity_sub = rossubscriber('/saf/stereo/disparity', 'stereo_msgs/DisparityImage');
%disparity_sub = rossubscriber(...
%'/saf/stereo/disparity', 'stereo_msgs/DisparityImage');


left_cam_info_sub = rossubscriber('/saf/stereo/left/camera_info', 'sensor_msgs/CameraInfo');
right_cam_info_sub = rossubscriber('/saf/stereo/right/camera_info', 'sensor_msgs/CameraInfo');

target_pub = rospublisher('/saf/vision/target', 'irob_msgs/Environment');

%retract_observation_pub = rospublisher('/saf/vision/retract_observation', 'irob_msgs/FloatArray');

pause(2) % Wait to ensure publisher is registered

disp('Waiting for camera info...');

%left_cam_info = receive(left_cam_info_sub);
%right_cam_info = receive(right_cam_info_sub);

left_cam_info = left_cam_info_sub.LatestMessage;
right_cam_info = right_cam_info_sub.LatestMessage;

disp('Camera info received:');
P_l = reshape(left_cam_info.P, 4, 3)
P_r = reshape(right_cam_info.P, 4, 3)

% -------------------------------------------------------------------------

load('pnp_phantom_model.mat');

offset = [0, 0, 0.0];
marker_ids = [1, 2, 3, 4];

while true
    
    valid = false;
    
    left_markers_msg = left_marker_sub.LatestMessage;
    right_markers_msg = right_marker_sub.LatestMessage;
    %disparity_msg = disparity_sub.LatestMessage;
    
    if (and(size(left_markers_msg) > 0, size(right_markers_msg) > 0))
        
        corners_L = zeros(0);
        corners_R = zeros(0);
        model_3d_corners_found = zeros(0);
        
        found = 0;
        
        for i = 1:size(marker_ids, 2)
            [im_coord_L, marker_left_corners, left_found] = getMarkerCoordinates(left_markers_msg,marker_ids(i));
            [im_coord_R, marker_right_corners, right_found] = getMarkerCoordinates(right_markers_msg,marker_ids(i));
            
            if and(left_found, right_found)
                corners_L= [corners_L; im_coord_L];
                corners_R = [corners_R; im_coord_R];
                
                model_3d_corners_found = [model_3d_corners_found; model_3d_corners(i, :)];
                
                found = found + 1;
            end
        end
        
        % [corners_L, lines_L, im_foreground_L] = detect_green_plate(IL);
        % [corners_R, lines_R, im_foreground_R] = detect_green_plate(IR);
        
        %disparityMap = readImage(disparity_msg.Image);
        
        %imshow([IL, IR])
        
        %         corners_L_int = uint32(round(corners_L));
        %
        %         corners_R = zeros(4,2);
        %
        %         for i = 1:size(corners_L_int, 1)
        %             corners_R(i,:) = [corners_L(i,1) - disparityMap(corners_L_int(i,2), corners_L_int(i,1)), corners_L(i,2)];
        %         end
        
        valid = false;
        
        if found > 2
            
            
            % Triangulate corners
            corners_3d = triangulate(uint32(corners_L), uint32(corners_R), ...
                P_l, P_r) * 1000.0; % m -> mm
            
            
            % Register phantom
            
            [R, t] = rigid_transform_3D(model_3d_corners_found, corners_3d);
            
            
            %offset_t = (R*offset');
            %offset_t = offset_t';
            
            model_3d_transf = (R*model_3d_corners_found') + repmat(t, 1, size(model_3d_corners_found,1));
            model_3d_transf = model_3d_transf';
            
            offset_t = (R*offset');
            offset_t = offset_t';
            
            err = model_3d_transf - corners_3d;
            err = err .* err;
            err = sum(err(:));
            rmse = sqrt(err/size(model_3d_corners,1))
            found
            
            plot = false;
            if plot
                subplot(1,2,1);
                scatter3(model_3d_corners_found(:,1), model_3d_corners_found(:,2), model_3d_corners_found(:,3), 'MarkerEdgeColor','b',...
                    'MarkerFaceColor','b')
                hold on
                scatter3(corners_3d(:,1), corners_3d(:,2), corners_3d(:,3), 'MarkerEdgeColor','r',...
                    'MarkerFaceColor','r')
                hold off
                
                subplot(1,2,2);
                scatter3(model_3d_transf(:,1), model_3d_transf(:,2), model_3d_transf(:,3), 'MarkerEdgeColor','b',...
                    'MarkerFaceColor','b')
                hold on
                scatter3(corners_3d(:,1), corners_3d(:,2), corners_3d(:,3), 'MarkerEdgeColor','r',...
                    'MarkerFaceColor','r')
                hold on
            end
            
            
            
            if rmse < 4
                valid = true;
                % Transform environment
                model_3d_targets_transformed = (R*model_3d_targets') + repmat(t, 1, size(model_3d_targets,1));
                model_3d_targets_transformed = model_3d_targets_transformed';
                if plot
                    scatter3(model_3d_targets_transformed(:,1), model_3d_targets_transformed(:,2), model_3d_targets_transformed(:,3), 'MarkerEdgeColor','b', ...
                        'MarkerFaceColor','b')
                    hold off
                end
                
                model_3d_approaches_transformed = (R*model_3d_approaches') + repmat(t, 1, size(model_3d_approaches,1));
                model_3d_approaches_transformed = model_3d_approaches_transformed';
                
                model_3d_grasps_transformed = (R*model_3d_grasps') + repmat(t, 1, size(model_3d_grasps,1));
                model_3d_grasps_transformed = model_3d_grasps_transformed';
                
                % Send ROS msg
                disp('Vision valid')
                
                tgt_msg = rosmessage(target_pub);
                tgt_msg.Valid = 1;
                
                tgt_msg.Objects = arrayfun(@(~) rosmessage('irob_msgs/GraspObject'), ...
                    zeros(1,size(model_3d_targets,1)));
                
                for i = 1:size(model_3d_targets,1)
                    
                    tgt_msg.Objects(i).Id = i;
                    
                    tgt_msg.Objects(i).Position.X = model_3d_targets_transformed(i,1) + offset_t(1);
                    tgt_msg.Objects(i).Position.Y = model_3d_targets_transformed(i,2) + offset_t(2);
                    tgt_msg.Objects(i).Position.Z = model_3d_targets_transformed(i,3) + offset_t(3);
                    
                    tgt_msg.Objects(i).GraspPosition.X = model_3d_grasps_transformed(i,1) + offset_t(1);
                    tgt_msg.Objects(i).GraspPosition.Y = model_3d_grasps_transformed(i,2) + offset_t(2);
                    tgt_msg.Objects(i).GraspPosition.Z = model_3d_grasps_transformed(i,3) + offset_t(3);
                    
                    tgt_msg.Objects(i).ApproachPosition.X = model_3d_approaches_transformed(i,1) + offset_t(1);
                    tgt_msg.Objects(i).ApproachPosition.Y = model_3d_approaches_transformed(i,2) + offset_t(2);
                    tgt_msg.Objects(i).ApproachPosition.Z = model_3d_approaches_transformed(i,3) + offset_t(3);
                    
                    tgt_msg.Objects(i).GraspDiameter= target_d;
                    
                    tgt_msg.TfPhantom.Translation.X = t(1);
                    tgt_msg.TfPhantom.Translation.Y = t(2);
                    tgt_msg.TfPhantom.Translation.Z = t(3);
                    
                    R_quat = rotm2quat(R);
                    
                    tgt_msg.TfPhantom.Rotation.X = R_quat(2);
                    tgt_msg.TfPhantom.Rotation.Y = R_quat(3);
                    tgt_msg.TfPhantom.Rotation.Z = R_quat(4);
                    tgt_msg.TfPhantom.Rotation.W = R_quat(1);
                    
                    
                end
                send(target_pub,tgt_msg);
                
            end
            
        end
    end
    
    % If error occured, send ERR msg in ROS
    if not(valid)
        disp('Vision invalid')
        tgt_msg = rosmessage(target_pub);
        tgt_msg.Valid = 2;
        send(target_pub,tgt_msg);
    end
    pause(1.0);
end
% w = waitforbuttonpress;


rosshutdown;
