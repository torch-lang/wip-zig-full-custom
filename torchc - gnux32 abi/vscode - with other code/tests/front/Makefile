TORCHC = ../../zig-out/bin/torchc

SRCS = $(shell find . -type f -name "*.th")
TOKS = $(SRCS:%.th=out/%.tok)

test: $(TOKS)
	./check.sh

out/%.tok: %.th $(TORCHC)
	@mkdir -p $(@D)
	-$(TORCHC) $< -o:tok $@ 2> $@

clean:
	@rm -rf out/

.PHONY: test clean
