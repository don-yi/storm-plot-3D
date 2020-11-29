function PlotStormDPR(STORM_NAME, wwlln_file_name, FILE_NAME, FILE_NAME_1C, stormCenterCoords, output_path, output_base_filename)
    DEGREE_SYMBOL = char(0176);

    file_id = H5F.open(FILE_NAME, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');
    file_id_1c = H5F.open(FILE_NAME_1C, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');

    % Using a 16X16 degree grid around the center to plot
    latMin = stormCenterCoords(1) - 6;
    latMax = stormCenterCoords(1) + 6;
    lonMin = stormCenterCoords(2) - 6;
    lonMax = stormCenterCoords(2) + 6;

    %%
    % Open the dataset.
    DATAFIELD_NAME_TC = 'S1/Tc';
    data_id_tc = H5D.open(file_id_1c, DATAFIELD_NAME_TC);

    Lat_NAME_TC = 'S1/Latitude';
    lat_id_tc = H5D.open(file_id_1c, Lat_NAME_TC);

    Lon_NAME_TC = 'S1/Longitude';
    lon_id_tc = H5D.open(file_id_1c, Lon_NAME_TC);

    DATAFIELD_NAME = 'NS/PRE/heightStormTop';
    data_id = H5D.open(file_id, DATAFIELD_NAME);

    MELTING_LAYER_NAME = 'NS/VER/heightZeroDeg';
    melting_id = H5D.open(file_id, MELTING_LAYER_NAME);

    Lat_NAME='NS/Latitude';
    lat_id=H5D.open(file_id, Lat_NAME);

    Lon_NAME='NS/Longitude';
    lon_id=H5D.open(file_id, Lon_NAME);

    % Read the dataset.
    data=H5D.read(data_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    meltingHeight=H5D.read(melting_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    lat=H5D.read(lat_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    lon=H5D.read(lon_id,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');

    data2d = H5D.read(data_id_tc,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    lat2d=H5D.read(lat_id_tc,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    lon2d=H5D.read(lon_id_tc,'H5T_NATIVE_DOUBLE', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');

    %%
    % Read the fill value attribute.
    ATTRIBUTE = '_FillValue';
    attr_id = H5A.open_name (data_id, ATTRIBUTE);
    fillvalue = H5A.read(attr_id, 'H5ML_DEFAULT');

    % Read the units attribute.
    ATTRIBUTE = 'units';
    attr_id = H5A.open_name (data_id, ATTRIBUTE);
    units = H5A.read(attr_id, 'H5ML_DEFAULT');

    % Close and release resources.
    H5A.close (attr_id);
    H5D.close (data_id);
    H5F.close (file_id);

    %%
    % Check if any dpr data falls in the required range
    indices = find(  (lat(1,:) > latMin) ...
                   & (lat(1,:) < latMax) ...
                   & (lon(1,:) > lonMin) ...
                   & (lon(1,:) < lonMax));

    if (isempty(indices))
        disp('WARNING: No data lat/lon coordinates found within our lat/lon min/max range'); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%$
        return;
    end

    %%
    % Extract 89V and 89H from the 2d data
    tc89V=zeros(size(lon2d));
    tc89V(:,:)=data2d(8,:,:);

    tc89H = zeros(size(lon2d));
    tc89H(:,:)=data2d(9,:,:);

    % Change fill value and first and last row to -9
    % to get a closed graph that touches the ground
    data(data==fillvalue) = -9;

    % This comment is being written well after this code was made, but I believe these commands isolate a
    % filename from it's full path string (i.e. path + filename) so that the
    % indexed extraction of information that Shashwat does in the
    % "Read storm information from file name" lines will work when [FILE_NAME]
    % is a full path string. This may break passing in [FILE_NAME] as a simple
    % filename (i.e. without the path component), but I am unable to test that
    % at this time due to lack of access to MATLAB.
    % -- Connor Bracy 06/30/2020
    full_FILE_NAME  = FILE_NAME;                %%%%%
    split_FILE_NAME = strsplit(FILE_NAME, '/'); %%%%%
    FILE_NAME       = ['_',split_FILE_NAME{end}];     %%%%%

    % Read storm information from file name
    stormDay       = str2double(FILE_NAME(30:31));
    stormMonth     = str2double(FILE_NAME(28:29));
    stormStartTime = str2double(FILE_NAME(34:35)) * 60 + str2double(FILE_NAME(36:37));
    stormEndTime   = str2double(FILE_NAME(42:43)) * 60 + str2double(FILE_NAME(44:45));

    FILE_NAME = full_FILE_NAME;  %%%%%

    %%
    % With all the data loaded and information extracted, we can start plotting.
    %%
    bgColor = [0.95 0.95 0.95];
    gridLinesColor = [0.7 0.7 0.7];

    % Create a figure
    f=figure('Color',    bgColor,         ...
             'Position', [0 0 1024 1024], ...
             'visible',  'off');

    % Load and plot the world map first
    load('Map.mat');

    % Draw world map in black line with the equator
    z = zeros(size(world(:,1)));
    disp('wp2=plot3(...)'); %%%%%
    wp2=plot3(world(:,1),world(:,2),z,'k-','LineWidth',1.0);
    disp('END: wp2=plot3(...)'); %%%%%
    hold on;
    % eqp=plot([-180,180],[0,0],'k-','LineWidth',0.7); hold on;

    % add labels to graph
    % get axes handle
    ax = gca;
    ax.Units = 'pixels';
    ax.Position = [150 200 700 700];
    ax.Box = 'off';
    ax.Layer = 'top';
    ax.ZAxis.Visible = 'off';
    ax.Color = [0.95 0.95 0.95];
    grid(ax, 'off');

    % plotting my own grid because it is either all or nothing
    % if using matlab grid
    stormLongs = lonMin:2:lonMax;
    stormLats = latMin:2:latMax;
    gridZ = zeros(size(stormLats));
    for I=stormLongs
        xaxis = ones(size(stormLats)) .* I;
        p = plot3(xaxis, stormLats, gridZ, '-', 'Color',gridLinesColor);
    end
    for I=stormLats
        yaxis = ones(size(stormLongs)) .* I;
        plot3(stormLongs, yaxis, gridZ, '-', 'Color',[0.7 0.7 0.7]);
    end

    hold on;
    %%
    % Draw the 89V next
    % The 89V data needs to be scaled to be in the same range
    % as the DPR data so that it can use the same colormap
    indices2d = find(  (lat2d(1,:) > latMin-5)    ...
                     & (lat2d(1,:) < latMax+5)    ...
                     & (lon2d(1,:) > lonMin-10)   ...
                     & (lon2d(1,:) < lonMax+10));

    stormLat2d = lat2d(:,indices2d);
    stormLon2d = lon2d(:,indices2d);
    tc89V = tc89V(:,indices2d);

    % all values greater than 265 should vanish
    tc89V(tc89V > 265) = NaN;

    % scaling with 0.120 so that the data scales down to 0-20
    % and the same color bar can be used for both height and brightness temp.
    tc89V = abs(tc89V - 300) .* 0.120;
    p = pcolorCentered_old(stormLon2d,stormLat2d,tc89V);

    %%
    % reduce data according to the indices in range

    stormLat = lat(:,indices);
    stormLon = lon(:,indices);

    % scale heights down to km
    stormHeight = data(:,indices)./ 1000;
    meltingLayerHeight = meltingHeight(:, indices) ./ 1000;

    % running a gaussian kernel of width 3 and sigma 2km on the data to smooth
    stormHeight = imgaussfilt(stormHeight, 2, 'filtersize', 3);

    % since rows are always 49
    extrapRows = 59;
    extrapCols = length(indices);

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

    % extrapolate data for lat and long
    for I=1:extrapCols
        preLat = interp1(x, stormLat(:,I), preIndices, 'linear', 'extrap');
        preLon = interp1(x, stormLon(:,I), preIndices, 'linear', 'extrap');
        endLat = interp1(y, stormLat(:,I), postIndices, 'linear', 'extrap');
        endLon = interp1(y, stormLon(:,I), postIndices, 'linear', 'extrap');
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
            extrapHeight(J+5,I) = stormHeight(J,I);
            extrapLon(J+5,I) = stormLon(J,I);
            extrapLat(J+5,I) = stormLat(J,I);
        end
    end

    % Create a 100x100 grid for each degree in the range and grid the data
    % on that range
    gridY = latMin:0.01:latMax;
    gridX = lonMin:0.01:lonMax;
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
    %%
    % Setup the Colormap and graph limits
    colormap(jet(64));
    min_data=0;
    max_data=20;

    % setup axes limits for the plot and colorbar
    xlim([lonMin lonMax]);
    ylim([latMin latMax]);
    zlim([min_data max_data]);
    caxis([min_data max_data]);

    % overlapping the original colorbar
    hAx=gca;                     % save axes handle main axes
    h=colorbar('Location','southoutside', ...
        'Position',[0.15 0.1 0.7 0.02]);% add colorbar, save its handle
    h2Ax=axes('Position',h.Position,'color','none');  % add mew axes at same posn
    h2Ax.YAxis.Visible='off'; % hide the x axis of new
    h2Ax.XAxisLocation = 'top';
    h2Ax.Position = [0.15 0.11 0.7 0.01];  % put the colorbar back to overlay second axeix
    h2Ax.XLim=[120 260];       % alternate scale limits new axis
    xlabel(h, 'Height (km)','HorizontalAlignment','center');
    xlabel(h2Ax,'89V GHz (Tb)','HorizontalAlignment','center');

    %% set current back to the main one
    %axes(hAx);
    %set(gcf, 'visible', 'off');
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
    fid = fopen(wwlln_file_name, 'r');

    data_storm=fscanf(fid,'%g %g %g %g %g %g %g %g %g %g\n', [10 inf]);
    data_storm=data_storm';

    % separate all the columns in separate vectors
    year_cg_all=data_storm(:,1);
    month_cg_all=data_storm(:,2);
    day_cg_all=data_storm(:,3);
    hr_cg_all=data_storm(:,4);
    min_cg_all=data_storm(:,5);
    sec_cg_all=data_storm(:,6);
    lat_cg_all=data_storm(:,7);
    long_cg_all=data_storm(:,8);
    distance_EW=data_storm(:,9);
    distance_NS=data_storm(:,10);

    % calculate pythagorean distance from center
    dist_center=(distance_EW.^2 + distance_NS.^2).^0.5;

    % calculate number of minutes from beginning of day
    min_day=hr_cg_all*60+min_cg_all;

    % find all lightning data in a 90 min. bracket around the storm data
    k1=find(  (day_cg_all ==stormDay )     ...
            & (min_day>=stormStartTime )   ...
            & (min_day<=stormEndTime )     ...
            & (month_cg_all==stormMonth));

    % plot WWLLN events in storm centered coordinates for the day
    latLN=lat_cg_all(k1);
    lonLN=long_cg_all(k1);

    % find all which are in a radius of 600km
    k=find(dist_center(k1)<=600);

    % pruning the lat/lon arrays to the search radius
    lat_in=latLN(k);
    lon_in=lonLN(k);

    % using a mean of melting layer height because there is
    % no easy way I know of to search for the melting layer
    % values at the lat/long from the lightning file
    meltingLayerMean = mean2(meltingLayerHeight);
    scatter1 = scatter(lon_in,lat_in,16,[0 0 0],...
        'filled','LineWidth',.05, 'MarkerEdgeColor','k');

    lNheight = ones(length(lat_in), 1) .* meltingLayerMean;
    scatter3(lon_in, lat_in, lNheight, 30,'magenta', 'filled'...
        ,'LineWidth',.05, 'MarkerEdgeColor','k');

    hold off;

    %%
    % Set the view and lights
    camlight('headlight');

    %light('Position',[0 0 0],'Style','local')
    light('Position',[lonMax latMax 0],'Style','local');

    lighting gouraud

    name = sprintf('%s', DATAFIELD_NAME);

    % Set axis title
    title(hAx, {STORM_NAME;output_base_filename; name},...
          'Interpreter', 'None', 'FontSize', 12,'FontWeight','bold');

    % Save the figure
    %saveas(f, [FILE_NAME '.fig']);

    view(0,90);


    % Generate the full-filename that will be used to output the plot.
    outputFullfile = fullfile(output_path, [output_base_filename, '.gif']);

    % Setup the variables needed to speed up the third frame generating loop,
    % which is simply the same frames as the first loop but in the reverse order.
    firstInterpCount = 15;                        %%%%%
    gifFrames        = cell(firstInterpCount, 1); %%%%%

    % Rotate from 90 to 45
    for J=1:firstInterpCount%15
        view(0, 90 - 3*J);
        frame = getframe(f);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        % Store the frame data to be used in the third frame loop.
        gifFrames{J} = {imind; cm}; %%%%%
        if J == 1
            imwrite(imind,cm,outputFullfile,'gif', 'Loopcount',inf);
        else
            imwrite(imind,cm,outputFullfile,'gif','WriteMode','append');
        end
    end

    % Rotate 360 about y-axis
    for J=1:40
        view(9*J, 45);
        frame = getframe(f);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        % keep appending to the same gif file
        imwrite(imind,cm,outputFullfile,'gif','WriteMode','append');
    end

    % Rotate back to 90 from 45
    % Draw the frames generated from the first loop to the GIF but in reverse
    % order. This reduces the computation time by avoiding redundant computation.
    for J=firstInterpCount:-1:1 %%%%%
        view(0, 45 + 3*J)

        prevFrame = gifFrames{J}; %%%%%
        imind     = prevFrame{1}; %%%%%
        cm        = prevFrame{2}; %%%%%

        % Write to the GIF File
        imwrite(imind,cm,outputFullfile,'gif','WriteMode','append');
    end
end

