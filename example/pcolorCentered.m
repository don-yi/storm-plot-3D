function handle = pcolorCentered(lg1,lt1,map1)
% pcolor won't do a checkerboard square centered on the datapoint, so
% instead, I've come up with this hack to trick it into centering the points.
% Tony Wimmers (CIMSS) 2004

[rows1,cols1]=size(map1);
lt2(2:rows1,2:cols1)=0.25*( ...
    lt1(1:rows1-1,1:cols1-1) + ...
    lt1(1:rows1-1,2:cols1) + ...
    lt1(2:rows1,1:cols1-1) + ...
    lt1(2:rows1,2:cols1));
lg2(2:rows1,2:cols1)=0.25*( ...
    lg1(1:rows1-1,1:cols1-1) + ...
    lg1(1:rows1-1,2:cols1) + ...
    lg1(2:rows1,1:cols1-1) + ...
    lg1(2:rows1,2:cols1));
lt2(1,:)=2*lt2(2,:)-lt2(3,:);
lt2(rows1+1,:)=2*lt2(rows1,:)-lt2(rows1-1,:);
lt2(:,1)=2*lt2(:,2)-lt2(:,3);
lt2(:,cols1+1)=2*lt2(:,cols1)-lt2(:,cols1-1);
lg2(1,:)=2*lg2(2,:)-lg2(3,:);
lg2(rows1+1,:)=2*lg2(rows1,:)-lg2(rows1-1,:);
lg2(:,1)=2*lg2(:,2)-lg2(:,3);
lg2(:,cols1+1)=2*lg2(:,cols1)-lg2(:,cols1-1);
map2=map1;
map2(rows1+1,:)=NaN;
map2(:,cols1+1)=NaN;

%handle=pcolor(lg2,lt2,map2);
handle=pcolorm(lg2,lt2,map2);
%setm(handle,'EdgeColor','none');
