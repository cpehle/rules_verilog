import sys
import os

output = open(sys.argv[1], "wt")
args = sys.argv[2:]

cmd = 'verilator ' + ' '.join(args)
result = os.popen(cmd).read()
output.write(result)
