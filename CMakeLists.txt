cmake_minimum_required(VERSION 3.18)

# Project metadata and language setup
project(gpu_ipc LANGUAGES CXX CUDA VERSION 1.0)

# Project meta
# ============
if(UNIX)
    if(NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose Release or Debug" FORCE)
    endif()

    # Append optimization flag to Release build
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")
    endif()

    # Correct CUDA compiler path
    set(CMAKE_CUDA_COMPILER "/usr/local/cuda-11.8/bin/nvcc")
endif()

# Find packages
find_package(Eigen3 REQUIRED)
find_package(GLEW REQUIRED)
find_package(GLUT REQUIRED)
find_package(OpenGL REQUIRED)

# Define the executable target
add_executable(gipc)

# Include directories for target
target_include_directories(gipc PRIVATE "GPU_IPC/")

# Organize source files
file(GLOB_RECURSE GIPC_SOURCE CONFIGURE_DEPENDS 
    "GPU_IPC/*.cu" "GPU_IPC/*.cpp")
file(GLOB_RECURSE GIPC_HEADERS CONFIGURE_DEPENDS 
    "GPU_IPC/*.h" "GPU_IPC/*.cuh" "GPU_IPC/*.hpp" "GPU_IPC/*.inl" "GPU_IPC/*.inc")
target_sources(gipc PRIVATE ${GIPC_SOURCE} ${GIPC_HEADERS})

# Add asset and output directory as compile-time definitions
target_compile_definitions(gipc PRIVATE 
    GIPC_ASSETS_DIR="${CMAKE_CURRENT_SOURCE_DIR}/Assets/"
    GIPC_OUTPUT_DIR="${CMAKE_CURRENT_SOURCE_DIR}/Output/"
    USE_SNK 
    SVD_DOUBLE 
    ADAPTIVE_KAPPA
)

# Link CUDA libraries
target_link_libraries(gipc PRIVATE 
    cusparse 
    cublas 
    cusolver 
    cudart_static
)
target_link_libraries(gipc PRIVATE 
    GLUT::GLUT 
    GLEW::GLEW 
    OpenGL::GLU 
    Eigen3::Eigen
)

# Specify C++ and CUDA standards
target_compile_features(gipc PRIVATE 
    cxx_std_17 
    cuda_std_17
)

# Set CUDA-specific properties
set_target_properties(gipc PROPERTIES
    CUDA_EXTENSIONS ON
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
    CUDA_ARCHITECTURES 86
)

# Set CUDA compilation flags
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
source_group(TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES ${GIPC_SOURCE} ${GIPC_HEADERS})
