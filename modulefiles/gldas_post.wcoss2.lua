help([[
Load environment to run GLDAS on WCOSS2
]])

envvar_ver=os.getenv("envvar_ver") or "1.0"
PrgEnv_intel_ver=os.getenv("PrgEnv_intel_ver") or "8.1.0"
craype_ver=os.getenv("craype_ver") or "2.7.8"
intel_ver=os.getenv("intel_ver") or "19.1.3.304"
cray_mpich_ver=os.getenv("cray_mpich_ver") or "8.1.9"
load(pathJoin("envvar", envvar_ver))
load(pathJoin("PrgEnv-intel", PrgEnv_intel_ver))
load(pathJoin("craype", craype_ver))
load(pathJoin("intel", intel_ver))
load(pathJoin("cray-mpich", cray_mpich_ver))

w3emc_ver=os.getenv("w3emc_ver") or "2.7.3"
w3nco_ver=os.getenv("w3nco_ver") or "2.4.1"
nemsio_ver=os.getenv("nemsio_ver") or "2.5.2"
bacio_ver=os.getenv("bacio_ver") or "2.4.1"
load(pathJoin("w3emc", w3emc_ver))
load(pathJoin("w3nco", w3nco_ver))
load(pathJoin("nemsio", nemsio_ver))
load(pathJoin("bacio", bacio_ver))

whatis("Description: GLDAS run environment")
