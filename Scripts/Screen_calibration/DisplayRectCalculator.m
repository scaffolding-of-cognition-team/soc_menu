%% What part of the display is usable
%
%Find out the largest rectangle that can be shown completely on the
%display.
%
% To do this, the code looks for whether any of the values in scal exceed
% the range of the screen (either below zero or above the max y value). If
% so, it finds the highest/lowest y value it can tolerate and sets the
% display rect to that
%

function DisplayRect=DisplayRectCalculator(scal, window)

YPosition=scal.SELECTYCALIBDOTS; %Find all the Y coordinates. If these values are below zero or above the screen res then they will not be included. 

% Remember the top left corner is the 0,0 point
% Do any values of Y dip below the bottom of the screen?
if any(YPosition > window.Rect(4))
    below_bottom_screen=1;
else
    below_bottom_screen=0;
end

% Do any of the Y values go above the top of the screen?
if any(YPosition < 0)
    above_top_screen = 1;
else
    above_top_screen = 0;
end

    
%If it has a maxima out of bounds (Although its value will be more negative
MaximaIdx=1;
if below_bottom_screen==1
    
    %What is the Y coord of the maxima
    [~, sorted_idxs]=sort(YPosition);
    
    %Increment until you get above zero
    while YPosition(sorted_idxs(MaximaIdx))<0
        MaximaIdx=MaximaIdx+1;
    end
    
    %What is the minimum y value to be included in the display
    MinimumY=scal.SELECTYCALIBDOTS_ORG(MaximaIdx);
    
    DisplayRect=[window.Rect(1), MinimumY, window.Rect(3), window.Rect(4)];
    
elseif above_top_screen == 1
    
    %What is the Y coord of the maxima
    [~, MinimaIdx]=min(YPosition);
    
    %Increment until you get above zero
    while YPosition(MinimaIdx)>window.Rect(4)
        MinimaIdx=MinimaIdx-1;
    end
    
    %What is the maximum Y value to be included in the display
    MaximumY=scal.SELECTYCALIBDOTS_ORG(MinimaIdx);
    
    DisplayRect=[window.Rect(1), window.Rect(2), window.Rect(3), MaximumY];
    
else %If Zero then just make original rect
    
    DisplayRect=window.Rect;
    
end
