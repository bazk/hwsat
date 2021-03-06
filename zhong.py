#!/usr/bin/env python2

import os, sys
import argparse
import jinja2
import time
import subprocess
import hashlib

ROOT_DIR = os.path.dirname(os.path.realpath(__file__))
TEMPLATES_DIR = os.path.join(ROOT_DIR, "templates")
DEFAULT_WORK_DIR = os.path.join(ROOT_DIR, "work")

def parse_templates(args, variables):
    if not os.path.exists(args.work_dir):
        os.makedirs(args.work_dir)

    engine = jinja2.Environment(
        loader=jinja2.FileSystemLoader(TEMPLATES_DIR),
        extensions=['jinja2.ext.autoescape'],
        autoescape=False)

    engine.globals["variables"] = variables
    engine.globals["len_variables"] = len(variables)

    def apply_tpl(template, output, env={}):
        contents = template.render(env)
        checksum = hashlib.sha1(contents).hexdigest()

        match = False
        try:
            with open(os.path.join(args.work_dir, output), 'rb') as f:
                match = ( checksum == hashlib.sha1(f.read()).hexdigest() )
        except:
            pass

        if not match:
            with open(os.path.join(args.work_dir, output), 'w') as f:
                f.write(contents)

    apply_tpl(engine.get_template('solver.vhd'), 'solver.vhd')
    apply_tpl(engine.get_template('solver_tb.vhd'), 'solver_tb.vhd')
    apply_tpl(engine.get_template('Makefile'), 'Makefile')

    imp_template = engine.get_template('imp.vhd')
    control_template = engine.get_template('control.vhd')

    for var in variables:
        apply_tpl(imp_template, 'imp_%s.vhd' % var["name"], { "current_var": var })
        apply_tpl(control_template, 'control_%s.vhd' % var["name"], { "current_var": var })

    color = 0
    for var in variables:
        var["color"] = color % 9
        color += 1

    apply_tpl(engine.get_template('solver.gtkw'), 'solver.gtkw', {
        "dumpfile": os.path.join(args.work_dir, 'solver.vcd'),
        "savefile": os.path.join(args.work_dir, 'solver.gtkw')
    })

def parse_dimacs(args, input_file):
    tmp_variables = {}
    num_clauses = 0

    for line in input_file.readlines():
        line = line.strip()

        if (len(line) <= 0):
            continue

        if not (line[0].isdigit() or line[0].startswith("-")):
            continue

        clause = []
        for var in line.split():
            try:
                var_int = int(var)
                var_name = "var"+str(abs(var_int))
            except:
                print "PARSE ERROR! Unexpected char: ", line

            if var_int == 0:
                continue

            clause.append( (var_name, 0 if (var_int < 0) else 1) )

        if len(clause) > 0:
            num_clauses += 1

            for (var, val) in clause:
                if not var in tmp_variables:
                    tmp_variables[var] = {
                        "pos_implications": [],
                        "neg_implications": []
                    }

                tmp = []

                for (var2, val2) in clause:
                    if (var == var2) and (val == val2):
                        continue

                    tmp.append("%s(%d)" % (var2, val2))

                if (len(tmp) > 0):
                    if (val == 0):
                        tmp_variables[var]["neg_implications"].append("(%s)" % " and ".join(tmp))
                    else:
                        tmp_variables[var]["pos_implications"].append("(%s)" % " and ".join(tmp))

    variables = []
    for (k,v) in tmp_variables.iteritems():
        var = {
            "name": k
        }

        if len(v["pos_implications"]) > 0:
            var["pos_implications"] = " or ".join(v["pos_implications"])
        else:
            var["pos_implications"] = "'0'"

        if len(v["neg_implications"]) > 0:
            var["neg_implications"] = " or ".join(v["neg_implications"])
        else:
            var["neg_implications"] = "'0'"

        variables.append(var)

    return (sorted(variables, key=lambda var: int(var["name"][3:])), num_clauses)

def compile(args):
    with open(os.devnull, "w") as devnull:
        subprocess.check_call(["make"], cwd=args.work_dir, stdout=devnull)

def run(args):
    print 'c ============================[ Search Statistics ]=============================='
    print 'c |                 |     Conflicts     |     Decisions     |    Backtracks     |'
    print 'c ==============================================================================='

    cmdline = ['./solver_tb']

    if (not args.no_vcd):
        cmdline.append('--vcd=solver.vcd')

    p = subprocess.Popen(cmdline, cwd=args.work_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    sat = False
    values = []

    num_decisions = 0
    num_conflicts = 0
    num_backtracks = 0

    total_time = 0

    while True:
        line = p.stdout.readline()
        if (line == '') and (p.poll() is not None):
            break

        fields = line.strip('\n').split(':')
        timestamp = int(fields[3].lstrip('@')[:-2]) / 1000000000000.0
        tmp = fields[5].lstrip(' ').split(' ')
        cmd = tmp[0]
        args = tmp[1:]

        if (cmd == "STATS"):
            num_decisions = int(args[0])
            num_conflicts = int(args[1])
            num_backtracks = int(args[2])
            print 'c |  %.10f s |  % 16d |  % 16d |  % 16d |' % (timestamp, num_decisions, num_conflicts, num_backtracks)

        elif (cmd == "RESULT"):
            sat = (args[0] == "SAT")
            total_time = timestamp

        elif (cmd == "VALUE"):
            sign = -1 if (args[0][0] == "-") else 1
            var = int(args[0][3:] if (sign == 1) else args[0][4:])
            values.append(sign * var)

    values = sorted(values, key=lambda v: abs(v))

    return (sat, values), (num_decisions, num_conflicts, num_backtracks, total_time)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--no-vcd', action='store_true', help='dont write the simulation vcd file')
    parser.add_argument('--work-dir', help='path to the work dir')
    parser.add_argument('input', nargs='?', help='input dimacs')
    args = parser.parse_args()

    if (args.work_dir):
        args.work_dir = os.path.abspath(args.work_dir)
    else:
        args.work_dir = DEFAULT_WORK_DIR

    start_time = time.time()

    if (args.input is None):
        print 'c Reading from standard input...'
        (variables, num_clauses) = parse_dimacs(args, sys.stdin)
    else:
        with open(args.input) as f:
            (variables, num_clauses) = parse_dimacs(args, f)

    parse_time = time.time() - start_time

    print 'c ============================[ Problem Statistics ]============================='
    print 'c |                                                                             |'
    print 'c |  Number of variables:      % 8d                                         |' % len(variables)
    print 'c |  Number of clauses:        % 8d                                         |' % (num_clauses)
    print 'c |  Parse time:               % 8.2f s                                       |' % (parse_time)

    start_time = time.time()
    parse_templates(args, variables)
    templ_parse_time = time.time() - start_time

    print 'c |  Template parse time:      % 8.2f s                                       |' % (templ_parse_time)

    start_time = time.time()
    compile(args)
    compile_time = time.time() - start_time

    print 'c |  Compile time:             % 8.2f s                                       |' % (compile_time)

    print 'c |                                                                             |'

    start_time = time.time()
    (result, stats) = run(args)
    run_time = time.time() - start_time

    (sat, values) = result
    (num_decisions, num_conflicts, num_backtracks, total_time) = stats

    print 'c ==============================================================================='
    print 'c conflicts             : %d' % (num_conflicts)
    print 'c decisions             : %d' % (num_decisions)
    print 'c backtracks            : %d' % (num_backtracks)
    print 'c sim time              : %.6f s' % (run_time)
    print 'c hw time               : %.6f s' % (total_time)
    print 'c '
    print 's', 'SATISFIABLE' if sat else 'UNSATISFIABLE'
    if values:
        print 'v', ' '.join([str(v) for v in values])

if __name__=="__main__":
    main()
