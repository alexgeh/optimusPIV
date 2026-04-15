% 1. Connect
laser = DM40Control('COM9');

% 2. Open Dashboard (It will open a tall, organized window)
dash = LaserDashboard(laser);
laser.Verbose = false; % Only let important messages through command line

% 3. Try opening the shutter, you'll see the dashboard instantly react!
laser.openShutter(1);
laser.closeShutter(1);

%% Clean disconnection from laser:
delete(dash);
delete(laser);
clear dash laser;
