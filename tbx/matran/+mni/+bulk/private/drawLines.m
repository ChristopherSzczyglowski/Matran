function hg = drawLines(xA, xB, hParent, varargin)
%drawLines Draws a set of line objects between the coordinate sets xA and
%xB and returns the handle.

x  = padCoordsWithNaN([xA(1, :) ; xB(1, :)]);
y  = padCoordsWithNaN([xA(2, :) ; xB(2, :)]);
z  = padCoordsWithNaN([xA(3, :) ; xB(3, :)]);

hg = line('XData', x, 'YData', y, 'ZData', z, ...
    'Parent'   , hParent, ...
    'LineStyle', '-'    , ...
    'LineWidth', 1      , ...
    'Color'    , 'k'    , ...
    'Tag'      , 'Beams');

if ~isempty(varargin)
    set(hg, varargin{:});
end

end