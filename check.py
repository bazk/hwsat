#!/usr/bin/env python2

import os, sys

def main():
    formula = []

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
                    var_name = abs(var_int)
                except:
                    print "error converting", line

                if var_int == 0:
                    continue

                clause.append( (var_name, False if (var_int < 0) else True) )

            if len(clause) > 0:
                formula.append(clause)

    values = {}
    for line in sys.stdin:
        str_values = line.strip('\n').split(' ')
        for sv in str_values:
            var_int = int(sv)
            var_name = abs(var_int)

            values[var_name] = False if (var_int < 0) else True

    satisfied = True
    for clause in formula:
        res = False
        for var in clause:
            (name, sign) = var
            res = values[name] if (sign) else not values[name]
            if res:
                break

        if not res:
            satisfied = False
            break

    if satisfied:
        print "SATISFIED"
    else:
        print "NOT SATISFIED"


if __name__=="__main__":
    main()