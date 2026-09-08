cmake_minimum_required(VERSION 3.24)

project(
  tonemate_pitch_core
  VERSION 0.1.0
  DESCRIPTION "ToneMate cross-platform pitch math and C ABI"
  LANGUAGES C CXX
)

include(GNUInstallDirs)
include(CTest)

add_library(tonemate_pitch_core src/pitch_core.cpp src/yin.cpp)
add_library(ToneMate::PitchCore ALIAS tonemate_pitch_core)

target_compile_features(tonemate_pitch_core PUBLIC cxx_std_20)
target_include_directories(
  tonemate_pitch_core
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(
  tonemate_pitch_core
  PROPERTIES
    EXPORT_NAME PitchCore
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN YES
    POSITION_INDEPENDENT_CODE YES
)

if(BUILD_SHARED_LIBS)
  target_compile_definitions(
    tonemate_pitch_core
    PUBLIC TONEMATE_PITCH_CORE_SHARED
    PRIVATE TONEMATE_PITCH_CORE_BUILDING
  )
endif()

if(BUILD_TESTING)
  add_executable(tonemate_pitch_core_tests tests/pitch_core_tests.cpp)
  target_link_libraries(tonemate_pitch_core_tests PRIVATE ToneMate::PitchCore)
  # Existing assert-based checks must also execute in Release builds.
  if(MSVC)
    target_compile_options(tonemate_pitch_core_tests PRIVATE /UNDEBUG)
  else()
    target_compile_options(tonemate_pitch_core_tests PRIVATE -UNDEBUG)
  endif()
  add_test(NAME tonemate_pitch_core_tests COMMAND tonemate_pitch_core_tests)
  add_executable(tonemate_yin_tests tests/yin_tests.cpp)
  target_link_libraries(tonemate_yin_tests PRIVATE ToneMate::PitchCore)
  add_test(NAME tonemate_yin_tests COMMAND tonemate_yin_tests)
  add_executable(tonemate_c_api_tests tests/c_api_tests.c)
  target_compile_features(tonemate_c_api_tests PRIVATE c_std_11)
  target_link_libraries(tonemate_c_api_tests PRIVATE ToneMate::PitchCore)
  add_test(NAME tonemate_c_api_tests COMMAND tonemate_c_api_tests)
endif()

install(
  TARGETS tonemate_pitch_core
  EXPORT ToneMatePitchCoreTargets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(
  EXPORT ToneMatePitchCoreTargets
  FILE ToneMatePitchCoreTargets.cmake
  NAMESPACE ToneMate::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/ToneMatePitchCore
)
