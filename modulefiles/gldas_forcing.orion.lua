help([[
Load environment to run GLDAS on Orion
]])

prepend_path("MODULEPATH", "/apps/contrib/NCEP/libs/hpc-stack-gfsv16/modulefiles/stack")

hpc_ver=os.getenv("hpc_ver") or "1.2.0"
load(pathJoin("hpc", hpc_ver))

hpc_intel_ver=os.getenv("hpc_intel_ver") or "2022.1.2"
load(pathJoin("hpc-intel", hpc_intel_ver))

w3nco_ver=os.getenv("w3nco_ver") or "2.4.1"
bacio_ver=os.getenv("bacio_ver") or "2.4.1"
load(pathJoin("w3nco", w3nco_ver))
load(pathJoin("bacio", bacio_ver))

whatis("Description: GLDAS run environment")
