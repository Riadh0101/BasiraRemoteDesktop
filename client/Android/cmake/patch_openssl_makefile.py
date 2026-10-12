import sys
import os

if len(sys.argv) < 2:
    print("Usage: patch_openssl_makefile.py <binary_dir>")
    sys.exit(1)

bld_dir = sys.argv[1]
makefile_path = os.path.join(bld_dir, "Makefile")

if not os.path.exists(makefile_path):
    print(f"Makefile not found at {makefile_path}")
    sys.exit(1)

with open(makefile_path, "r", encoding="utf-8", errors="replace") as f:
    lines = f.readlines()

print(f"Read {len(lines)} lines from {makefile_path}")

# 1. Update PERL to include PERL5LIB
updated_lines = []
for line in lines:
    if line.startswith("PERL=/usr/bin/perl") and "-I/c/Users/Administrator/.local/perl5/lib" not in line:
        line = "PERL=/usr/bin/perl -I/c/Users/Administrator/.local/perl5/lib\n"
    updated_lines.append(line)
lines = updated_lines

# 2. Patch libcrypto.so rule to use response file
libcrypto_target_idx = None
for i, line in enumerate(lines):
    if line.startswith("libcrypto.so:"):
        libcrypto_target_idx = i
        break

if libcrypto_target_idx is not None:
    # Find start of link command ($(CC) $(LIB_CFLAGS))
    cmd_start_idx = None
    for i in range(libcrypto_target_idx + 1, min(libcrypto_target_idx + 1000, len(lines))):
        if lines[i].startswith("\t$(CC)"):
            cmd_start_idx = i
            break

    if cmd_start_idx is not None:
        rsp_path = os.path.join(bld_dir, "libcrypto.rsp")
        if "@libcrypto.rsp" in lines[cmd_start_idx]:
            print("Already patched to use @libcrypto.rsp!")
            if not os.path.exists(rsp_path) or os.path.getsize(rsp_path) == 0:
                print("Rebuilding empty/missing libcrypto.rsp from disk objects...")
                objs = []
                for root, dirs, files in os.walk(bld_dir):
                    for f_name in files:
                        if 'libcrypto-shlib-' in f_name and f_name.endswith('.o'):
                            rel_p = os.path.relpath(os.path.join(root, f_name), bld_dir).replace('\\', '/')
                            objs.append(rel_p)
                objs.sort()
                with open(rsp_path, "w", encoding="utf-8") as f_rsp:
                    f_rsp.write('\n'.join(objs) + '\n')
                print(f"Rebuilt {len(objs)} objects in {rsp_path}")
        else:
            cmd_end_idx = None
            for i in range(cmd_start_idx, min(cmd_start_idx + 1000, len(lines))):
                if not lines[i].endswith("\\\n"):
                    cmd_end_idx = i
                    break

            if cmd_end_idx is not None:
                # Extract all .o files in this link command
                link_lines = lines[cmd_start_idx:cmd_end_idx + 1]
                objs = []
                for ll in link_lines:
                    parts = ll.strip().rstrip('\\').split()
                    for p in parts:
                        if p.endswith('.o'):
                            objs.append(p)

                rsp_path = os.path.join(bld_dir, "libcrypto.rsp")
                with open(rsp_path, "w", encoding="utf-8") as f_rsp:
                    f_rsp.write('\n'.join(objs) + '\n')
                print(f"Wrote {len(objs)} objects to {rsp_path}")

                # New link command
                new_cmd = "\t$(CC) $(LIB_CFLAGS) $(LIB_LDFLAGS) -Wl,-soname=libcrypto.so -o libcrypto.so -Wl,--version-script=libcrypto.ld @libcrypto.rsp providers/libdefault.a providers/libcommon.a $(LIB_EX_LIBS)\n"
                lines = lines[:cmd_start_idx] + [new_cmd] + lines[cmd_end_idx + 1:]
                print("Patched libcrypto.so link command successfully!")

with open(makefile_path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("OpenSSL Makefile patch complete.")
