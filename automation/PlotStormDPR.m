function PlotStormDPR( ...
    stormName, fname1C, fname2A, centerCoord, outPath, outFname ...
)

    %%

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
    % Draw the 89V next

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

    % get data in plot range
    lat1C_inRange = lat1C(:,inRange1C);
    lon1C_inRange = lon1C(:,inRange1C);
    tc89V = tc89V(:,inRange1C);

    % trim extreme high temp
    tc89V(tc89V > 265) = NaN;

    pcolorCentered_old(lon1C_inRange,lat1C_inRange,tc89V);








    % %%
    % % DPR

    % % read from hdf5 data
    % lat2A_ds = '/NS/Latitude';
    % lat2A = h5read(fname2A,lat2A_ds);
    % lon2A_ds = '/NS/Longitude';
    % lon2A = h5read(fname2A,lon2A_ds);

    % % Using a 16X16 degree grid around the center to plot
    % latMin = centerCoord(1) - 6;
    % latMax = centerCoord(1) + 6;
    % lonMin = centerCoord(2) - 6;
    % lonMax = centerCoord(2) + 6;


    % % Check if any dpr data falls in the required range
    % inRange2A = find(  ...
    %       (lat2A(1,:) > latMin) ...
    %     & (lat2A(1,:) < latMax) ...
    %     & (lon2A(1,:) > lonMin) ...
    %     & (lon2A(1,:) < lonMax) ...
    % );


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
