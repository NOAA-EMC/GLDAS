help([[
Load environment to run GLDAS on S4
]])

license_ver=os.getenv("license_ver") or "S4"
load(pathJoin("license_intel", license_ver))

prepend_path("MODULEPATH", "/data/prod/hpc-stack/modulefiles/stack")

hpc_ver=os.getenv("hpc_ver") or "1.2.0"
load(pathJoin("hpc", hpc_ver))

hpc_intel_ver=os.getenv("hpc_intel_ver") or "18.0.4"
load(pathJoin("hpc-intel", hpc_intel_ver))

w3nco_ver=os.getenv("w3nco_ver") or "2.4.1"
bacio_ver=os.getenv("bacio_ver") or "2.4.1"
load(pathJoin("w3nco", w3nco_ver))
load(pathJoin("bacio", bacio_ver))

whatis("Description: GLDAS run environment")
