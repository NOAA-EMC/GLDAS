if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -free -convert big_endian")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O3 -fp-model precise -ftz -fast-transcendentals -no-prec-div -no-prec-sqrt -align array64byte")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fconvert=big-endian")
endif()

list(APPEND c_src)

list(APPEND fortran_src ${gldas_model_srcs})

set(exe_name gldas_model.x)
add_executable(${exe_name} ${fortran_src})
target_link_libraries(${exe_name} PRIVATE ${gldas_model_libdeps})

install(TARGETS ${exe_name} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
