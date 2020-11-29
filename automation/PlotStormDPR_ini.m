stormName='tmp';

fname1C='1C-R.GPM.GMI.XCAL2016-C.20200827-S022853-E040126.036907.V05A.HDF5';
fname2A='2A.GPM.DPR.V820180723.20200827-S024128-E031127.V06A.RT-H5';

centerCoord=[29.8,-93.3];

outPath='C:\Users\DennisLee\src\repo\storm-plot-3D\automation\out';

outFname='test';

PlotStormDPR(stormName, fname1C, fname2A, centerCoord, outPath, outFname)
