#!/usr/bin/env python

# Convert Molecular SMILES to inchikeys

import smi2fp_module3 as s2fp
import argparse
import numpy
import sys
import textwrap
# import cmap.io.gct as gct

# Parse arguments
parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description=textwrap.dedent('''\
    Program to convert SMILES strings to Inchikeys
    usage examples:
        smi2inchikey -smi "Cc1ccc(cc1)S(=O)(=O)N2C(C3CC2C=C3)C(=O)O" -o out.txt
    or
        smi2inchikey -icsv input.csv -o out.txt'''))

parser.add_argument('-q', '--quiet',
                    action="store_true",
                    help="Supress printing any help and error message")

parser.add_argument('-smi', '--smiles',
                    action="store", dest="smiles",
                    help="Smiles string", default=None)

parser.add_argument('-icsv', '--inputcsv',
                    action="store", dest="icsv_file",
                    help="Input CSV file name", default=None)

parser.add_argument('-o', '--out_file',
                    action="store", dest="out_file",
                    help="Path to output file", default=None)

args = parser.parse_args()
# Done with parsing arguments
out_file = 'inchikey.txt' if args.out_file is None else args.out_file

# Executed when -smi is provided
if args.smiles is not None:
    inchikey = s2fp.smiles2inchikey(args.smiles)
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
        inchikey = s2fp.smiles2inchikey(sm)
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
