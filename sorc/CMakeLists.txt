cmake_minimum_required(VERSION 3.15)

# Get the version from the VERSION file.
#file(STRINGS "VERSION" pVersion)
set(pVersion 1.0.0)

project(gldas VERSION ${pVersion} LANGUAGES Fortran)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/CMakeModules/Modules)

include(GNUInstallDirs)

# Build type
if(NOT CMAKE_BUILD_TYPE MATCHES "^(Debug|Release|RelWithDebInfo|MinSizeRel)$")
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE
      "Release"
      CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
                                               "MinSizeRel" "RelWithDebInfo")
endif()

# Set default compiler flags.
if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -g -traceback")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -check -check bounds -check noarg_temp_created -check nopointer -fp-stack-check -fstack-protector-all -fpe0 -debug -ftrapuv")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -g -fbacktrace")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -ggdb -fno-unsafe-math-optimizations -frounding-math -fsignaling-nans -ffpe-trap=invalid,zero,overflow -fbounds-check")
  if(CMAKE_Fortran_COMPILER_VERSION VERSION_GREATER_EQUAL 10)
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fallow-argument-mismatch")
  endif()
endif()

# Find packages.
find_package(MPI REQUIRED)

if(OPENMP)
  find_package(OpenMP REQUIRED)
endif()

find_package(NetCDF REQUIRED COMPONENTS Fortran)
find_package(ESMF REQUIRED)

find_package(bacio REQUIRED)
find_package(w3nco REQUIRED)
find_package(w3emc REQUIRED)
find_package(nemsio REQUIRED)
find_package(sp REQUIRED)

# Build gldas utilities.
add_subdirectory(gdas2gldas.fd)
add_subdirectory(gldas2gdas.fd)
add_subdirectory(gldas_forcing.fd)
add_subdirectory(gldas_post.fd)
add_subdirectory(gldas_rst.fd)
#add_subdirectory(gldas_model.fd)
