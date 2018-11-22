import sys
import os

args = sys.argv[2:]
cmd = 'verilator --cc ' + ' '.join(args)
result = os.popen(cmd).read()

# output.write(result)