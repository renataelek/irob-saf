function [ y, z ] = retractonCtrlHMM( angles, tensions, visible_sizes )

% Parameters

N = 19;
N_E = 190;

start_angle = 0;
end_angle = 180;

start_tension = 0;
end_tension = 180;

transition_slope_angle = 40;
transition_max_d_angle = 30;

transition_slope_tension = 40;
transition_max_d_tension = 30;

emission_sigma_angle = 30;
emission_sigma_tension = 30;

% States

STATES_angle = start_angle:((end_angle - start_angle) / (N-1)):end_angle;

STATES_tension = start_tension:((end_tension - start_tension) / (N-1)):end_tension;
 
% Transitions - Angle

T_angle = double(zeros(N,N));

for i = 1:N
    a1 = STATES(i) - (transition_max_d_angle + transition_slope_angle);
    b1 = STATES(i) - transition_max_d_angle;
    c1 = STATES(i) - (transition_max_d_angle - transition_slope_angle);
    
    a2 = STATES(i) + (transition_max_d_angle - transition_slope_angle);
    b2 = STATES(i) + transition_max_d_angle;
    c2 = STATES(i) + (transition_max_d_angle + transition_slope_angle);
    
    
    y = trimf(STATES_angle,[a1 b1 c1]) + trimf(STATES_angle,[a2 b2 c2]);
    
    %T(i,:) = y / sum(y);
    T_angle(i,:) = y / 2;
    %plot(STATES,T(i,:)); hold on;
end

% Transitions -Tension

T_tension = double(zeros(N,N));

for i = 1:N
    a1 = STATES(i) - (transition_max_d_tension + transition_slope_tension);
    b1 = STATES(i) - transition_max_d_tension;
    c1 = STATES(i) - (transition_max_d_tension - transition_slope_tension);
    
    a2 = STATES(i) + (transition_max_d_tension - transition_slope_tension);
    b2 = STATES(i) + transition_max_d_tension;
    c2 = STATES(i) + (transition_max_d_tension + transition_slope_tension);
    
    
    y = trimf(STATES_tension,[a1 b1 c1]) + trimf(STATES_tension,[a2 b2 c2]);
    
    %T(i,:) = y / sum(y);
    T_tension(i,:) = y / 2;
    %plot(STATES,T(i,:)); hold on;
end

% Emissions - Angle

EMISSIONS_angle = start_angle:((end_angle - start_angle) / (N_E-1)):end_angle;

E_angle = double(zeros(N,N_E));

for i = 1:N
    
    E_angle(i, :) = gaussmf(EMISSIONS_angle,[emission_sigma_angle STATES_angle(i)]);
    %plot(EMISSIONS,E(i,:)); hold on;
end

% Emissions - Tension

EMISSIONS_tension = start_tension:((end_tension - start_tension) / (N_E-1)):end_tension;

E_tension = double(zeros(N,N_E));

for i = 1:N
    
    E_tension(i, :) = gaussmf(EMISSIONS_tension,[emission_sigms_tension STATES_tension(i)]);
    %plot(EMISSIONS,E(i,:)); hold on;
end


% Calculate hidden states

%seq = 1:30:190;

likelystates_angle = hmmviterbi(angles, T_angle, E_angle);

likelystates_tension = hmmviterbi(tensions, T_tension, E_tension);

%plot(likelystates)

%y = output(1)
%z = output(2)



