cmake_minimum_required(VERSION 3.16)
project(mandelbrot LANGUAGES CUDA CXX)

set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CXX_STANDARD 20)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/mandelbrot/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/mandelbrot/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/mandelbrot/bin)

add_subdirectory(ext/SFML)

add_executable(mandelbrot
        src/main.cpp
        src/View.cpp
        src/Renderer.cu
        )

add_custom_command(TARGET mandelbrot POST_BUILD COMMAND
        ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_SOURCE_DIR}/ext/JetBrainsMono
        ${CMAKE_BINARY_DIR}/mandelbrot/ext/JetBrainsMono
        )

target_include_directories(mandelbrot PRIVATE src)

target_link_libraries(mandelbrot
        sfml-system
        sfml-window
        sfml-graphics
        )

set_target_properties(mandelbrot PROPERTIES CUDA_ARCHITECTURES native)
set_target_properties(mandelbrot PROPERTIES CUDA_SEPARABLE_COMPILATION ON)
