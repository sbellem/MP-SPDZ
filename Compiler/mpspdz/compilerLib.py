from collections import namedtuple

from mpspdz.program import Program
from mpspdz.config import *  # noqa F403
from mpspdz.exceptions import *  # noqa F403
from . import instructions, instructions_base, types, comparison
from .GC import types as GC_types

# import sys


def run(args, options, merge_opens=True, reallocate=True, debug=False, *, source=None):
    """ Compile a file and output a Program object.

    If merge_opens is set to True, will attempt to merge any parallelisable open
    instructions. """

    if isinstance(args, str):
        args = (args,)

    prog = Program(args, options, source=source)
    instructions.program = prog
    instructions_base.program = prog
    types.program = prog
    comparison.program = prog
    prog.DEBUG = debug
    VARS["program"] = prog  # noqa F405
    if options.binary:
        VARS["sint"] = GC_types.sbitintvec.get_type(int(options.binary))  # noqa F405
        VARS["sfix"] = GC_types.sbitfix  # noqa F405
    comparison.set_variant(options)

    print("Compiling file", prog.infile)

    if instructions_base.Instruction.count != 0:
        print("instructions count", instructions_base.Instruction.count)
        instructions_base.Instruction.count = 0
    # make compiler modules directly accessible

    # sys.path.insert(0, "Compiler")

    # create the tapes
    # exec(compile(open(prog.infile).read(), prog.infile, "exec"), VARS)  # noqa F405
    exec(compile(prog.source, "<string>", "exec"), VARS)  # noqa F405

    # optimize the tapes
    for tape in prog.tapes:
        tape.optimize(options)

    if prog.tapes:
        prog.update_req(prog.curr_tape)

    if prog.req_num:
        print("Program requires:")
        for x in prog.req_num.pretty():
            print(x)

    if prog.verbose:
        print("Program requires:", repr(prog.req_num))
        print("Cost:", 0 if prog.req_num is None else prog.req_num.cost())
        print("Memory size:", dict(prog.allocated_mem))

    # finalize the memory
    prog.finalize_memory()

    return prog


compile_prog = run

option_defaults = {
    "merge_opens": True,
    "outfile": None,
    "asmoutfile": None,
    "galois": 40,
    "debug": None,
    "comparison": "log",
    "reorder_between_opens": True,
    "preserve_mem_order": False,
    "optimize_hard": None,
    "noreallocate": False,
    "max_parallel_open": False,
    "dead_code_elimination": False,
    "profile": None,
    "stop": None,
    "ring": 0,
    "binary": 0,
    "field": 0,
    "insecure": None,
    "budget": 100000,
    "mixed": None,
    "edabit": None,
    "cisc": None,
    "verbose": None,
}
Options = namedtuple(
    "Options", option_defaults.keys(), defaults=option_defaults.values()
)

# for dest, option in parser_options.items():
#    attrs = {attr: value for attr, value in option.items() if attr != "opt_str"}
#    parser.add_option(*option["opt_str"], dest=dest, **attr)

parser_options = {
    "merge_opens": {
        "opt_str": ("-n", "--nomerge"),
        "action": "store_false",
        "default": True,
        "help": "don't attempt to merge open instructions",
    },
    "outfile": {
        "opt_str": ("-o", "--output"),
        "default": None,
        "help": "specify output file",
    },
}

#    parser.add_option(
#        "-a", "--asm-output", dest="asmoutfile", help="asm output file for debugging"
#    )
#    parser.add_option(
#        "-g",
#        "--galoissize",
#        dest="galois",
#        default=40,
#        help="bit length of Galois field",
#    )
#    parser.add_option(
#        "-d",
#        "--debug",
#        action="store_true",
#        dest="debug",
#        help="keep track of trace for debugging",
#    )
#    parser.add_option(
#        "-c",
#        "--comparison",
#        dest="comparison",
#        default="log",
#        help="comparison variant: log|plain|inv|sinv",
#    )
#    parser.add_option(
#        "-r",
#        "--noreorder",
#        dest="reorder_between_opens",
#        action="store_false",
#        default=True,
#        help="don't attempt to place instructions between start/stop opens",
#    )
#    parser.add_option(
#        "-M",
#        "--preserve-mem-order",
#        action="store_true",
#        dest="preserve_mem_order",
#        default=False,
#        help="preserve order of memory instructions; possible efficiency loss",
#    )
#    parser.add_option(
#        "-O",
#        "--optimize-hard",
#        action="store_true",
#        dest="optimize_hard",
#        help="currently not in use",
#    )
#    parser.add_option(
#        "-u",
#        "--noreallocate",
#        action="store_true",
#        dest="noreallocate",
#        default=False,
#        help="don't reallocate",
#    )
#    parser.add_option(
#        "-m",
#        "--max-parallel-open",
#        dest="max_parallel_open",
#        default=False,
#        help="restrict number of parallel opens",
#    )
#    parser.add_option(
#        "-D",
#        "--dead-code-elimination",
#        action="store_true",
#        dest="dead_code_elimination",
#        default=False,
#        help="eliminate instructions with unused result",
#    )
#    parser.add_option(
#        "-P",
#        "--profile",
#        action="store_true",
#        dest="profile",
#        help="profile compilation",
#    )
#    parser.add_option(
#        "-s", "--stop", action="store_true", dest="stop", help="stop on register errors"
#    )
#    parser.add_option(
#        "-R",
#        "--ring",
#        dest="ring",
#        default=0,
#        help="bit length of ring (default: 0 for field)",
#    )
#    parser.add_option(
#        "-B",
#        "--binary",
#        dest="binary",
#        default=0,
#        help="bit length of sint in binary circuit (default: 0 for arithmetic)",
#    )
#    parser.add_option(
#        "-F",
#        "--field",
#        dest="field",
#        default=0,
#        help="bit length of sint modulo prime (default: 64)",
#    )
#    parser.add_option(
#        "-I",
#        "--insecure",
#        action="store_true",
#        dest="insecure",
#        help="activate insecure functionality for benchmarking",
#    )
#    parser.add_option(
#        "-b",
#        "--budget",
#        dest="budget",
#        default=100000,
#        help="set budget for optimized loop unrolling " "(default: 100000)",
#    )
#    parser.add_option(
#        "-X",
#        "--mixed",
#        action="store_true",
#        dest="mixed",
#        help="mixing arithmetic and binary computation",
#    )
#    parser.add_option(
#        "-Y",
#        "--edabit",
#        action="store_true",
#        dest="edabit",
#        help="mixing arithmetic and binary computation using edaBits",
#    )
#    parser.add_option(
#        "-C",
#        "--CISC",
#        action="store_true",
#        dest="cisc",
#        help="faster CISC compilation mode",
#    )
#    parser.add_option(
#        "-v",
#        "--verbose",
#        action="store_true",
#        dest="verbose",
#        help="more verbose output",
#    )
