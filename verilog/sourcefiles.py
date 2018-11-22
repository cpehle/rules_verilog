import sys
import os

if __name__ == "__main__":
  assert len(sys.argv) >= 1
  output = open(sys.argv[1], "wt")
  for path in sys.argv[2:]:
    #input = open(path, "rt")
    filename, file_extension = os.path.splitext(path)
    # output.write("set PART {$(_PART)}" >> $@
    # @echo "set BITFILE {../../out/$(_NAME).bit}" >> $@
    if file_extension == '.sv':
      output.write('read_verilog -sv {}\n'.format(path))
    if file_extension == '.v':
      output.write('read_verilog {}\n'.format(path))
    if file_extension == '.xdc':
      output.write('read_xdc {}\n'.format(path))
