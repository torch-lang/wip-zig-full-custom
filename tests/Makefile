TORCHC = ../zig-out/bin/torchc

SRCS = $(shell find . -type f -name "*.th" | sort)
OBJS = $(SRCS:%.th=%.o)

all: $(OBJS)
	@echo done

%.o: %.th
	@echo -n "$<"
	@$(TORCHC) $<
	@echo "  OK"

.PHONY: all
