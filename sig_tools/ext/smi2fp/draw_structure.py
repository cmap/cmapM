#!/usr/bin/env python

# Draw and save molecules from structure info

import os
import smi2fp_module3 as s2fp
import argparse
import numpy
import sys
import textwrap

# Parse arguments
parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description=textwrap.dedent('''\
    Program to draw and save molecules from structure information
    usage examples:
        draw_structure -smi "Cc1ccc(cc1)S(=O)(=O)N2C(C3CC2C=C3)C(=O)O" -o out.png
    or
        draw_structure -icsv input.csv -o out.png'''))

parser.add_argument('-q', '--quiet',
                    action="store_true",
                    help="Supress printing any help and error message")

parser.add_argument('-smi', '--smiles',
                    action="store", dest="smiles",
                    help="Smiles string", default=None)

parser.add_argument('-icsv', '--inputcsv',
                    action="store", dest="icsv_file",
                    help="Input CSV file name", default=None)

parser.add_argument('-f', '--format',
                    action="store", dest="format",
                    help="Image file format", default='png',
                    choices=['png', 'svg'])

parser.add_argument('-o', '--out_path',
                    action="store", dest="out_path",
                    help="Path to save images", default='.')

args = parser.parse_args()
# Done with parsing arguments

# Executed when -smi is provided
if args.smiles is not None:
    img = s2fp.smiles2image(args.smiles)
    dataJ = [dict([("canonical_smiles", args.smiles),
                   ("inchikey", inchikey)])]
    
    print('{0:s}'.format(inchikey))
    #s2fp.write_output(data = dataJ, ocsv = out_file)
# Executed when -icsv file is provided
elif args.icsv_file is not None:
    print('Input CSV file: {0:s}'.format(args.icsv_file))
    dataJ = s2fp.read_csv_smiles(args.icsv_file, '\t')
    for i in range(len(dataJ)):
        sm = dataJ[i]['canonical_smiles'].encode('ascii', 'replace')
        img = s2fp.smile2image(sm)
        out_file =  os.path.join(args.out_path, dataJ[i]['pert_id'] + '.svg')   
        dataJ[i]['inchikey'] = inchikey
    s2fp.write_output(data = dataJ, ocsv = args.out_file)
# Executed when no SMILES is provided
else:
    print('You need to provide SMILES by using: -smi -or icsv')
    if args.quiet:
        print('An error occurred. Cannot proceed.')
        sys.exit(1)
    else:
        parser.print_help()
        sys.exit(1)
