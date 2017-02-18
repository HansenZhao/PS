classdef MemRegion < handle
    
    properties
        id;
        diffuseCoef;
        bias;
        isTransport;
        startPos;
        endPos;
    end
    
    properties (Access = private)
        curDataIndicator;
        dataPool;
    end
    
    methods
        function obj = MemRegion(startPos,endPos,D,bias,varargin)
            if (~isempty(varargin) && varargin{1} == 1)
                obj.isTransport = 1;
            else
                obj.isTransport = 0;
            end
            obj.startPos = startPos;
            obj.endPos = endPos;
            obj.diffuseCoef = D;
            if and(bias ~= 0,obj.isTransport)
                warning('Transport Region should not have bias!');
                obj.bias = 0;
            else
                obj.bias = bias;
            end
            
        end

        function isHandle = onNewRegionAdd(obj,sPos,ePos)
            if(obj.isInRange(sPos) && obj.isInRange(ePos))
                isHandle = false;
                return;
            end

            if obj.isInRange(sPos)
                obj.endPos = sPos;
                isHandle = true;
                return;
            end

            if obj.isInRange(ePos)
                obj.startPos = ePos;
                isHandle = true;
                return;
            end

            isHandle = true;
            return;

        end

        function changePos(obj,spec,pos)
            if strcmp(spec,'left')
                obj.startPos = pos;
                return;
            end

            if strcmp(spec,'right')
                obj.endPos = pos;
                return;
            end
        end

        function isIn = isInRange(obj,pos)
            isIn = and(pos > obj.startPos,pos < obj.endPos);
        end
        
        function isO = isOverLap(obj,sPos,ePos)
            isO = and(sPos <= obj.startPos,ePos >= obj.endPos);
        end
        
        function prepare(obj,stepNum,interval)
            obj.curDataIndicator = 1;
            obj.dataPool = sqrt(2*obj.diffuseCoef*interval) * randn(stepNum,1);
        end
        
        function pos = getNextPos(obj,curPos)
            if obj.isTransport
                while(1)
                    pos = obj.getNextMove() + curPos;
                    if obj.isInRange(pos)
                        break;
                    end
                end
            else
                pos = obj.getNextMove() + curPos;
            end
        end
        
        
    end
    
    methods (Access = private)
        function value = getNext(obj)
            value = obj.dataPool(obj.curDataIndicator);
            obj.curDataIndicator = obj.curDataIndicator + 1;
        end
        function move = getNextMove(obj)
            if rand < abs(obj.bias)
                while(1)
                    move = obj.getNext();
                    if sign(move) == sign(obj.bias)
                        break;
                    end
                end
            else
                move = obj.getNext();
            end
        end
    end
end

