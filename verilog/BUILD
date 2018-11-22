load(":verilog.bzl", "verilog_library", "verilog_sources", "verilator_lint", "verilator_compile")

py_binary(
    name = "sourcefiles",
    srcs = [
    	 "sourcefiles.py",
    ],
    visibility = ["//visibility:public"],
)

py_binary(
    name = "verilator_lint",
    srcs = [
        "verilator_lint.py"
    ],
    visibility = ["//visibility:public"],
)

py_binary(
    name = "verilator_compile",
    srcs = [
        "verilator_compile.py"
    ],
    visibility = ["//visibility:public"],
)

verilog_library(
    name = "test",
    srcs = [
        "test.v",
        "test_2.sv"
    ],
)

verilog_sources(
    name = "sf_test",
    srcs = [
        "top.v",
    ],
    deps = [
        ":test",
    ],
)

verilator_lint(
    name = "lint",
    top = "top",
    srcs = [
        "top.v",
    ],
    deps = [
        ":test",
    ],
)

verilator_compile(
    name = "comp",
    top = "top",
    srcs = [
        "top.v",
    ],
    deps = [
        ":test",
    ],
)