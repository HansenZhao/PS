classdef ParticleField < handle
    %PARTICLEFIELD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    	particleNum;
    	regionNum;
    end

    properties (Access = private)
    	fieldSpliter;
    	diffuseCoef;
        bias;
    	simuResult;
        simuStepPool;
        simuInterval;
    end
    
    methods
    	%% ParticleField: new ParticleField instance
    	function obj = ParticleField(initCoef,initBias)
    		obj.particleNum = 0;
    		obj.regionNum = 1;
    		obj.fieldSpliter = [-inf,inf];
    		obj.diffuseCoef = initCoef;
            obj.bias = initBias;
    		obj.simuResult = [];
            obj.simuStepPool = [];
            obj.simuInterval = 0;
    	end

    	%% addParticle: add new Paticle to field
    	function [] = addParticle(obj,num,varargin)
    		if nargin == 1
    			initPos = 0;
    		else
    			initPos = varargin{1};
    		end
    		for m = 1:1:num
    			obj.simuResult(end+1) = initPos;
    		end
    		obj.particleNum = obj.particleNum + num;
    	end

    	%% addRegion: add a new Region in field
    	function addRegion(obj,regionPos,coef,bias,varargin)

            if (length(regionPos) == 1 && nargin == 5)
                if strcmp(varargin{1},'left')
                    newRegion = [-inf,regionPos];
                else if strcmp(varargin{1},'right')
                        newRegion = [regionPos,inf];
                    else
                        return;
                    end
                end
            else if length(regionPos) == 2
                    newRegion = regionPos;
                else
                    return;
                end
            end

            startPos = sum(obj.fieldSpliter < newRegion(1));
            endPos = sum(obj.fieldSpliter <= newRegion(2));

            if startPos < endPos
            	coverIndices = (startPos + 1):endPos;
            	if length(coverIndices) > 1
            		obj.diffuseCoef(coverIndices(1:(length(coverIndices)-1))) = [];
            	end
            	obj.fieldSpliter(coverIndices) = [];
                
                obj.diffuseCoef = ParticleField.insertAfter(obj.diffuseCoef,coef,startPos);
                obj.bias = ParticleField.insertAfter(obj.bias,bias,startPos);
            else              
                obj.diffuseCoef = ParticleField.insertAfter(obj.diffuseCoef,[coef,obj.diffuseCoef(startPos)],startPos);  
                obj.bias = ParticleField.insertAfter(obj.bias,[bias,obj.bias(startPos)],startPos);  
            end
            
            obj.fieldSpliter = ParticleField.insertAfter(obj.fieldSpliter,newRegion,startPos);    
            obj.regionNum = length(obj.diffuseCoef);
    	end

    	%% dispField: display field info in console
    	function [] = dispField(obj)

            if and(length(obj.fieldSpliter) - obj.regionNum ~= 1,...
                obj.regionNum == length(obj.bias))

                disp('Field Region set error!')
                return;

            end

    	    L = obj.regionNum;
    	    for m = 1:1:L
                fprintf(1,'<%.1f> %.2f$%.2f ',obj.fieldSpliter(m),obj.diffuseCoef(m),obj.bias(m));
    	    end
    	    fprintf(1,'<%.1f>\n',obj.fieldSpliter(end));
    	end

        %% simulate: begin simulation (simLength,interval,Dimension)
        function [] = simulate(obj,simLength,interval)
            if nargin < 2
                interval = 1;
            end
            if nargin < 1
                simLength = 1000;
            end

            obj.simuInterval = interval;

            curPos = obj.simuResult(1,:);
            obj.simuResult = zeros(simLength,obj.particleNum);
            obj.simuResult(1,:) = curPos;
            
            obj.simuStepPool = zeros(obj.regionNum,simLength,obj.particleNum);

            for m = 1:1:obj.regionNum
                obj.simuStepPool(m,:,:) = sqrt(2.0 * obj.diffuseCoef(m) * interval) * randn(simLength,obj.particleNum);
            end

            for m = 1:1:obj.particleNum
                stepPoolIndex = ones(1,obj.regionNum);
                tmpPos = curPos(m);

                for n = 2:1:simLength
                    regionIndex = obj.getPosRegionIndex(tmpPos);
                    regionBias = obj.bias(regionIndex);

                    if rand < abs(regionBias)
                        while(1)
                            tryChange = obj.simuStepPool(regionIndex,stepPoolIndex(regionIndex),m);
                            stepPoolIndex(regionIndex) = stepPoolIndex(regionIndex) + 1;

                            if sign(tryChange) == sign(regionBias)
                                break;
                            end
                        end
                    else
                        tryChange = obj.simuStepPool(regionIndex,stepPoolIndex(regionIndex),m);
                        stepPoolIndex(regionIndex) = stepPoolIndex(regionIndex) + 1;
                    end

                    nextPos = tmpPos + tryChange;

                    obj.simuResult(n,m) = nextPos;
                    tmpPos = nextPos;
                end
            end

        end

        function [] = plotSimu(obj)
            time = (0:1:(size(obj.simuResult,1)-1)).*obj.simuInterval;
            subplot(1,2,1);
            for m = 1:1:length(obj.diffuseCoef)
                if obj.bias(m) ~= 0
                    posY = obj.fieldSpliter(m);
                    if posY == -inf
                        posY = min(obj.simuResult(:,m));
                    end
                    height = obj.fieldSpliter(m + 1) - posY;
                    if height == inf
                        height = range(obj.simuResult(:,m));
                    end

                    h = rectangle('position',[0,posY,range(time),height]);
                    set(h,'EdgeColor','none');
                    hold on;
                    if obj.bias(m) > 0
                        set(h,'FaceColor',[1,1,1]-([0,1,1]*abs(obj.bias(m))));
                    else if obj.bias(m) < 0
                            set(h,'FaceColor',[1,1,1]-([1,1,0]*abs(obj.bias(m))));
                        end
                    end
                end             
            end
            for m = 1:1:obj.particleNum
                plot(time,obj.simuResult(:,m),'DisplayName',strcat('trajectory of Particle:',32,num2str(m)));
                hold on;
            end
            xlabel('Time');
            ylabel('Position');
            xlim([0,max(time)]);
            ylim([min(obj.simuResult(:,m)),max(obj.simuResult(:,m))]);

            subplot(1,2,2);
            for m = 1:1:obj.particleNum
                plot(time,obj.pos2vel(obj.simuResult(:,m)),'DisplayName',strcat('velocity of Particle:',32,num2str(m)));
                hold on;
            end
            xlabel('Time');
            ylabel('Velocity');
        end

        function [pos] = getSimuResult(obj,varargin)
            if isempty(varargin)
                pos = obj.simuResult;
            else
                if or(varargin{1} > obj.particleNum,varargin{1}<=0)
                    disp(strcat('ERROR: cannot find Particle',32,num2str(varargin{1})));
                    return;
                end
                pos = obj.simuResult(:,varargin{1});
            end
        end

        function [vel] = getSimuVel(obj,varargin)
            vel = obj.pos2vel(obj.getSimuResult(varargin{1}));
        end   
    end

    methods (Access = private)
        %% getPosRegionCoef: get pos
        function [index] = getPosRegionIndex(obj,pos)
            index = sum(obj.fieldSpliter <= pos,2);
        end    

        function [vel] = pos2vel(obj,pos)
            [L,S] = size(pos);
            vel = zeros(L,S);
            for m = 2:1:L
                vel(m,:) = abs((pos(m,:) - pos(m-1,:)))./obj.simuInterval;
            end
        end  
    end

    methods (Static)
    	function [array] = insertAfter(rawArray,vec,pos)
    		L = length(rawArray);
    		nL = length(vec);
    		array = zeros(1,L+nL);
    		array(1:pos) = rawArray(1:pos);
    		array((pos+1):pos+nL) = vec;
    		array((pos+nL+1):end) = rawArray((pos+1):end);
    	end
	end    
end

