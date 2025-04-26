add_requires("openssl3", {system = true})
add_requires(
    "c-ares",
    "fmt",
    "zlib",
    "freetype",
    "clipper2 Clipper2_1.5.2",
    "stb",
    "pugixml",
    "libpng",
    "libjpeg-turbo",
    "poly2tri", -- is the library still supported?
    "simdjson",
    "axslcc",
    "box2d v3.1.0"
)

add_requires("astc-encoder", {configs = {cli = false}}) -- enable intrinsics
add_requires("fontconfig", {system = true}) -- linux only lib
add_requires("gtk3", {system = true})

add_requires("glfw", {configs = {wayland = false}})

target("yasio")
    set_kind("shared")
    add_files("3rdparty/yasio/yasio/*.cpp")
    add_includedirs("3rdparty/yasio/", {public = true})
    add_packages("openssl3", "c-ares")

target("convert-utf")
    set_kind("shared")
    add_files("3rdparty/ConvertUTF/*.cpp")
    add_includedirs("3rdparty/ConvertUTF/", {public = true})

target("unzip")
    set_kind("shared")
    add_files("3rdparty/unzip/*.c", "3rdparty/unzip/*.cpp")
    add_includedirs("3rdparty/unzip/", {public = true})
    add_packages("zlib")
    add_defines("NOUNCRYPT=1")

-- TODO: use glad from xrepo
target("glad")
    set_kind("shared")
    add_files("3rdparty/glad/src/*.c")
    add_includedirs("3rdparty/glad/include", {public = true})

target("xxhash")
    set_kind("shared")
    add_files("3rdparty/xxhash/*.c")
    add_includedirs("3rdparty/xxhash", {public = true})

rule("axslcc")
    set_extensions(".frag", ".vert")

    on_buildcmd_file(function(target, batchcmds, sourcefile, opt)
        -- TODO: include dirs
        -- TODO: difference between find_program vs find_tool
        import("lib.detect.find_program")
        local axslcc = assert(find_program("axslcc"), "axslcc not found!")
        local includedir = target:extraconf("rules", "axslcc", "includedir")
        if not path.is_absolute(includedir) then
            includedir = path.join(target:scriptdir(), includedir)
        end
        local flags = {
            "--lang=glsl",
            "--profile=330",
            "--automap",
            "--no-suffix",
            "--err-format=msvc",
            "--defines=MAX_DIRECTIONAL_LIGHT_NUM=1,MAX_POINT_LIGHT_NUM=1,MAX_SPOT_LIGHT_NUM=1",
            "--include-dirs=" .. includedir -- TODO: default should be axmol/core/renderer/shaders
        }
        local extension = path.extension(sourcefile)
        local filename = path.basename(sourcefile)

        batchcmds:show_progress(opt.progress, "${color.build.object}compiling shader via axslcc %s", sourcefile)
        if extension == ".frag" then
            table.append(flags, "--frag=" .. path.absolute(sourcefile))
            filename = filename .. "_fs"
        elseif extension == ".vert" then
            table.append(flags, "--vert=" .. path.absolute(sourcefile))
            filename = filename .. "_vs"
        else
            print("extension " .. extension .. "not supported, file: " .. sourcefile)
        end

        os.mkdir(target:targetdir())
        local outputfile = path.absolute(path.join(target:targetdir(), filename))
        table.append(flags, "--output=" .. outputfile)
        batchcmds:vrunv(axslcc, flags)

        -- add deps
        batchcmds:add_depfiles(sourcefile)
        batchcmds:set_depmtime(os.mtime(outputfile))
        batchcmds:set_depcache(target:dependfile(outputfile))
    end)
rule_end()

target("axmol")
    set_kind("shared")
    add_files(
        "core/*.cpp",
        "core/base/*.cpp",
        "core/platform/*.cpp",
        "core/renderer/*.cpp",
        "core/renderer/backend/*.cpp",
        "core/2d/*.cpp",
        "core/3d/*.cpp",
        "core/math/*.cpp",
        "core/physics/*.cpp",
        "core/ui/*.cpp",
        "core/ui/UIEditBox/UIEditBox.cpp",
        "core/ui/UIEditBox/UIEditBoxImpl-common.cpp",
        "extensions/physics-nodes/src/physics-nodes/*.cpp"
    )

    if is_plat("linux") then
        remove_files("core/base/Controller-android.cpp")
        add_files("core/platform/$(os)/*.cpp")
        add_files("core/renderer/backend/opengl/*.cpp") -- except apple

        add_files(
            "core/ui/UIEditBox/UIEditBoxImpl-linux.cpp"
            -- "core/ui/UIWebView/UIWebViewImpl-linux.cpp",
            -- "core/ui/UIWebView/UIWebView.cpp"
        )

        add_includedirs("core/platform/$(os)", {public = true})
    end

    add_includedirs(
        "core",
        "3rdparty/robin-map/include",
        "3rdparty/",
        "extensions/physics-nodes/src/",
        ".",
        "core/base",
        "core/platform",
        {public = true}
    )

    add_deps("yasio", "convert-utf", "unzip", "glad", "xxhash")
    add_packages(
        "glfw",
        "freetype",
        "clipper2",
        "stb",
        "pugixml",
        "libpng",
        "libjpeg-turbo",
        "astc-encoder",
        "fontconfig",
        "poly2tri",
        "simdjson",
        "gtk3"
    )

    add_packages("axslcc", {host = true})

    add_packages("fmt", {public = true})
    add_packages("box2d", {public = true})
    add_links("pthread")

    add_defines(
        "AX_USE_WEBP=0", "AX_ENABLE_3D=1",
        "AX_VERSION_STR_FULL=\"3.0.0\"",
        "AX_MAX_DIRECTIONAL_LIGHT=1", "AX_MAX_POINT_LIGHT=1", "AX_MAX_SPOT_LIGHT=1",
        "AX_ENABLE_SCRIPT_BINDING=1",
        "_AX_DEBUG=1",
        "AX_ENABLE_PHYSICS=1", {public = true}
    )

    add_rules("axslcc", {includedir = "core/renderer/shaders"})
    add_files("core/**.frag", "core/**.vert")