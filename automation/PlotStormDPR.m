function PlotStormDPR( ...
    stormName, fname1C, fname2A, centerCoord, outPath, outFname ...
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
    % TODO: check back later
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
    % % scaling with 0.120 so that the data scales down to 0-20
    % % and the same color bar can be used for both height and brightness temp.
    % tc89V = abs(tc89V - 300) .* 0.120;

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

    % Compile the c-code functions
    mex smoothpatch_curvature_double.c
    mex smoothpatch_inversedistance_double.c
    mex vertex_neighbours_double.c

    disp('Compiled C-code, proceeding to produce plot');

    ps = surf2patch(s);
    s2 = smoothpatch(ps, 0, 15);

    patch(s2, 'FaceColor','interp','EdgeAlpha',0, 'FaceAlpha', 0.5);




    % % Read storm information from file name
    % % 2A.GPM.DPR.V820180723.20200827-S024128-E031127.V06A.RT-H5
    % Y = str2double(fname2A(23:26));
    % M = str2double(fname2A(27:28));
    % D = str2double(fname2A(29:30));

    % SH = str2double(fname2A(33:34));
    % SMN = str2double(fname2A(35:36));
    % SS = str2double(fname2A(37:38));

    % EH = str2double(fname2A(41:42));
    % EMN = str2double(fname2A(43:44));
    % ES = str2double(fname2A(45:46));

    % % serial date num of start and end
    % S = datenum(Y,M,D,SH,SMN,SS);
    % E = datenum(Y,M,D,EH,EMN,ES);



end
