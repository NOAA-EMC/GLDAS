if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -check -check bounds -check noarg_temp_created -check nopointer -fp-stack-check -fstack-protector-all -fpe0 -debug -ftrapuv")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -ggdb -fno-unsafe-math-optimizations -frounding-math -fsignaling-nans -ffpe-trap=invalid,zero,overflow -fbounds-check")
endif()

list(APPEND fortran_src ${gldas_model_srcs})

set(exe_name gldas_model.x)
add_executable(${exe_name} ${fortran_src})
target_link_libraries(${exe_name} PRIVATE ${gldas_model_libdeps})

install(TARGETS ${exe_name} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
