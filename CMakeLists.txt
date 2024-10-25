cmake_minimum_required(VERSION 3.18)

# Project metadata and language setup
project(gpu_ipc LANGUAGES CXX CUDA VERSION 1.0)

# Default build type and optimization flags
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose Release or Debug" FORCE)
endif()

# Require specific C++ and CUDA standards
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# Set CUDA architecture with a default if not provided
if(NOT DEFINED CUDA_ARCHITECTURES)
    set(CUDA_ARCHITECTURES "86" CACHE STRING "CUDA architectures to compile for")
endif()

# Set CUDA compiler path only if not auto-detected
find_program(CMAKE_CUDA_COMPILER NAMES nvcc PATHS /usr/local/cuda/bin /opt/cuda/bin NO_DEFAULT_PATH)
if(NOT CMAKE_CUDA_COMPILER)
    message(FATAL_ERROR "CUDA compiler (nvcc) not found. Please ensure CUDA is installed and nvcc is in your PATH.")
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
target_include_directories(gipc PRIVATE "GPU_IPC/")

# Set asset and output directories as compile-time definitions
target_compile_definitions(gipc PRIVATE 
    GIPC_ASSETS_DIR="${CMAKE_CURRENT_SOURCE_DIR}/Assets/" 
    GIPC_OUTPUT_DIR="${CMAKE_CURRENT_SOURCE_DIR}/Output/"
    USE_SNK
    SVD_DOUBLE
    ADAPTIVE_KAPPA
)

# Link CUDA and other necessary libraries with explicit error checking
foreach(lib cusparse cublas cusolver cudart_static GLUT::GLUT GLEW::GLEW OpenGL::GLU Eigen3::Eigen)
    if(TARGET ${lib})
        target_link_libraries(gipc PRIVATE ${lib})
    else()
        message(FATAL_ERROR "Required library ${lib} not found. Please ensure it is installed and available.")
    endif()
endforeach()

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
message(STATUS "  - Eigen3: ${Eigen3_FOUND}")
message(STATUS "  - GLEW: ${GLEW_FOUND}")
message(STATUS "  - GLUT: ${GLUT_FOUND}")
message(STATUS "  - OpenGL: ${OpenGL_FOUND}")
