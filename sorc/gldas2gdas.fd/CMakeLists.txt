if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -r8 -i4 -convert big_endian -assume byterecl")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O3 -fp-model precise")
  set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -check -check bounds -check noarg_temp_created -check nopointer -fp-stack-check -fstack-protector-all -fpe0 -debug -ftrapuv")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fdefault-real-8 -fdefault-double-8 -fconvert=big-endian")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -ggdb -fno-unsafe-math-optimizations -frounding-math -fsignaling-nans -ffpe-trap=invalid,zero,overflow -fbounds-check")
endif()

list(APPEND fortran_src
  driver.F90
  input_data.F90
  interp.F90
  model_grid.F90
  setup.f90
  utils.f90
  write_data.F90)

set(exe_name gldas2gdas.x)
add_executable(${exe_name} ${fortran_src})
target_link_libraries(${exe_name} PRIVATE bacio::bacio_4
                                          w3nco::w3nco_d
                                          nemsio::nemsio
                                          sp::sp_d)
target_link_libraries(${exe_name} PRIVATE esmf)
if(OPENMP)
  target_link_libraries(${exe_name} PRIVATE OpenMP::OpenMP_Fortran)
endif()

install(TARGETS ${exe_name} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
