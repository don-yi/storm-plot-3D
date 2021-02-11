function PlotStormDPR( ...
    stormName, fname1C, fname2A, fnameWwlln, centerCoord, passtime, outPath, outFname ...
)

    %%
    % world map and label

    % Create a figure
    bgColor = [0.95 0.95 0.95];
    f = figure( ...
        'Color',bgColor,'Position',[0 0 1024 1024],'visible','off' ...
    );

    % Load and plot the world map first
    load('Map.mat');

    % Draw world map in black line with the equator
    z = zeros(size(world(:,1)));
    plot3(world(:,1),world(:,2),z,'k-','LineWidth',1.0);

    hold on;

    % add labels to graph
    ax = gca;
    ax.Units = 'pixels';
    ax.Position = [150 200 700 700];
    ax.Box = 'off';
    ax.Layer = 'top';
    ax.ZAxis.Visible = 'off';
    ax.Color = [0.95 0.95 0.95];
    % TODO
    % grid(ax, 'off');


    %%
    % 2D 89V plot

    % read 1C S1 lat and lon
    lat1C = h5read(fname1C,'/S1/Latitude');
    lon1C = h5read(fname1C,'/S1/Longitude');

    % read tc 89V from tc
    tc89V = zeros(size(lon1C));
    tc = h5read(fname1C,'/S1/Tc');
    tc89V(:,:) = tc(8,:,:);

    % plot range
    latMin1C = centerCoord(1) - 11;
    latMax1C = centerCoord(1) + 11;
    lonMin1C = centerCoord(2) - 16;
    lonMax1C = centerCoord(2) + 16;

    % The 89V data needs to be scaled to be in the same range
    % as the DPR data so that it can use the same colormap
    inRange1C = find( ...
          (lat1C(1,:) > latMin1C)  ...
        & (lat1C(1,:) < latMax1C)  ...
        & (lon1C(1,:) > lonMin1C) ...
        & (lon1C(1,:) < lonMax1C) ...
    );

    if (isempty(inRange1C))
        disp('WARNING: 1C lat/lon data not in range');
        return;
    end

    % get data in plot range
    lat1C_inRange = lat1C(:,inRange1C);
    lon1C_inRange = lon1C(:,inRange1C);
    tc89V = tc89V(:,inRange1C);

    % trim extreme high temp
    tc89V(tc89V > 265) = NaN;

    % TODO: col bar for both height and brightness temp.
    % scaling with 0.120 so that the data scales down to 0-20
    % and the same color bar can be used for both height and brightness temp.
    tc89V = abs(tc89V - 300) .* 0.120;

    pcolorCentered_old(lon1C_inRange,lat1C_inRange,tc89V);


    %%
    % 3D DPR plot
    heightDs = '/NS/PRE/heightStormTop';
    fillVal = h5readatt(fname2A,heightDs,'_FillValue');

    height = h5read(fname2A,heightDs);
    % TOASK: done this for smoothness and more consistent 3D plotting
    %   (less max/min diff)
    % Change fill value to -9
    % to get a closed graph that touches the ground ???
    height(height==fillVal) = -9;


    % read from hdf5 data
    lat2A = h5read(fname2A,'/NS/Latitude');
    lon2A = h5read(fname2A,'/NS/Longitude');

    % Using a 16X16 degree grid around the center to plot
    latMin2A = centerCoord(1) - 6;
    latMax2A = centerCoord(1) + 6;
    lonMin2A = centerCoord(2) - 6;
    lonMax2A = centerCoord(2) + 6;

    % Check if any dpr data falls in the required range
    inRange2A = find(  ...
          (lat2A(1,:) > latMin2A) ...
        & (lat2A(1,:) < latMax2A) ...
        & (lon2A(1,:) > lonMin2A) ...
        & (lon2A(1,:) < lonMax2A) ...
    );

    if (isempty(inRange2A))
        disp('WARNING: 3A lat/lon data not in range');
        return;
    end


    % scale down to km
    heightKM = height(:,inRange2A)./ 1000;
    heightZero = h5read(fname2A,'/NS/VER/heightZeroDeg');
    heightZeroKM = heightZero(:, inRange2A) ./ 1000;

    % TOASK: need to understand followings?
    % gaussian kernel of width 3 and sigma 2km on the data to smooth
    heightKM = imgaussfilt(heightKM, 2, 'filtersize', 3);

    % since rows are always 49
    extrapRows = 59;
    extrapCols = length(inRange2A);

    extrapLat = zeros(extrapRows, extrapCols);
    extrapLon = zeros(extrapRows, extrapCols);
    extrapHeight = zeros(extrapRows, extrapCols);

    % other helper sets of indices
    x = 6:54;
    y = 1:49;
    preIndices = 1:5;
    postIndices = 50:54;

    % put -9 into the extrapolated rows of height
    for I=1:5
    extrapHeight(I, :) = -9;
    extrapHeight(end-(I-1), :) = -9;
    end

    % lat1C_inRange = lat1C(:,inRange1C);
    % lon1C_inRange = lon1C(:,inRange1C);
    lat2A_inRange = lat2A(:,inRange2A);
    lon2A_inRange = lon2A(:,inRange2A);

    % extrapolate data for lat and long
    for I=1:extrapCols
        preLat = interp1(x, lat2A_inRange(:,I), preIndices, 'linear', 'extrap');
        preLon = interp1(x, lon2A_inRange(:,I), preIndices, 'linear', 'extrap');
        endLat = interp1(y, lat2A_inRange(:,I), postIndices, 'linear', 'extrap');
        endLon = interp1(y, lon2A_inRange(:,I), postIndices, 'linear', 'extrap');
        for J=1:5
            extrapLat(J,I) = preLat(J);
            extrapLon(J,I) = preLon(J);
            extrapLat(end-(J-1), I) = endLat(6-J);
            extrapLon(end-(J-1), I) = endLon(6-J);
        end
    end

    % copy old data back
    for I=1:extrapCols
        for J=1:49
            extrapHeight(J+5,I) = heightKM(J,I);
            extrapLon(J+5,I) = lon2A_inRange(J,I);
            extrapLat(J+5,I) = lat2A_inRange(J,I);
        end
    end

    % TODO: check back later for necessity (grid)
    % Create a 100x100 grid for each degree in the range and grid the data
    % on that range
    gridY = latMin2A:0.01:latMax2A;
    gridX = lonMin2A:0.01:lonMax2A;
    [xq, yq] = meshgrid(gridX, gridY);

    % grid the extrapolated data using the natural method
    gd = griddata(extrapLon, extrapLat, extrapHeight, xq, yq, 'natural');

    % Draw the plot using the surf commmand
    s = surf(xq,yq, gd, 'FaceColor', 'interp', 'FaceAlpha',0);
    s.EdgeColor = 'none';

    % % Compile the c-code functions
    % mex smoothpatch_curvature_double.c
    % mex smoothpatch_inversedistance_double.c
    % mex vertex_neighbours_double.c

    disp('Compiled C-code, proceeding to produce plot');

    ps = surf2patch(s);
    s2 = smoothpatch(ps, 0, 15);

    patch(s2, 'FaceColor','interp','EdgeAlpha',0, 'FaceAlpha', 0.5);

    %%
    % Setup the Colormap and graph limits
    colormap(jet(64));
    min_data=0;
    max_data=20;

    % setup axes limits for the plot and colorbar
    xlim([lonMin2A lonMax2A]);
    ylim([latMin2A latMax2A]);
    zlim([min_data max_data]);
    caxis([min_data max_data]);

    % overlapping the original colorbar
    hAx=gca;                     % save axes handle main axes
    h=colorbar('Location','southoutside', ...
        'Position',[0.15 0.1 0.7 0.02]);% add colorbar, save its handle
    set(h, 'XDir', 'reverse'); % reverse axis
    h2Ax=axes('Position',h.Position,'color','none');  % add mew axes at same posn
    h2Ax.YAxis.Visible='off'; % hide the x axis of new
    h2Ax.XAxisLocation = 'top';
    h2Ax.Position = [0.15 0.11 0.7 0.01];  % put the colorbar back to overlay second axeix
    h2Ax.XLim=[120 260];       % alternate scale limits new axis
    xlabel(h, 'Height (km)','HorizontalAlignment','center');
    xlabel(h2Ax,'89V GHz (Tb)','HorizontalAlignment','center');

    % Set current back to the main one (done manually so that the other
    % properties such as visibility are not affected).
    % -- Connor Bracy 05/25/2020
    hGifFig = gcf;
    hGifFig.CurrentAxes = hAx;
    % Attmpt to speed up the processing by hiding all figures, setting the current figure to the one
    % that will be used to create the GIF images, and setting it to be the only visible figure
    % so that getframe isn't slowed down by 'capturing the frame of a figure not visible on the screen'
    % which supposedly greatly reduces the computational efficiency of the function.
    % -- Connor Bracy 05/27/2020
    set(findobj('Type', 'Figure'), 'Visible', 'off'); % Make all figures in this MATLAB workspace non-visible
    set(0, 'CurrentFigure', hGifFig); % Set the current figure of the workspace to the figure we will use to generate images.

    %%
    % Draw lightning

    % read data
    fidLN = fopen(fnameWwlln, 'r');
    lightningData = textscan(fidLN, '%f %f %f %f %f %f %f %f %f %f');

    % split time data field
    lightningY = lightningData{1};
    lightningM = lightningData{2};
    lightningD = lightningData{3};
    lightningH = lightningData{4};
    lightningMN = lightningData{5};
    lightningS = lightningData{6};
    % org as serial date num
    lightningTime = datenum( ...
        lightningY, lightningM, lightningD, lightningH, lightningMN, lightningS ...
    );

    % split lat & lon data field
    lightningLat = lightningData{7};
    lightningLon = lightningData{8};
    % split dist data field
    lightningDistEW = lightningData{9};
    lightningDistNS = lightningData{10};

    % Read storm information from file name
    % 2A.GPM.DPR.V820180723.20200827-S024128-E031127.V06A.RT-H5
    stormY = str2double(fname2A(23:26));
    stormM = str2double(fname2A(27:28));
    stormD = str2double(fname2A(29:30));
    stormStartH = str2double(fname2A(33:34));
    stormStartMN = str2double(fname2A(35:36));
    stormStartS = str2double(fname2A(37:38));
    stormEndH = str2double(fname2A(41:42));
    stormEndMN = str2double(fname2A(43:44));
    stormEndS = str2double(fname2A(45:46));
    % org as serial date num
    stormStartTime = datenum( ...
        stormY, stormM, stormD, stormStartH, stormStartMN, stormStartS ...
    );
    stormEndTime = datenum( ...
        stormY, stormM, stormD, stormEndH, stormEndMN, stormEndS ...
    );

    % calculate pythagorean distance from center
    distCent = (lightningDistEW.^2 + lightningDistNS.^2).^0.5;

    % get passtime as serial date num
    passtimeDN = datenum(passtime, 'yyyy-mm-dd HH:MM:SS');
    lightingTimeFrom = passtimeDN - datenum('00:15', 'HH:MM');
    lightingTimeTo = passtimeDN + datenum('00:15', 'HH:MM');

    % find ind during storm
    indDuringStorm = find( ...
          lightingTimeFrom <= lightningTime ...
        & lightningTime <= lightingTimeTo ...
    );
    % find all in radius 600km
    indDuringInStorm = find(distCent(indDuringStorm) <= 600);

    % pruning lat/lon arrays to ind of during and in storm
    latFound = lightningLat(indDuringInStorm);
    lonFound = lightningLon(indDuringInStorm);

    % scatter on 2D
    scatter( ...
        lonFound, latFound, ...
        16, ...
        'black', ...
        'filled', ...
        'LineWidth', .05, ...
        'MarkerEdgeColor', 'black' ...
    );

    shg;

    % get and scale melting layer height (km)
    meltingHeightRaw = h5read(fname2A,'/NS/VER/heightZeroDeg');
    meltingHeight = meltingHeightRaw(:, inRange2A) ./ 1000;

    % TODO
    % lNheight = ones(length(lat_in), 1) .* meltingLayerMean;
    % scatter3(lon_in, lat_in, lNheight, 30,'magenta', 'filled'...
    %     ,'LineWidth',.05, 'MarkerEdgeColor','k');

    % hold off;

    %%
    % Set the view and lights

    % set light
    camlight('headlight');
    light('Position',[lonMax2A latMax2A 0],'Style','local');
    lighting gouraud

    % set title
    name = 'NS/PRE/heightStormTop';
    title( ...
        hAx, {stormName; outFname; name}, ...
        'Interpreter', 'None', 'FontSize', 12, 'FontWeight', 'bold' ...
    );

    view(0, 90);

    % gen full file name
    fullOutFname = fullfile(outPath, [outFname, '.gif']);





end
