#!/usr/bin/env python

# Program to convert SMILES strings to binary fingerprints
# Version 1.1
# E-mail questions to: morzech@broadinstitute.org
# Marek Orzechowski 08/19/2015

import smi2fp_module as s2fp
import argparse
import numpy
import sys
import textwrap
# import cmap.io.gct as gct

# Parse arguments
parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description=textwrap.dedent('''\
    Program to convert SMILES strings to binary fingerprints
    usage examples:
        smi2fp_tool -smi "Cc1ccc(cc1)S(=O)(=O)N2C(C3CC2C=C3)C(=O)O" [-fpt "FP2"] [-pert_id "BRD-123456789"] \
                    [-pert_iname "abcdefghi"] [-ojson output.json]
    or
        smi2fp -ijson input.json [or -icsv input.csv] -ojson output.json [or -ocsv output.csv]'''))

parser.add_argument('-q', '--quiet',
                    action="store_true",
                    help="Supress printing any help and error message")

parser.add_argument('-smi', '--smiles',
                    action="store", dest="smiles",
                    help="Smiles string", default=None)

parser.add_argument('-fpt', '--fpt_type',
                    action="store", dest="fpt", choices=['FP2', 'FP3', 'FP4', 'MACCS', 'ECFP', 'FCFP'],
                    help="Fingerprint type", default="FP2")

parser.add_argument('-pert_id', '--pert_id',
                    action="store", dest="pert_id",
                    help="pert_id string", default="BRD-XXXXXXXXX")

parser.add_argument('-pert_iname', '--pert_iname',
                    action="store", dest="pert_iname",
                    help="pert_iname string", default=None)

parser.add_argument('-ijson', '--inputjson',
                    action="store", dest="ijson_file",
                    help="Input JSON file name", default=None)

parser.add_argument('-ojson', '--outputjson',
                    action="store", dest="ojson_file",
                    help="Output JSON file name", default=None)

parser.add_argument('-icsv', '--inputcsv',
                    action="store", dest="icsv_file",
                    help="Input CSV file name", default=None)

parser.add_argument('-ocsv', '--outputcsv',
                    action="store", dest="ocsv_file",
                    help="Output CSV file name", default=None)

parser.add_argument('-ogctx', '--outputgctx',
                    action="store", dest="ogctx_file",
                    help="Output GCTX file name", default=None)

args = parser.parse_args()
# Done with parsing arguments

if args.pert_iname is None:
    args.pert_iname = args.pert_id

# Executed when -smi is provided
if args.smiles is not None:
    fpt = s2fp.smiles2fpt(args.smiles, args.fpt)
    dataJ = [dict([("pert_id", args.pert_id),
                   ("pert_iname", args.pert_iname),
                   ("canonical_smiles", args.smiles),
                   ("binary_fpt", fpt.tolist())])]
    s2fp.write_output(dataJ, args.pert_id, None, args.ojson_file, args.ocsv_file, args.ogctx_file)
# Executed when -ijson is provided
elif args.ijson_file is not None:
    print 'Input JSON file: ' + args.ijson_file
    dataJ = s2fp.read_json(args.ijson_file)
    s2fp.check_missing(dataJ)
    for i in range(len(dataJ)):
        sm = dataJ[i]['canonical_smiles'].encode('ascii', 'replace')
        fpt = s2fp.smiles2fpt(sm, args.fpt)
        dataJ[i][unicode('binary_fpt')] = fpt.tolist()
    s2fp.write_output(dataJ, None, args.ijson_file, args.ojson_file, args.ocsv_file, args.ogctx_file)
# Executed when -icsv file is provided
elif args.icsv_file is not None:
    print 'Input CSV file: ' + args.icsv_file
    dataJ = s2fp.read_csv_smiles(args.icsv_file, '\t')
    s2fp.check_missing(dataJ)
    for i in range(len(dataJ)):
        sm = dataJ[i]['canonical_smiles'].encode('ascii', 'replace')
        fpt = s2fp.smiles2fpt(sm, args.fpt)
        dataJ[i][unicode('binary_fpt')] = fpt.tolist()
    s2fp.write_output(dataJ, None, args.icsv_file, args.ojson_file, args.ocsv_file, args.ogctx_file)
# Executed when no SMILES is provided
else:
    print '''You need to provide SMILES by using at least one of the three options: -smi or -ijson -or icsv\n'''
    if args.quiet:
        print '''An error occurred. Cannot proceed.'''
        sys.exit(1)
    else:
        parser.print_help()
        sys.exit(1)
