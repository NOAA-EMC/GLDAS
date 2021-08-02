if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -FR -convert big_endian")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O0")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -ffree-form -fconvert=big-endian")
endif()

list(APPEND fortran_src gldas_post.f)

set(exe_name gldas_post.x)
add_executable(${exe_name} ${fortran_src})
target_link_libraries(${exe_name} PRIVATE bacio::bacio_4
                                          w3nco::w3nco_4
                                          nemsio::nemsio)

install(TARGETS ${exe_name} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
