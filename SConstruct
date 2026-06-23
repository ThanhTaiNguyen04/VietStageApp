#!/usr/bin/env python
import os
import sys

# Path to the godot-cpp directory
godot_cpp_path = "godot-cpp"

# Load the SConscript from godot-cpp
env = SConscript(os.path.join(godot_cpp_path, "SConstruct"))

# Add our source folder to include path
env.Append(CPPPATH=["src"])

# Gather all C++ source files
sources = Glob("src/*.cpp")

# Compile dynamic library and output to bin/libvietstage
target_path = "bin/libvietstage"
library = env.SharedLibrary(
    target=target_path,
    source=sources
)

Default(library)
