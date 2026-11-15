# Verification files are compiled in dependency order. Paths are relative to sim/.
+incdir+../vip
+incdir+../tb
+incdir+../sequences
+incdir+../testcases
-f ../vip/vip.f
../tb/env_pkg.sv
../sequences/seq_pkg.sv
../testcases/test_pkg.sv
../tb/testbench.sv
