# picolisp-awscurl Makefile

PIL_MODULE_DIR ?= .modules
REPO_PREFIX ?= https://github.com/aw

# Unit testing
TEST_REPO = $(REPO_PREFIX)/picolisp-unit.git
TEST_DIR = $(PIL_MODULE_DIR)/picolisp-unit/HEAD
TEST_REF = v3.1.0

.PHONY: all

all: check run-multi run-native

$(TEST_DIR):
		mkdir -p $(TEST_DIR) && \
		git clone $(TEST_REPO) $(TEST_DIR) && \
		cd $(TEST_DIR) && \
		git checkout $(TEST_REF)

check: $(TEST_DIR) test-multi test-native

test-multi: $(TEST_DIR) run-multi

run-multi:
		./test.l

test-native: $(TEST_DIR) run-native

run-native:
		./test.l native
