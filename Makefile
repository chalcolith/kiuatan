config ?= release

PACKAGE := kiuatan
GET_DEPENDENCIES_WITH := corral fetch
CLEAN_DEPENDENCIES_WITH := corral clean
COMPILE_WITH := corral run -- ponyc

BUILD_DIR ?= build/$(config)
SRC_DIR := $(PACKAGE)
TESTS_DIR := $(PACKAGE)/test
EXAMPLES_DIR := examples

binary := $(BUILD_DIR)/$(PACKAGE)
tests_binary := $(BUILD_DIR)/test
docs_dir := build/$(PACKAGE)-docs

ifdef config
	ifeq (,$(filter $(config),debug release))
		$(error Unknown configuration "$(config)")
	endif
endif

ifeq ($(config),release)
	PONYC = $(COMPILE_WITH)
else
	PONYC = $(COMPILE_WITH) --debug
endif

ifneq ($(wildcard .git),)
  tag := $(shell cat VERSION)-$(shell git rev-parse --short HEAD)
else
  tag := $(shell cat VERSION)
endif

SOURCE_FILES := $(shell find $(SRC_DIR) -name *.pony)
VERSION := "$(tag) [$(config)]"
GEN_FILES_IN := $(shell find $(SRC_DIR) -name \*.pony.in)
GEN_FILES = $(patsubst %.pony.in, %.pony, $(GEN_FILES_IN))

EXAMPLES := $(notdir $(shell find $(EXAMPLES_DIR)/* -maxdepth 0 -type d))
EXAMPLES_SOURCE_FILES := $(shell find $(EXAMPLES_DIR) -name *.pony)
EXAMPLES_BINARIES := $(addprefix $(BUILD_DIR)/,$(EXAMPLES))

# build: $(binary)

test: unit-tests # build-examples

unit-tests: $(tests_binary)
	$^ --exclude=integration --sequential

$(binary): $(GEN_FILES) $(SOURCE_FILES) | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) $(SRC_DIR)

$(tests_binary): $(GEN_FILES) $(SOURCE_FILES) | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) $(TESTS_DIR)

%.pony: %.pony.in
	sed s/%%VERSION%%/$(VERSION)/ $< > $@

build-examples: $(EXAMPLES_BINARIES)

$(EXAMPLES_BINARIES): $(BUILD_DIR)/%: $(SOURCE_FILES) $(EXAMPLES_SOURCE_FILES) | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) $(EXAMPLES_DIR)/$*

clean:
	$(CLEAN_DEPENDENCIES_WITH)
	rm -rf $(BUILD_DIR)

$(docs_dir): $(SOURCE_FILES)
	rm -rf $(docs_dir)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) --docs-public --pass=docs --output build $(SRC_DIR)

docs: $(docs_dir)

TAGS:
	ctags --recurse=yes $(SRC_DIR)

all: test

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: all build-examples clean TAGS test
