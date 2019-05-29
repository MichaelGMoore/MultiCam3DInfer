function [Rinf,deltaRinf] = inferPosition(cam,X,Y)
% camData is a cell array of N camera objects
% X,Y are [N x 1] arrays representing the coordinates of an object as seen
%   by each camera
% X runs from 1 to numPix(1), left-to-right
% Y runs from 1 to numPix(2), to-to-bottom

N = length(cam);
assert(isequal(length(X),N),'must provide X value for each camera')
assert(isequal(length(Y),N),'must provide Y value for each camera')

clear u
for c = 1:N
    X(c) = 2*X(c)/cam{c}.numPix(1)-1;
    Y(c) = 2*Y(c)/cam{c}.numPix(1)-cam{c}.numPix(2)/cam{c}.numPix(1);
    theta = atan(sqrt(X(c)^2+Y(c)^2)*tan(cam{c}.alpha/2));
    phi = atan2(Y(c),X(c));
    u{c}(:,1) = cam{c}.e1*cos(theta) + cam{c}.e2*sin(theta)*cos(phi)...
        + cam{c}.e3*sin(theta)*sin(phi);
end
clear c theta phi

% use Alexander Brodsky script to find closest approach of two lines 
addpath('./distBW2lines')

% average over all pairs of cameras
R = [];
for c1 = 1:N
    for c2 = (c1+1):N
        L1=cat(2,cam{c1}.C,cam{c1}.C+u{c1})';
        L2=cat(2,cam{c2}.C,cam{c2}.C+u{c2})';
        [d,Pc,Qc]=distBW2lines(L1,L2);
        R(:,end+1) = .5*(Qc+Pc)';
    end
end
clear c1 c2

Rinf =mean(R,2);
deltaRinf = std(R,1,2);

end