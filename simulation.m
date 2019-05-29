% This demo creates a simulation to test and validate the code. Not all
% functions/steps used in this simulation are needed to infer 3D positions
% from multiple camera angle data. See the file "pipeline.m" for how a
% working pipeline would be constructed.

%% create 2 cameras with ground-truth data about their orientation
clear camGT obj

% Position a pair of cameras
S = 5; % size of room in meters

% create camera objects
numPix = [1280;1024];
alpha = 1.04; % angle-of-view of camera in radians, measured by Jacob

% place the two cameras in opposite corners
C = [0;S;1];
camGT{1} = camClass(C,numPix,alpha);

C = [S;S;1];
camGT{2} = camClass(C,numPix,alpha);
clear C numPix alpha

%% aim both cameras at a target on opposite wall
% this will align the cameras horizontally
T = [S/2;0;S/2];

camGT{1} = aimCam(camGT{1},T);
camGT{2} = aimCam(camGT{2},T);
clear T

% these matrices store the orientation vectors of the cameras as columns
EGT1 = cat(2,camGT{1}.e1,camGT{1}.e2,camGT{1}.e3);
EGT2 = cat(2,camGT{2}.e1,camGT{2}.e2,camGT{2}.e3);

%% rotate the cameras about the optical axis by a random amount
% random orientations will give a more robust test of functionality

phi = 2*pi*rand;
camGT{1} = spinCam(camGT{1},phi);

phi = 2*pi*rand;
camGT{2} = spinCam(camGT{2},phi);
clear phi

% update the orientation vectors
EGT1 = cat(2,camGT{1}.e1,camGT{1}.e2,camGT{1}.e3);
EGT2 = cat(2,camGT{2}.e1,camGT{2}.e2,camGT{2}.e3);

%% create 2 test objects
% check that they are in view of both cameras
clear Rtrain
for o = 1:2
    Rtrain(:,o) = [S*rand;rand;S*rand];        
end
clear o test u theta

%% image the two objects on ground truth cameras to get image coordinates

clear Xtrain Ytrain
for o = 1:2
    for c = 1:2
        [Xtrain(o,c),Ytrain(o,c)] = imageObject(camGT{c},Rtrain(:,o));
    end
end
clear o c

%% create new cameras at same locations and learn their orientations from the images
numPix = [1280;1024];
alpha = 1.04; % angle-of-view of camera in radians, measured by Jacob
C = [0;S;1];
cam{1} = camClass(C,numPix,alpha);
C = [S;S;1];
cam{2} = camClass(C,numPix,alpha);
clear C numPix alpha

%% to orient a camera we need 2 reference objects, with X,Y,R for each 
% learn the cameras orientations from the reference images
for c = 1:2
    cam{c} = trainCam(cam{c},Xtrain(:,c),Ytrain(:,c),Rtrain);
end
clear c

% use these to compare GT and learned results
E1 = cat(2,cam{1}.e1,cam{1}.e2,cam{1}.e3);
E2 = cat(2,cam{2}.e1,cam{2}.e2,cam{2}.e3);

%% Use the aligned cameras to find the location of the third object

% create a new object (test that it isn't too far off axis to be out of view)
Rtest = [S*rand;rand;S*rand];
    
% image the 3rd object with both trained cameras
clear Xtest Ytest
for c = 1:2
    [Xtest(1,c),Ytest(1,c)] = imageObject(cam{c},Rtest);
end
clear c

% construct the image vector for each camera
[Rinf,deltaRinf] = inferPosition(cam,Xtest,Ytest) % here use the cell array of all cameras as input
RGT = Rtest




%% plot section ************************************************************
% make a quick and dirty 3D representation of the vectors involved

fig1 = figure;
ax1 = axes(fig1,'outerposition',[0,0,1,1]);
O = [0;0;0];
L = cat(2,O,camGT{1}.C);
plot3(ax1,L(1,:),L(2,:),L(3,:),'r','linewidth',2)
hold(ax1,'on')
L = cat(2,O,camGT{2}.C);
plot3(ax1,L(1,:),L(2,:),L(3,:),'r','linewidth',2)
L = cat(2,camGT{1}.C,camGT{1}.C+10*camGT{1}.e1);
plot3(ax1,L(1,:),L(2,:),L(3,:),'k--','linewidth',1)
L = cat(2,camGT{2}.C,camGT{2}.C+10*camGT{2}.e1);
plot3(ax1,L(1,:),L(2,:),L(3,:),'k--','linewidth',1)
L = cat(2,camGT{1}.C,camGT{1}.C+camGT{1}.e1);
plot3(ax1,L(1,:),L(2,:),L(3,:),'k','linewidth',2)
L = cat(2,camGT{2}.C,camGT{2}.C+camGT{2}.e1);
plot3(ax1,L(1,:),L(2,:),L(3,:),'k','linewidth',2)
L = cat(2,camGT{1}.C,camGT{1}.C+camGT{1}.e2);
plot3(ax1,L(1,:),L(2,:),L(3,:),'b','linewidth',2)
L = cat(2,camGT{2}.C,camGT{2}.C+camGT{2}.e2);
plot3(ax1,L(1,:),L(2,:),L(3,:),'b','linewidth',2)
L = cat(2,camGT{1}.C,camGT{1}.C+camGT{1}.e3);
plot3(ax1,L(1,:),L(2,:),L(3,:),'g','linewidth',2)
L = cat(2,camGT{2}.C,camGT{2}.C+camGT{2}.e3);
plot3(ax1,L(1,:),L(2,:),L(3,:),'g','linewidth',2)
L = Rtrain;
plot3(ax1,L(1,:),L(2,:),L(3,:),'mo','linewidth',2)
L = Rtest;
plot3(ax1,L(1,:),L(2,:),L(3,:),'co','linewidth',2)

axis(ax1,'image')
xlim(ax1,[-1 S+1])
ylim(ax1,[-1 S+1])
zlim(ax1,[0 S])
xlabel(ax1,'x')
ylabel(ax1,'y')
zlabel(ax1,'z')
box(ax1,'on')
ax1.BoxStyle = 'full';








