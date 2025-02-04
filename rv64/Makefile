all: rv64load build-zig program.bin

rv64load: rv64load.s rv64.ld
	clang --target=riscv64-unknown-none -nostdlib $< -o $@ -T rv64.ld

build-zig:
	zig build --build-file ../build.zig

program.bin: ../zig-out/bin/torchc
	$< ../example.th > $@

dump: program.bin
	riscv64-linux-gnu-objdump -b binary -m riscv:rv64 -D $<

run: rv64load program.bin
	qemu-riscv64 $<

clean:
	@rm -rf rv64load program.bin

.PHONY: all build-zig dump run
