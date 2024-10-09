cmake_minimum_required(VERSION 3.18)

# Project Metadata
project(gpu_ipc LANGUAGES CXX CUDA)

# Set the build type to Release by default if not specified
if(UNIX AND NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose Release or Debug" FORCE)
endif()

# Set compiler flags
if(UNIX)
    set(CMAKE_CXX_FLAGS_RELEASE "-O3")
endif()

# Set CUDA version and path
find_package(CUDA 11.8 REQUIRED)
# Set CUDA Compiler
if(UNIX AND NOT DEFINED CMAKE_CUDA_COMPILER)
    set(CMAKE_CUDA_COMPILER "/usr/local/cuda-11.8/bin/nvcc" CACHE FILEPATH "Path to CUDA Compiler")
endif()

# Set CUDA standard and architecture
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_ARCHITECTURES "60;70;75;80;86")
cmake_policy(SET CMP0146 NEW)


# Find required packages
find_package(Eigen3 3.4 REQUIRED)
find_package(GLEW REQUIRED)
find_package(GLUT REQUIRED)
find_package(OpenGL REQUIRED)

# Define executable
add_executable(gipc)

# Include directories
target_include_directories(gipc PRIVATE "${PROJECT_SOURCE_DIR}/GPU_IPC")

# Gather sources and headers
file(GLOB_RECURSE GIPC_SOURCES CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/GPU_IPC/*.cu" "${PROJECT_SOURCE_DIR}/GPU_IPC/*.cpp")
file(GLOB_RECURSE GIPC_HEADERS CONFIGURE_DEPENDS "${PROJECT_SOURCE_DIR}/GPU_IPC/*.h" "${PROJECT_SOURCE_DIR}/GPU_IPC/*.cuh" "${PROJECT_SOURCE_DIR}/GPU_IPC/*.hpp" "${PROJECT_SOURCE_DIR}/GPU_IPC/*.inl" "${PROJECT_SOURCE_DIR}/GPU_IPC/*.inc")

# Add sources to the target
target_sources(gipc PRIVATE ${GIPC_SOURCES} ${GIPC_HEADERS})

# Define directories for assets and output
target_compile_definitions(gipc PRIVATE GIPC_ASSETS_DIR="${PROJECT_SOURCE_DIR}/Assets/")
target_compile_definitions(gipc PRIVATE GIPC_OUTPUT_DIR="${PROJECT_SOURCE_DIR}/Output/")

# Define preprocessor macros
target_compile_definitions(gipc PRIVATE USE_SNK SVD_DOUBLE ADAPTIVE_KAPPA)

# Link CUDA and other required libraries
target_link_libraries(gipc PRIVATE 
    cusparse cublas cusolver cudart_static 
    GLUT::GLUT GLEW::GLEW OpenGL::GLU Eigen3::Eigen
)

# Set compilation features
target_compile_features(gipc PRIVATE cxx_std_17 cuda_std_17)

# Set CUDA properties for the target
set_target_properties(gipc PROPERTIES
    CUDA_EXTENSIONS ON
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
)

# Set CUDA compilation options
# Use separate compile options for public and private to avoid ambiguity
target_compile_options(gipc PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:
        --use_fast_math
        -lineinfo
        --ptxas-options=-allow-expensive-optimizations=true
        -Xcudafe 
        "--display_error_number --diag_suppress=implicit_return_from_non_void_function --diag_suppress=2642"
    >
)

target_compile_options(gipc PUBLIC
    $<$<COMPILE_LANGUAGE:CUDA>:
        --extended-lambda
        --expt-relaxed-constexpr
        --default-stream=per-thread
    >
)

# Organize source files into groups for IDEs
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${GIPC_SOURCES} ${GIPC_HEADERS})
