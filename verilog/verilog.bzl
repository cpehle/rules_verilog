VerilogFiles = provider("transitive_sources")

def get_transitive_srcs(srcs, deps):
    """Obtain the source files for a target and its transitive dependencies.
    Args:
      srcs: a list of source files
      deps: a list of targets that are direct dependencies
    Returns:
      a collection of the transitive sources
    """
    return depset(
        srcs,
        transitive = [dep[VerilogFiles].transitive_sources for dep in deps],
    )

def _verilog_library_impl(ctx):
    trans_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    return [
        VerilogFiles(transitive_sources = trans_srcs),
        DefaultInfo(files = trans_srcs),
    ]

verilog_library = rule(
    implementation = _verilog_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
    },
)

def _verilator_compile_impl(ctx):
    verilator = ctx.executable._verilator_compile
    trans_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    srcs_list = trans_srcs.to_list()
    top = ctx.files.top
    out = ctx.outputs.out
    ctx.actions.run(
        executable = verilator,
        arguments = ['--cc'] + ['--top-module top'] + [src.path for src in srcs_list],
        inputs = srcs_list,
        outputs = [out],
    )

verilator_compile = rule(
    implementation = _verilator_compile_impl,
    attrs = {
        "top": attr.label(allow_files = True),
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "_verilator_compile": attr.label(
            default = Label("//verilog:verilator_compile"),
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {"out": "obj_dir/Vtop.h"},
)

def _verilator_lint_impl(ctx):
    verilator = ctx.executable._verilator_lint
    trans_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    srcs_list = trans_srcs.to_list()
    top = ctx.files.top
    out = ctx.outputs.out
    ctx.actions.run(
        executable = verilator,
        arguments = [out.path] + ['--lint-only'] + ['--top-module top'] + [src.path for src in srcs_list],
        inputs = srcs_list,
        outputs = [out],
    )

verilator_lint = rule(
    implementation = _verilator_lint_impl,
    attrs = {
        "top": attr.label(allow_files = True),
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "_verilator_lint": attr.label(
            default = Label("//verilog:verilator_lint"),
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {"out": "%{name}.lint_result"},
)

def _verilog_sources_impl(ctx):
    sourcefiles = ctx.executable._sourcefiles 
    out = ctx.outputs.out
    trans_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    srcs_list = trans_srcs.to_list()
    ctx.actions.run(
        executable = sourcefiles,
        arguments = [out.path] + [src.path for src in srcs_list],
        inputs = srcs_list,
        outputs = [out],
    )

verilog_sources = rule(
    implementation = _verilog_sources_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "_sourcefiles": attr.label(
            default = Label("//verilog:sourcefiles"),
            allow_files = True,
            executable = True,
            cfg = "host",
        ),
    },
    outputs = {"out": "%{name}.tcl"},
)

driver_template = """\
#include <iostream>
#include <stdlib.h>
#include "V{module}.h"
#include "verilated.h"
#include "verilated_vpi.h"
#if VM_TRACE
#include <verilated_vcd_c.h>
#endif
using namespace std;

namespace
{
vluint64_t currentTime = 0;
}

// Called whenever the $time variable is accessed.
double sc_time_stamp()
{
    return currentTime;
}

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    Verilated::debug(0);

    time_t t1;
    time(&t1);
    srand48((long) t1);

    V{module} *testbench = new V{module};

    testbench->__Vclklast__TOP__reset = 0;
    testbench->reset = 1;
    testbench->clk = 0;
    testbench->eval();

#if VM_TRACE // If verilator was invoked with --trace
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    testbench->trace(tfp, 99);
    tfp->open("trace.vcd");
#endif

    while (!Verilated::gotFinish())
    {
        if (currentTime == 4)
            testbench->reset = 0;

        testbench->clk = !testbench->clk;
        testbench->eval();
#if VM_TRACE
        tfp->dump(currentTime); // Create waveform trace for this timestamp
#endif

        currentTime++;
    }

#if VM_TRACE
    tfp->close();
#endif

    testbench->final();
    delete testbench;

    return 0;
}
"""

def _verilator_test_impl(ctx):
    driver = ctx.actions.declare_file("%s.cpp" % ctx.label.name)
    driver_content = driver_template.format(
        module = ctx.label.name
    )
    ctx.actions.write(driver, driver_content)




