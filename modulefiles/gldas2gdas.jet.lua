help([[
Load environment to run GLDAS on Jet
]])

prepend_path("MODULEPATH", "/lfs4/HFIP/hfv3gfs/role.epic/hpc-stack/libs/intel-18.0.5.274/modulefiles/stack")

hpc_ver=os.getenv("hpc_ver") or "1.2.0"
load(pathJoin("hpc", hpc_ver))

hpc_intel_ver=os.getenv("hpc_intel_ver") or "18.0.5.274"
load(pathJoin("hpc-intel", hpc_intel_ver))

impi_ver=os.getenv("impi_ver") or "2018.4.274"
load(pathJoin("hpc-impi", impi_ver))

w3nco_ver=os.getenv("w3nco_ver") or "2.4.1"
nemsio_ver=os.getenv("nemsio_ver") or "2.5.2"
bacio_ver=os.getenv("bacio_ver") or "2.4.1"
sp_ver=os.getenv("sp_ver") or "2.3.3"
load(pathJoin("w3nco", w3nco_ver))
load(pathJoin("nemsio", nemsio_ver))
load(pathJoin("bacio", bacio_ver))
load(pathJoin("sp", sp_ver))

hdf5_ver=os.getenv("hdf5_ver") or "1.10.6"
netcdf_ver=os.getenv("netcdf_ver") or "4.7.4"
esmf_ver=os.getenv("esmf_ver") or "8.0.1"

load(pathJoin("hdf5", hdf5_ver))
load(pathJoin("netcdf", netcdf_ver))
load(pathJoin("esmf", esmf_ver))

whatis("Description: GLDAS run environment")
