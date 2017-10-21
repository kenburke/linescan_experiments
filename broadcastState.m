classdef broadcastState < event.EventData
    
   properties
      bcState
      bcData
      bcType
   end
   
   methods
      function data = broadcastState(bcState,bcData,bcType)
         if nargin<3
             bcType = '';
             if nargin<2
                 bcData = NaN;
             end
         end
         
         data.bcState = bcState;
         data.bcData = bcData;
         data.bcType = bcType;
      end
   end
end
