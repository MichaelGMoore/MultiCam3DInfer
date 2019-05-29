classdef camClass
    % camClass: camera object for 3D Position Inference application 
    
    properties
        name    % string. Give your camera a name
        C       % [3 x 1] vector of camera position in lab frame
        numPix  % [2 x 1] vector of pixel numbers in [X,Y] form
        alpha   % horizontal angle-of-view of the camera
        
        % these 3 can be learned from the data: 
        e1      % [3 x 1] optical-axis unit vector (same as a)
        e2      % [3 x 1] horizontal axis unit vector 
        e3      % [3 x 1] vertical axis unit vector
                    % e1,e2,e3 must form a right-handed orthonormal triplet   
    end
    
    methods
        function obj = camClass(C,numPix,alpha,name)
            %UNTITLED Construct an instance of this class
            % can call with three arguments to skip giving a name string
            assert(isequal(size(C),[3,1]),'C must be [3 x 1] array')
            assert(isnumeric(C),'C must be numeric')
            assert(isequal(size(numPix),[2,1]),'numPix must be [2 x 1] array')
            assert(isnumeric(numPix),'numPix must be numeric')
            assert(isequal(size(alpha),[1,1]),'alpha must be a single number')
            assert(isnumeric(alpha),'alpha must be numeric')
            
            obj.C = C;
            obj.numPix = numPix;
            obj.alpha = alpha;
            if nargin == 4
                obj.name = name;
            end
        end
        
        function [X,Y] = imageObject(obj,R)
            % compute the X and Y of the object imaged by a camClass object
            assert(isequal(size(R),[3,1]),'R must be [3 x 1] array')
            assert(isnumeric(R),'R must be numeric')
            
            u = R - obj.C;
            u = u/norm(u);
            
            theta = acos(u'*obj.e1); % theta on 0:pi
            rho = tan(theta)/tan(obj.alpha/2); % assumes objects are in angle-of-view

            X = rho*u'*obj.e2/sin(theta);
            Y = rho*u'*obj.e3/sin(theta);     
            
            X = (X+1)/2*obj.numPix(1);
            Y = (Y+obj.numPix(2)/obj.numPix(1))/2*obj.numPix(1);
        end
        
        function obj = trainCam(obj,X,Y,R)
            % learn the camera orientation from images of 2 objects
            %   X   [2 x 1] object X positions (pixels, left-to-right)
            %   Y   [2 x 1] object Y positions (pixels, top-to-bottom)
            %   R   [3 x 2] object lab-frame (x,y,z) coordinates
            %           row runs over x,y,z
            %           col runs over objects
            
            X = 2*X/obj.numPix(1)-1;
            Y = 2*Y/obj.numPix(1)-obj.numPix(2)/obj.numPix(1);
            
            % compute the object pointing unit-vectors
            for o = 1:2
                u(:,o) = R(:,o) - obj.C;
                u(:,o) = u(:,o)/norm(u(:,o));
            end           
            clear o
            
            % compute angles
            for o = 1:2
                theta(o) = atan(sqrt(X(o)^2+Y(o)^2)*tan(obj.alpha/2));
                phi(o) = atan2(Y(o),X(o));
            end
            clear o
            
            % *************************************************************
            % solve for Optical axis
            M = cat(1,u(:,1)',u(:,2)',cross(u(:,1),u(:,2))');
            b = [cos(theta(1));cos(theta(2));...
                sin(theta(1))*sin(theta(2))...
                *(cos(phi(1))*sin(phi(2))-sin(phi(1))*cos(phi(2)))];
            obj.e1 = M\b;
            obj.e1 = obj.e1/norm(obj.e1);
                   

            
            % *************************************************************
            % solve for horizontal axis
            
            M = cat(1,u(:,1)',u(:,2)',obj.e1');
            b = [sin(theta(1))*cos(phi(1));sin(theta(2))*cos(phi(2));0];;
            obj.e2 = M\b;
            obj.e2 = obj.e2/norm(obj.e2);
            
            
            % *************************************************************
            % solve for vertical axis
            obj.e3 = cross(obj.e1,obj.e2);
            obj.e3 = obj.e3/norm(obj.e3);
                 
        end
        
        function obj = aimCam(obj,T)
            % aimCam    aims the camera at the target
            % T is [3 x 1] vector of target in lab frame
            
            %   - by default this will give horizonal alignment 
            %   - if camera is aimed vertically, then it will be aligned along
            %   x-axis in lab frame
            assert(isequal(size(T),[3,1]),'T must be [3 x 1] array')
            
            e1 = T-obj.C;
            e1 = e1/norm(e1);
           
            ez = [0;0;1]; % vertical vector
            
            if abs(e1'*ez) > 0
                e2 = cross(e1,ez);
                e2 = e2/norm(e2);
                e3 = cross(e1,e2);
                if e3'*ez > 0 % we want vert axis pointing down (top-to-bottom pixel labels)
                    e2 = -e2;
                    e3 = -e3;
                end
            else
                e2 = [1,0,0];
                e3 = cross(e1,e2);
            end
            
            obj.e1 = e1;
            obj.e2 = e2;
            obj.e3 = e3;
        end
        
        function obj = spinCam(obj,phi)
            % use the SO(3) generators to make a rotation about e1
            Lx = [0,0,0;0,0,-1;0,1,0];
            Ly = [0,0,1;0,0,0;-1,0,0];
            Lz = [0,-1,0;1,0,0;0,0,0];
            rot =  expm(phi*(obj.e1(1)*Lx +obj.e1(2)*Ly+obj.e1(3)*Lz));
            obj.e2 =rot*obj.e2;
            obj.e3 = rot*obj.e3;
        end
        
        % external methods
        
    end
end

