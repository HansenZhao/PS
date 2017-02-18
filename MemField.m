classdef MemField < handle
    %PARTICLEFIELD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        simuResult;
    end

    properties (Access = private)
        regionCell;
        transportStep;
        innerRegion;
        isTransportSet;
        pState;
        curTransportStep;
    end

    properties (Dependent)
        regionNum;
        transRegionIndex;
        simuVel;
    end
    
    methods
        function obj = MemField(initCoef,initBias,innerCoef,innerBias,transStep)
            obj.regionCell = {};
            obj.regionCell{end + 1} = MemRegion(-inf,inf,initCoef,initBias);
            obj.innerRegion = MemRegion(-inf,inf,innerCoef,innerBias);
            obj.transportStep = transStep;         
        end

        function addRegion(obj,starts,ends,coef,bias,varargin)
            if (~isempty(varargin) && varargin{1} == 1)
                if obj.isTransportSet
                    warning('Transport Region has been already set!');
                    return;
                end
                obj.isTransportSet = 1;
                tmpBool = 1;
            else
                tmpBool = 0;
            end
            obj.askForChange(starts,ends);
            obj.regionCell{end + 1} = MemRegion(starts,ends,coef,bias,tmpBool);
        end

        function num = get.regionNum(obj)
            num = length(obj.regionCell);           
        end
        
        function index = get.transRegionIndex(obj)
            if ~obj.isTransportSet
                index = [];
                return;
            end
            for m = 1:1:obj.regionNum
                if obj.regionCell{m}.isTransport
                    index = m;
                    return;
                end
            end
        end
        
        function vel = get.simuVel(obj)
            vel = obj.pos2vel();
        end

        function dispField(obj)
            obj.sortRegion();
            L = obj.regionNum;
            for m = 1:1:(L-1)
                fprintf(1,'<%.1f> ',obj.regionCell{m}.startPos);
                if obj.regionCell{m}.isTransport
                    printPos = 2;
                else
                    printPos = 1;
                end
                fprintf(printPos,'%.2f$%.2f ',obj.regionCell{m}.diffuseCoef,...
                                              obj.regionCell{m}.bias);
            end
            fprintf(1,'<%.1f> %.2f$%.2f <%.1f>\n',obj.regionCell{L}.startPos,...
                                                  obj.regionCell{L}.diffuseCoef,...
                                                  obj.regionCell{L}.bias,...
                                                  obj.regionCell{L}.endPos);
            fprintf(1,'<%.1f> %.2f$%.2f <%.1f>\n',obj.innerRegion.startPos,...
                                                  obj.innerRegion.diffuseCoef,...
                                                  obj.innerRegion.bias,...
                                                  obj.innerRegion.endPos);
        end
        
        function simulate(obj,initPos,stepNum,interval)
            obj.sortRegion();
            obj.prepareSim(stepNum,interval);
            obj.simuResult.data(1) = initPos;
            
            I = obj.tryGetRegionIndex(initPos);
            if obj.regionCell{I}.isTransport
                warning('Init Pos in transport region!')
                obj.pState = ParticleState.InTransport;
                obj.simuResult.inTransportAt(1);
                obj.curTransportStep = 1;
            end
            
            h = waitbar(0,'wait...');
            
            for m = 2:1:stepNum
                obj.simuResult.data(m) = ...
                    obj.askForMove(obj.simuResult.data(m-1),m);
                waitbar(m/stepNum,h,'wait...');
            end
            close(h);
        end
        
        function plot(obj)
            h = figure;
            hAxes = subplot(2,1,1);
            hold on;
            
            hR = rectangle('position',[obj.simuResult.interval * obj.simuResult.inTransportAt,...
                                       obj.regionCell{obj.transRegionIndex}.startPos,...
                                       obj.transportStep * obj.simuResult.interval,...
                                       obj.regionCell{obj.transRegionIndex}.endPos - obj.regionCell{obj.transRegionIndex}.startPos]);
            set(hR,'FaceColor',[1,0.5,0.5],'EdgeColor','none');
            plot(hAxes,(1:1:obj.simuResult.stepNum)' * obj.simuResult.interval,...
                 obj.simuResult.data);
            title('Trajectory of simulated particle');
            hA2 = subplot(2,1,2);
            hold on;
            
            recH = max(obj.pos2vel());
            hR = rectangle('position',[obj.simuResult.interval * obj.simuResult.inTransportAt,...
                                       0,obj.transportStep * obj.simuResult.interval,...
                                       recH]);
            set(hR,'FaceColor',[1,0.5,0.5],'EdgeColor','none');     
            ylim([0,recH]);
            
            plot(hA2,(1:1:obj.simuResult.stepNum)' * obj.simuResult.interval,...
                     obj.pos2vel(),'DisplayName','velocity');
            title('Velocity of simulated particle');
        end
	end

    methods (Access = private)
        function askForChange(obj,starts,ends)
            L = obj.regionNum;
            isToDelete = [];
            for m = 1:1:L
                if obj.regionCell{m}.isOverLap(starts,ends)
                    isToDelete(end + 1) = m;
                    continue;
                else if ~obj.regionCell{m}.onNewRegionAdd(starts,ends)
                        if obj.regionCell{m}.isTransport
                            obj.regionCell{m}.isTransport = 0;
                            obj.isTransportSet = 0;
                            warning('new region overlap with transport region!');
                            warning('transport region has been convert to normal region!');               
                        end
                        tmpEnd = obj.regionCell{m}.endPos;
                        obj.regionCell{m}.changePos('right',starts);
                        obj.regionCell{end + 1} = MemRegion(ends,tmpEnd,obj.regionCell{m}.diffuseCoef,...
                                                            obj.regionCell{m}.bias,0);
                    end
                end            
            end
            for m = 1:1:length(isToDelete)
                if obj.regionCell{isToDelete(m)}.isTransport
                    obj.isTransportSet = 0;
                end
            end
            obj.regionCell(isToDelete) = [];
        end

        function sortRegion(obj)
            L = obj.regionNum;
            tmp = zeros(L,1);
            for m = 1:1:L
                tmp(m) = obj.regionCell{m}.startPos;
            end
            [~,I] = sort(tmp);
            obj.regionCell = obj.regionCell(I);
        end
        
        function prepareSim(obj,stepNum,interval)
            for m = 1:1:obj.regionNum
                obj.regionCell{m}.prepare(stepNum,interval);
            end
            obj.innerRegion.prepare(stepNum,interval);
            obj.simuResult = struct();
            obj.simuResult.stepNum = stepNum;
            obj.simuResult.interval = interval;
            obj.simuResult.data = zeros(stepNum,1);
            obj.simuResult.inTransportAt = 0;
            obj.simuResult.outTransportAt = 0;
            obj.pState = ParticleState.Outter;
            obj.curTransportStep = 0;
        end
        
        function pos = askForMove(obj,curPos,curTime)
            switch obj.pState
                case ParticleState.Outter
                    I = obj.tryGetRegionIndex(curPos);
                    if obj.regionCell{I}.isTransport
                        obj.pState = ParticleState.InTransport;
                        obj.simuResult.inTransportAt = curTime;
                        obj.curTransportStep = 1;
                    end
                    pos = obj.regionCell{I}.getNextPos(curPos);
                case ParticleState.InTransport
                    if obj.curTransportStep >= obj.transportStep
                        obj.pState = ParticleState.Inner;
                        obj.simuResult.outTransportAt = curTime + 1;
                    end
                    I = obj.tryGetRegionIndex(curPos);
                    pos = obj.regionCell{I}.getNextPos(curPos);
                    obj.curTransportStep = obj.curTransportStep + 1;
                case ParticleState.Inner
                    pos = obj.innerRegion.getNextPos(curPos);
            end
        end
        
        function rIndex = getRegionIndex(obj,curPos)
            for m = 1:1:obj.regionNum
                if obj.regionCell{m}.isInRange(curPos)
                    rIndex = m;
                    return;
                end
            end
            rIndex =  -1;
            return;
        end
        
        function rIndex = tryGetRegionIndex(obj,curPos)
            rIndex = obj.getRegionIndex(curPos);
            if rIndex < 0
                rIndex = obj.getRegionIndex(curPos + 0.001);
            end  
        end
        
        function vel = pos2vel(obj)
            vel = zeros(obj.simuResult.stepNum,1);
            vel(2:end) = abs(obj.simuResult.data(2:end) - obj.simuResult.data(1:(end-1)))./ obj.simuResult.interval;
        end
    end    
end



