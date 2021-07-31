if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -FR -convert big_endian")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O0")
  set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -check -check bounds -check noarg_temp_created -check nopointer -fp-stack-check -fstack-protector-all -fpe0 -debug -ftrapuv")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-line-length-none -fconvert=big-endian")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -ggdb -fno-unsafe-math-optimizations -frounding-math -fsignaling-nans -ffpe-trap=invalid,zero,overflow -fbounds-check")
endif()

list(APPEND fortran_src gldas_noahmp_rst.f)

set(exe_name gldas_noahmp_rst.x)
add_executable(${exe_name} ${fortran_src})
target_link_libraries(${exe_name} PRIVATE bacio::bacio_4
                                          w3nco::w3nco_4
                                          nemsio::nemsio)

install(TARGETS ${exe_name} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
