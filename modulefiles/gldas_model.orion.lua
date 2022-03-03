help([[
Load environment to run GLDAS on Orion
]])

prepend_path("MODULEPATH", "/apps/contrib/NCEP/libs/hpc-stack-gfsv16/modulefiles/stack")

hpc_ver=os.getenv("hpc_ver") or "1.2.0"
load(pathJoin("hpc", hpc_ver))

hpc_intel_ver=os.getenv("hpc_intel_ver") or "2022.1.2"
load(pathJoin("hpc-intel", hpc_intel_ver))

impi_ver=os.getenv("impi_ver") or "2022.1.2"
load(pathJoin("hpc-impi", impi_ver))

w3emc_ver=os.getenv("w3emc_ver") or "2.9.2"
w3nco_ver=os.getenv("w3nco_ver") or "2.4.1"
bacio_ver=os.getenv("bacio_ver") or "2.4.1"
sp_ver=os.getenv("sp_ver") or "2.3.3"
ip_ver=os.getenv("ip_ver") or "3.3.3"
load(pathJoin("w3emc", w3emc_ver))
load(pathJoin("w3nco", w3nco_ver))
load(pathJoin("bacio", bacio_ver))
load(pathJoin("sp", sp_ver))
load(pathJoin("ip", ip_ver))

whatis("Description: GLDAS run environment")
