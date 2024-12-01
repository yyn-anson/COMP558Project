%fileName = 'images/example.jpg';
%vecLD = traceLineDrawingFromRGB(fileName);
%already done in previous file (compute_LD_MAT)


vecLD = computeContourProperties(vecLD);

%need contour properties of vecLD for this to work ^
[vecLD,MAT,MATskel] = computeAllMATfromVecLD(vecLD);
%modified computeALLMATproperties to include Taper and our addition
%'Convexity'


figure;
drawMATproperty(vecLD,'mirror');
title('Mirror','FontSize',18);

figure;
drawMATproperty(vecLD,'parallelism');
title('Parallelism','FontSize',18);

figure;
drawMATproperty(vecLD,'taper');
title('Taper','FontSize',18);

figure;
drawMATproperty(vecLD,'separation');
title('Separation','FontSize',18);

figure;
drawMATproperty(vecLD,'convexity');
title('Convexity','FontSize',18);