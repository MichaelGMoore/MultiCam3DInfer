% Example pipeline for 3D position inference from multiple camera angles

%% Step 1 create the cameras 
N = 2; % replace with number of cameras

% do this for each camera (1-N):
C = [Cx,Cy,Cz]; % replace Cx,Cy, and Cz with camera position in lab frame 
numPix = [1280;1024]; % [horiz,vert] format (edit to match camera)
alpha = 1.04; % horizontal angle-of-view of camera in radians (edit to match camera)
cam{1} = camClass(C,numPix,alpha); % replace c with camera number

% --- cut and paste lines 6-10 below for each additional camera ----




% results in a cell array of camClass objects

%% train each camera with two reference objects
R = []; % [3 x 2] array of object positions in lab coordinates
         % row runs over (x,y,z) components
         % col runs over reference objects

X = []; % [2 x N] array of X values in images (pixels, left-to-right)
        % row runs over reference objects, col runs over cameras
Y = []; % [2 x N] array Y values in images (pixels, top-to-bottom)
        % row runs over reference objects, col runs over cameras

for c = 1:N
    trainCam(cam{c},X(:,c),Y(:,c),R);
end
clear c

%% For any object imaged in all cameras, infer 3D position

X = []; % [1 x N] array of X values in images (pixels, left-to-right)
        % col runs over cameras
Y = []; % [1 x N] array of Y values in images (pixels, top-to-bottom)
        % col runs over cameras            
[Rinf,deltaRinf] = inferPosition(cam,X,Y); % returns position of object in 3D





