#!/usr/bin/env python2

import os, sys
import jinja2

ROOT_DIR = os.path.dirname(os.path.realpath(__file__))
TEMPLATES_DIR = os.path.join(ROOT_DIR, "templates")
WORK_DIR = os.path.join(ROOT_DIR, "work")

JINJA_ENV = jinja2.Environment(
    loader=jinja2.FileSystemLoader(TEMPLATES_DIR),
    extensions=['jinja2.ext.autoescape'],
    autoescape=False)

def main():
    if not os.path.exists(WORK_DIR):
        os.makedirs(WORK_DIR)

    tmp_variables = {}

    with open(sys.argv[1]) as f:
        for line in f.readlines():
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
                    print "error converting", line

                if var_int == 0:
                    continue

                clause.append( (var_name, 0 if (var_int < 0) else 1) )

            if len(clause) > 0:
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

    variables = sorted(variables, key=lambda var: int(var["name"][3:]))

    with open(os.path.join(WORK_DIR, 'solver.vhd'), 'w') as f:
        solver = JINJA_ENV.get_template('solver.vhd').render({
            "variables": variables,
            "len_variables": len(variables)
        })
        f.write(solver)

    with open(os.path.join(WORK_DIR, 'solver_tb.vhd'), 'w') as f:
        solver = JINJA_ENV.get_template('solver_tb.vhd').render({
            "variables": variables,
            "len_variables": len(variables)
        })
        f.write(solver)

    with open(os.path.join(WORK_DIR, 'Makefile'), 'w') as f:
        makefile = JINJA_ENV.get_template('Makefile').render({
            "variables": variables,
            "len_variables": len(variables)
        })
        f.write(makefile)

    imp_template = JINJA_ENV.get_template('imp.vhd')
    control_template = JINJA_ENV.get_template('control.vhd')

    for var in variables:
        with open(os.path.join(WORK_DIR, 'imp_%s.vhd' % var["name"]), 'w') as f:
            imp = imp_template.render({
                "current_var": var,
                "variables": variables,
                "len_variables": len(variables)
            })
            f.write(imp)

        with open(os.path.join(WORK_DIR, 'control_%s.vhd' % var["name"]), 'w') as f:
            control = control_template.render({
                "current_var": var,
                "variables": variables,
                "len_variables": len(variables)
            })
            f.write(control)

    color = 0
    for var in variables:
        var["color"] = color % 9
        color += 1

    with open(os.path.join(WORK_DIR, 'solver.gtkw'), 'w') as f:
        gtkw = JINJA_ENV.get_template('solver.gtkw').render({
            "dumpfile": os.path.join(WORK_DIR, 'solver.vcd'),
            "savefile": os.path.join(WORK_DIR, 'solver.gtkw'),
            "variables": variables,
            "len_variables": len(variables)
        })
        f.write(gtkw)

if __name__=="__main__":
    main()