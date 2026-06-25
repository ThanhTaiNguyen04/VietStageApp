#!/usr/bin/env python

env = SConscript("godot-cpp/SConstruct")

# Tweaks to include src/ folder
env.Append(CPPPATH=["src/"])
sources = Glob("src/*.cpp")

# Build target configured for the locations expected in vietstage.gdextension
if env["platform"] == "macos":
    library = env.SharedLibrary(
        "bin/libvietstage.{}.{}.framework/libvietstage.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
    )
elif env["platform"] == "ios":
    if env["ios_simulator"]:
        library = env.StaticLibrary(
            "bin/libvietstage.{}.{}.simulator.a".format(env["platform"], env["target"]),
            source=sources,
        )
    else:
        library = env.StaticLibrary(
            "bin/libvietstage.{}.{}.a".format(env["platform"], env["target"]),
            source=sources,
        )
else:
    library = env.SharedLibrary(
        "bin/libvietstage{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

env.NoCache(library)
Default(library)
