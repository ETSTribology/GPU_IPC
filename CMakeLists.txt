cmake_minimum_required(VERSION 3.18)

# Project metadata and language setup
project(gpu_ipc LANGUAGES CXX CUDA VERSION 1.0)

# Default build type and optimization flags
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose Release or Debug" FORCE)
endif()

# Set CUDA architecture with a default if not provided
if(NOT DEFINED CUDA_ARCHITECTURES)
    set(CUDA_ARCHITECTURES "60" CACHE STRING "CUDA architectures to compile for")
endif()

# Set CUDA toolkit root directory if not already set
if(NOT DEFINED CUDA_TOOLKIT_ROOT_DIR)
    set(CUDA_TOOLKIT_ROOT_DIR "/usr/local/cuda" CACHE PATH "CUDA Toolkit root directory")
endif()

# Set CUDA compiler path only if not auto-detected
find_program(CMAKE_CUDA_COMPILER NAMES nvcc 
    PATHS 
    ${CUDA_TOOLKIT_ROOT_DIR}/bin
    /usr/local/cuda/bin 
    /opt/cuda/bin 
    NO_DEFAULT_PATH
)
if(NOT CMAKE_CUDA_COMPILER)
    message(FATAL_ERROR "CUDA compiler (nvcc) not found. Please ensure CUDA is installed and nvcc is in your PATH.")
endif()

# Optionally enable ccache
option(USE_CCACHE "Enable ccache for faster builds" OFF)
if(USE_CCACHE)
    find_program(CCACHE_FOUND ccache)
    if(CCACHE_FOUND)
        message(STATUS "ccache found and enabled.")
        set(CMAKE_CXX_COMPILER_LAUNCHER ccache)
        set(CMAKE_CUDA_COMPILER_LAUNCHER ccache)
    else()
        message(WARNING "ccache not found, builds may be slower. To enable, install ccache or set USE_CCACHE=OFF.")
    endif()
else()
    message(STATUS "ccache not enabled by user (USE_CCACHE=OFF).")
endif()

# Optimization flags for Release mode
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
endif()

# Find required packages and handle errors if missing
find_package(Eigen3 REQUIRED)
find_package(GLEW REQUIRED)
find_package(GLUT REQUIRED)
find_package(OpenGL REQUIRED)

# Enhanced CUDA library search paths
list(APPEND CUDA_LIBRARY_SEARCH_PATHS
    "${CMAKE_CUDA_IMPLICIT_LINK_DIRECTORIES}"
    "${CUDA_TOOLKIT_ROOT_DIR}/lib64"
    "${CUDA_TOOLKIT_ROOT_DIR}/lib"
    "/usr/local/cuda/lib64"
    "/usr/lib/x86_64-linux-gnu"
)

# Locate CUDA libraries explicitly with enhanced search paths
find_library(CUDA_CUSPARSE_LIBRARY cusparse
    HINTS ${CUDA_LIBRARY_SEARCH_PATHS}
    NO_DEFAULT_PATH
)
find_library(CUDA_CUBLAS_LIBRARY cublas
    HINTS ${CUDA_LIBRARY_SEARCH_PATHS}
    NO_DEFAULT_PATH
)
find_library(CUDA_CUSOLVER_LIBRARY cusolver
    HINTS ${CUDA_LIBRARY_SEARCH_PATHS}
    NO_DEFAULT_PATH
)
find_library(CUDA_CUDART_LIBRARY cudart_static
    HINTS ${CUDA_LIBRARY_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

# Verbose output for debugging library paths
message(STATUS "CUDA Library Search Paths: ${CUDA_LIBRARY_SEARCH_PATHS}")
message(STATUS "Found CUSPARSE: ${CUDA_CUSPARSE_LIBRARY}")
message(STATUS "Found CUBLAS: ${CUDA_CUBLAS_LIBRARY}")
message(STATUS "Found CUSOLVER: ${CUDA_CUSOLVER_LIBRARY}")
message(STATUS "Found CUDART: ${CUDA_CUDART_LIBRARY}")

if(NOT CUDA_CUSPARSE_LIBRARY OR NOT CUDA_CUBLAS_LIBRARY OR NOT CUDA_CUSOLVER_LIBRARY OR NOT CUDA_CUDART_LIBRARY)
    message(FATAL_ERROR "Required CUDA libraries not found. Please ensure they are installed and available.")
endif()

# Display a message summarizing the configuration
message(STATUS "Building for CUDA architecture: ${CUDA_ARCHITECTURES}")
message(STATUS "CUDA Compiler: ${CMAKE_CUDA_COMPILER}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# Source files organization
file(GLOB_RECURSE GIPC_SOURCES CONFIGURE_DEPENDS "GPU_IPC/*.cu" "GPU_IPC/*.cpp")
file(GLOB_RECURSE GIPC_HEADERS CONFIGURE_DEPENDS "GPU_IPC/*.h" "GPU_IPC/*.cuh" "GPU_IPC/*.hpp" "GPU_IPC/*.inl" "GPU_IPC/*.inc")

# Define the executable target
add_executable(gipc ${GIPC_SOURCES} ${GIPC_HEADERS})

# Include directories for target
target_include_directories(gipc 
    PRIVATE 
        "GPU_IPC/"
        ${CUDA_TOOLKIT_ROOT_DIR}/include
)

# Set asset and output directories as compile-time definitions
target_compile_definitions(gipc PRIVATE 
    GIPC_ASSETS_DIR="${CMAKE_CURRENT_SOURCE_DIR}/Assets/" 
    GIPC_OUTPUT_DIR="${CMAKE_CURRENT_SOURCE_DIR}/Output/"
    USE_SNK
    SVD_DOUBLE
    ADAPTIVE_KAPPA
)

# Link CUDA and other necessary libraries with explicit error checking
target_link_libraries(gipc PRIVATE 
    ${CUDA_CUSPARSE_LIBRARY} 
    ${CUDA_CUBLAS_LIBRARY} 
    ${CUDA_CUSOLVER_LIBRARY} 
    ${CUDA_CUDART_LIBRARY} 
    GLUT::GLUT 
    GLEW::GLEW 
    OpenGL::GLU 
    Eigen3::Eigen
)

# CUDA-specific properties and options
set_target_properties(gipc PROPERTIES
    CUDA_ARCHITECTURES ${CUDA_ARCHITECTURES}
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
)

# CUDA compilation flags
target_compile_options(gipc
    PRIVATE $<$<COMPILE_LANGUAGE:CUDA>: 
        --use_fast_math 
        -lineinfo 
        --ptxas-options=-allow-expensive-optimizations=true 
        -Xcudafe 
        "--display_error_number --diag_suppress=implicit_return_from_non_void_function --diag_suppress=2642"
    >
    PUBLIC $<$<COMPILE_LANGUAGE:CUDA>: 
        --extended-lambda 
        --expt-relaxed-constexpr 
        --default-stream=per-thread
    >
)

# Organize source files in IDEs for easier navigation
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${GIPC_SOURCES} ${GIPC_HEADERS})

# Output configuration summary
message(STATUS "Configuration Summary:")
message(STATUS "  - C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  - CUDA Standard: ${CMAKE_CUDA_STANDARD}")
message(STATUS "  - CUDA Architectures: ${CUDA_ARCHITECTURES}")
message(STATUS "  - CUDA Toolkit Root: ${CUDA_TOOLKIT_ROOT_DIR}")
message(STATUS "  - Eigen3: ${Eigen3_FOUND}")
message(STATUS "  - GLEW: ${GLEW_FOUND}")
message(STATUS "  - GLUT: ${GLUT_FOUND}")
message(STATUS "  - OpenGL: ${OpenGL_FOUND}")
