NAME := bad-dull

ROOT ?= $(dir $(lastword $(MAKEFILE_LIST)))

SOURCE ?= $(ROOT)source
BUILD ?= $(ROOT)build

LOG ?= $(ROOT)debug.log

BOLD := \033[1m

RED := \033[1;31m
GREEN := \033[1;32m
CYAN := \033[1;36m

DIM := \033[2m

RESET := \033[0m

.ONESHELL:
.PHONY: all clean build run

all: build

clean:
	@printf "\n$(BOLD)Cleaning..$(RESET)\n"

	@printf "    $(CYAN)→$(RESET) Removing build directory..\n"
	@rm -rf "$(BUILD)"
	@printf "    $(GREEN)✓$(RESET) Removed $(BUILD)\n"

	@printf "\n    $(CYAN)→$(RESET) Removing logs..\n"
	@rm -f "$(LOG)"
	@printf "    $(GREEN)✓$(RESET) Removed $(LOG)\n"

	@printf "\n$(GREEN)$(BOLD)Done cleaning.$(RESET)\n"

build: clean
	@printf "\n$(BOLD)Building..$(RESET)\n"

	@mkdir -p "$(BUILD)/$(NAME)" "$(BUILD)/built"
	@printf "    $(GREEN)✓$(RESET) Created directories.\n"

	@printf "\n    $(CYAN)→$(RESET) Assembling..\n\n"

	set -x; set -x; llvm-mc -triple=i386-unknown-elf -filetype=obj $(SOURCE)/$(NAME)/main.s -o $(BUILD)/$(NAME)/$(NAME).o || { \
	    code=$$?; \
	    printf "\n$(RED)✘$(RESET) $(BOLD)Assembly Failed. Exit $$code$(RESET)\n\n"; \
	    exit $$code; \
	}

	set +x

	@printf "\n    $(GREEN)✓$(RESET) Assembled.\n"

	@printf "\n    $(CYAN)→$(RESET) Linking..\n\n"

	set -x; set -x; ld.lld -T $(SOURCE)/$(NAME)/linker.ld --oformat=binary $(BUILD)/$(NAME)/$(NAME).o -o $(BUILD)/$(NAME)/$(NAME) || { \
	    code=$$?; \
	    printf "\n$(RED)✘$(RESET) $(BOLD)Linking Failed. Exit $$code$(RESET)\n\n"; \
	    exit $$code; \
	}

	set +x

	@printf "\n    $(GREEN)✓$(RESET) Linked.\n"

	@printf "\n    $(CYAN)→$(RESET) Writing Image..\n\n"

	set -x; set -x; cat $(BUILD)/$(NAME)/$(NAME) $(SOURCE)/$(NAME)/frames.bin > $(BUILD)/$(NAME)/$(NAME).img || { \
	    code=$$?; \
	    printf "\n$(RED)✘$(RESET) $(BOLD)Write Failed. Exit $$code$(RESET)\n\n"; \
	    exit $$code; \
	}

	set +x

	@printf "\n    $(GREEN)✓$(RESET) Wrote Image.\n"

	@cp "$(BUILD)/$(NAME)/$(NAME).img" "$(BUILD)/built/$(NAME).img" || { \
	    code=$$?; \
	    printf "\n$(RED)✘$(RESET) $(BOLD)Staging Failed. Exit $$code$(RESET)\n\n"; \
	    exit $$code; \
	}

	@printf "\n    $(GREEN)✓$(RESET) Staged binary.\n"

	@printf "\n$(GREEN)$(BOLD)Finished building.$(RESET)\n"

run: all
	@printf "\n$(BOLD)Launching..$(RESET)\n"
	@printf "    $(CYAN)→$(RESET) Running..\n\n"

	set -x; set -x; qemu-system-x86_64 -net none -drive format=raw,file="$(BUILD)/built/$(NAME).img" -d int,cpu_reset -no-reboot -D "$(LOG)"; code=$$?; set +x; \
	if [ "$$code" -ne 0 ]; then \
	    printf "\n    $(RED)✘$(RESET) Exited with error $$code.\n"; \
	else \
	    printf "\n    $(GREEN)✓$(RESET) Exited cleanly.\n"; \
	fi

	@printf "\n$(GREEN)$(BOLD)Exited.$(RESET) Debug log: $(DIM)$(LOG)$(RESET)\n"
