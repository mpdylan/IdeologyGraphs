'''
Utility script for converting the MATLAB .mat files in the Facebook100 data set to plain CSV files.
Output is a list of edges, one edge per line.
'''
import os
import scipy as sp
from scipy import io

def write_csv(fname):
#    fname = sys.argv[1]
    outfile = fname[:-3] + "csv"
    f = open(outfile, "w")
    print("Loading file", fname)
    sparsemat = sp.io.matlab.loadmat(fname)['A']
    sparsemat = sp.sparse.coo_matrix(sparsemat)
    for i, j in zip(sparsemat.row, sparsemat.col):
        if i <= j:
            f.write(str(i) + ',' + str(j) + '\n')
    print("Wrote file", outfile)
    return None

def main():
    filelist = os.listdir()
    n = 0
    for fname in filelist:
        if fname[-3:] == "mat":
            write_csv(fname)
            n += 1
    print("Converted", n, "files.")
    return None

if __name__ == "__main__":
    main()
