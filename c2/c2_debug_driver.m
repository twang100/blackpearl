%%
addpath('../environment/');
addpath('../flight/');
load('pirate_boat.mat');
pirate_ref = double(map);
clear map;

% parametrs
p8_speed = 1/10; % pixel/sec
h60_speed = 1/30; % pixel/sec
pirate_speed = 1/120; % pixel/sec
launch_pos = [577 406];
search_waypoints = [297 628; 405 323 ];
search_waypoints = search_waypoints';
p8_pos = launch_pos;
h60_pos = launch_pos;
p8_waypoint = search_waypoints(1, :);
h60_waypoint = p8_waypoint;
c2_output.p8_waypoint = p8_waypoint;
c2_output.h60_waypoint = h60_waypoint;

dt = 100; % time step
for t = 0:dt:10000
    % Generate environment map
    [global_map, eo_map, boarded, pirate_pos] = Environment(t);
    if(boarded == 1)
        figure(999);
        text(220, 230, 'GAME OVER!', 'color', 'r', 'FontSize', 50);
        break;
    end

%    pirate_pos = [0 0];

    % Flight
    [flight_output] = flight_main(t, c2_output);
    p8_pos = flight_output.p8_position;
    h60_pos = flight_output.h60_position;

    % RADAR
    p8_grid = round(p8_pos);
    origin = [p8_grid(1)-100 p8_grid(2)-100]-1;
    radar_output = c2_radar_main(t, dt, global_map, p8_pos);

    % EO
    % Generate EO image, take the 50 x 50 from eo_map
    h60_grid = round(h60_pos);
    eo_image = eo_map(h60_grid(2)-25:h60_grid(2)+25, h60_grid(1)-25:h60_grid(1)+25);
    score = corr2(eo_image, pirate_ref);
    if(score > 0.99)
        eo_output.valid_target = 1;
    else
        eo_output.valid_target = 0;
    end

    % C2
     c2_output = c2_main(t, dt, radar_output, eo_output, flight_output);
     p8_waypoint = c2_output.p8_waypoint;
     h60_waypoint = c2_output.h60_waypoint;

    % Display scenario
    figure(999);
    imshow(global_map);
    ylim([200 600]);
    hold on,
    plot(pirate_pos(1), pirate_pos(2), 'rs', ...
        p8_pos(1), p8_pos(2), 'bs', ...
        h60_pos(1), h60_pos(2), 'go');
    for k = 1:length(radar_output)
        plot(radar_output(k).history(:, 1), radar_output(k).history(:, 2), 'm-');
        plot(radar_output(k).pos(1), radar_output(k).pos(2), 'r*');
        text(radar_output(k).pos(1), radar_output(k).pos(2), num2str(radar_output(k).id));
    end
%     legend('Pirate', 'P8', 'H60', 'Radar Track', 'Current Position');

    plot(search_waypoints(:, 1), search_waypoints(:, 2), 'gs-');
    rect = [p8_pos(1)-100 p8_pos(2)-100, 200, 200];
    rectangle('Position', rect, 'EdgeColor', 'b');
    text(20, 580, sprintf('t = %.0f', t), 'color', 'r', 'FontSize', 16, 'BackgroundColor', 'w');
    if(eo_output.valid_target == 1)
        text(220, 230, 'PIRATE INTERCEPTED!', 'color', 'g', 'FontSize', 50);
        break;
    end
    axis off;
    hold off;

    figure(9);
    imshow(eo_image);
    set(gcf, 'Name', 'EO Image');
    pause(0.01);
end
