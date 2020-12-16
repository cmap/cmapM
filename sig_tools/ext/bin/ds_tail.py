#!/bin/env python

import os
import sys
from pymongo import Connection
import argparse
import csv
from tables import File
from numpy import concatenate

def get_args():
      ''' Parse command-line arguments '''
      parser = argparse.ArgumentParser(description='Get meta-data \
                                    for signatures')
      parser.add_argument('-i', dest='infile',
                          help='Score matrix in gctx format',
                          required=True)

      parser.add_argument('-o', dest='outpath', default=None,
                          help='Output path, default is stdout')
      
      parser.add_argument('-n', dest='tail_size', default=10,
                          help='Tail size (integer), default is 10', type=int)
      
      parser.add_argument('-t', dest='score_type', default='NA',
                          help='Score type (string), default is NA')

      parser.add_argument('-u', dest='up',
                    help='Matrix of UP ES scores in gctx format')

      parser.add_argument('-d', dest='dn',
                          help='Matrix of DN ES scores in gctx format')

      return parser.parse_args()

def get_auth(auth_file, location):
      d = {}
      with open(auth_file,'r') as f:
            fields=f.readline().rstrip().split('\t')            
            for line in f:
                  tok = line.rstrip().split('\t')
                  d[tok[0]] = dict(zip(fields[1:], tok[1:]))
      assert(location in d)            
      return d[location]


def get_info(col, tail, score_type, mongo_fields):
      hd = ['sig_id', 'score_type', 'rank', 'score'] + mongo_fields
      score_dict = dict(zip(tail['id'], tail['score']))
      rank_dict = dict(zip(tail['id'], tail['rank']))
      row_dict = {}
      
      for doc in col.find({"sig_id": {"$in": tail['id']}}):
            sig_id=doc['sig_id']
            row=[sig_id, score_type, rank_dict[sig_id], score_dict[sig_id]]
            for f in mongo_fields:
                  row.append(doc[f])
            row_dict[sig_id] = row
      return {'header': hd, 'rows': row_dict}

def write_table(ofid, tail, tbl):
      ofid.writerow(tbl['header'])
      for id in tail['id']:
            ofid.writerow(tbl['rows'][id])

def parse_gctx(infile):
      fid = File(infile, 'r')
      mat = fid.getNode('/0/DATA/0', 'matrix').read()
      rid = fid.getNode('/0/META/ROW', 'id').read()
      cid = fid.getNode('/0/META/COL', 'id').read()
      fid.close()
      return {'matrix': mat, 'rid': rid, 'cid': cid}

def get_tails(x, rid, n):
      # sort descending order
      srtidx=x.argsort()[::-1]
      up = rid.take(srtidx[0:n]).tolist()
      dn = rid.take(srtidx[-n:]).tolist()
      #id = [e.rstrip() for e in concatenate((up, dn), 1).tolist()]
      id = [e.rstrip() for e in up+dn]
      score = concatenate((x[srtidx[0:n]], x[srtidx[-n:]]), 1)
      #score = x[srtidx[0:n]] + x[srtidx[-n:]]
      nx = len(x)
      rank = range(1, n+1) + range(nx-n+1, nx+1, 1)      
      return {'id': id, 'score': score, 'rank': rank}
      
def main():
      """ Main """
      # Parse arguments
      args = get_args()    
      auth_file='/cmap/data/vdb/mongo/mongo_servers.txt'
      mongo_location='local'
#      host='vitalstatistix:27017'
#      db_id='affogato'
      collection_id = 'signature'
      mongo_fields = ['pert_id', 'cell_id',
                      'pert_desc', 'pert_type', 'pert_time',
                      'pert_time_unit', 'pert_dose', 'pert_dose_unit',
                        'is_gold', 'distil_cc_q75', 'distil_ss',
                        'pct_self_rank_q25']
      # connect to Mongo
      auth = get_auth(auth_file, 'local')
      connection = Connection('mongodb://%s:%s@%s/%s' % (auth['user_id'], auth['password'], auth['server_id'], auth['sig_db']))
      db = connection[auth['sig_db']]
      col = db[auth['sig_collection']]

      ds = parse_gctx(args.infile)
      # output tails of each column
      for i in range(len(ds['cid'])):
            tail = get_tails(ds['matrix'][i,:], ds['rid'], args.tail_size)
          
            if args.outpath is None:
                  ofid = csv.writer(sys.stdout, delimiter='\t',
                                    quoting=csv.QUOTE_MINIMAL)
            else:
                  ofname = '%s/tail_%s_%s.txt' %(args.outpath, args.score_type.upper(), ds['cid'][i].rstrip().replace(':','_'))
                  ofid = csv.writer(open(ofname, 'wt'), delimiter='\t',
                                    quoting=csv.QUOTE_MINIMAL)                
                  tbl = get_info(col, tail, args.score_type, mongo_fields)
                  write_table(ofid, tail, tbl)

      # close Mongo connection
      connection.close()

if __name__=="__main__":
      sys.exit(main())

