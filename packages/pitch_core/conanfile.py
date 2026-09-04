from conan import ConanFile
from conan.tools.cmake import CMake, CMakeDeps, CMakeToolchain, cmake_layout
from conan.tools.files import copy
import os


class ToneMatePitchCoreConan(ConanFile):
    name = "tonemate-pitch-core"
    version = "0.1.0-alpha.1"
    package_type = "library"
    license = "Proprietary"
    author = "Kugnus Lab"
    url = "https://github.com/souluk319/tone-mate"
    description = "ToneMate cross-platform pitch math and stable C ABI"
    topics = ("audio", "pitch", "dsp", "tonemate")

    settings = "os", "arch", "compiler", "build_type"
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": True}

    exports_sources = "CMakeLists.txt", "include/*", "src/*", "LICENSE"

    def config_options(self):
        if self.settings.os == "Windows":
            self.options.rm_safe("fPIC")

    def configure(self):
        if self.options.shared:
            self.options.rm_safe("fPIC")

    def layout(self):
        cmake_layout(self)

    def generate(self):
        CMakeDeps(self).generate()
        toolchain = CMakeToolchain(self)
        toolchain.variables["BUILD_TESTING"] = False
        toolchain.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        copy(self, "LICENSE", src=self.source_folder, dst=os.path.join(self.package_folder, "licenses"))
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.libs = ["tonemate_pitch_core"]
        self.cpp_info.set_property("cmake_file_name", "ToneMatePitchCore")
        self.cpp_info.set_property("cmake_target_name", "ToneMate::PitchCore")
