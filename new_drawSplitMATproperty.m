function new_drawSplitMATproperty(vecLD, property, markerSize)
    % my_drawSplitMATpropertyWithRectangles(vecLD, property, markerSize)
    % splits the MAT property into desired split, visualizes them with
    % rectangle outlines, as seen in paper (param = bottom percentage)
    %
    % Input:
    %   vecLD: The vectorized line drawing
    %   property: String indicating the MAT property ('mirror', 'parallelism', 'separation', 'taper', 'convexity')
    %   markerSize: The size of the markers for plotting (default: 1)
    %
    % Output:
    %   Saves three images: 'property'_top50.png, 'property'_bot50.png, 'property'_intact.png

    if nargin < 3
        markerSize = 1;
    end


    if ~isfield(vecLD, [property, '_allX'])
        error(['Property ', property, ' has not been computed.']);
    end

    %same format as drawMATproperty
    allX = vecLD.([property, '_allX']);
    allY = vecLD.([property, '_allY']);
    allScores = vecLD.([property, '_allScores']);

    %splitting scores into top 50% and bottom 50% (changed)
    %medianScore = median(allScores);
    %topIdx = allScores > medianScore;    %top 50%
    %bottomIdx = allScores <= medianScore; %bottom 50%

    %splitting the scores into top 100*(1-param)%
    %param = bottom split value
    param = 0.5
    thresholdScore = quantile(allScores, param);
    topIdx = allScores > thresholdScore; 
    bottomIdx = allScores <= thresholdScore; 
    topX = allX(topIdx);
    topY = allY(topIdx);
    bottomX = allX(bottomIdx);
    bottomY = allY(bottomIdx);

    imgWidth = vecLD.imsize(1);
    imgHeight = vecLD.imsize(2);
    rectPos = [1, 1, imgWidth - 1, imgHeight - 1];

    %bottom 50% plot (black lines + blue rectangle)
    figure('Visible', 'off');
    scatter(bottomX, bottomY, markerSize, 'k', 'filled');
    hold on;
    rectangle('Position', rectPos, 'EdgeColor', 'b', 'LineWidth', 2);
    hold off;
    setAxisProperties(imgWidth, imgHeight);
    saveas(gcf, [property, '_bot50.png']);
    close(gcf);

    %top 50% plot (black lines + red rectangle)
    figure('Visible', 'off');
    scatter(topX, topY, markerSize, 'k', 'filled');
    hold on;
    rectangle('Position', rectPos, 'EdgeColor', 'r', 'LineWidth', 2);
    hold off;
    setAxisProperties(imgWidth, imgHeight);
    saveas(gcf, [property, '_top50.png']);
    close(gcf);

    %whole image plot (bottom 50 in blue, top 50 in red)
    figure('Visible', 'off');
    hold on;
    scatter(bottomX, bottomY, markerSize, 'b', 'filled');
    scatter(topX, topY, markerSize, 'r', 'filled');
    hold off;
    rectangle('Position', rectPos, 'EdgeColor', 'k', 'LineWidth', 2);
    setAxisProperties(imgWidth, imgHeight);
    legend({'Bottom 50%', 'Top 50%'}, 'Location', 'best');
    saveas(gcf, [property, '_intact.png']);
    close(gcf);


    function setAxisProperties(imgWidth, imgHeight)
        axis ij;
        axis([1, imgWidth, 1, imgHeight]);
        axis off;
        daspect([1 1 1]);
        box on;
        set(gcf, 'color', 'w');
        set(gca, 'Position', [0 0 1 1]);
    end
end
