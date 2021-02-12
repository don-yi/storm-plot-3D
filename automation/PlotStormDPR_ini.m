stormName='tmp';

fname1C='1C-R.GPM.GMI.XCAL2016-C.20200827-S022853-E040126.036907.V05A.HDF5';
fname2A='2A.GPM.DPR.V820180723.20200827-S024128-E031127.V06A.RT-H5';
fnameWwlln='ATL_20_13_Laura_WWLLN_Locations.txt';

centerCoord=[29.8,-93.3];
passtime='2020/08/27      02:55:00';

outPath='C:\Users\DennisLee\src\repo\storm-plot-3D\automation\out';
outFname='test';

PlotStormDPR( ...
  stormName, ...
  fname1C, fname2A, fnameWwlln, ...
  centerCoord, passtime, ...
  outPath, outFname ...
)
