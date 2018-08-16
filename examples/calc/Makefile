target := calc
config ?= release

SRC_DIR ?= $(target)
BUILD_DIR ?= build/$(config)
binary := $(BUILD_DIR)/$(target)

ifdef config
  ifeq (,$(filter $(config),debug release))
    $(error Unknown configuration "$(config)")
  endif
endif

ifeq ($(config),release)
	PONYC = ponyc
else
	PONYC = ponyc --debug
endif

ifneq ($(wildcard .git),)
  tag := $(shell cat ../../VERSION)-$(shell git rev-parse --short HEAD)
else
  tag := $(shell cat ../../VERSION)
endif

SOURCE_FILES := $(shell find $(SRC_DIR) -name \*.pony)
VERSION := "$(tag) [$(config)]"
GEN_FILES_IN := $(shell find $(SRC_DIR) -name \*.pony.in)
GEN_FILES = $(patsubst %.pony.in, %.pony, $(GEN_FILES_IN))

%.pony: %.pony.in
	sed s/%%VERSION%%/$(VERSION)/ $< > $@

all: $(binary)

.PHONY: all docs test clean

$(binary): $(GEN_FILES) $(SOURCE_FILES) | $(BUILD_DIR)
	stable env $(PONYC) $(SRC_DIR) -o $(BUILD_DIR)

$(BUILD_DIR)/test: $(SOURCE_FILES)
	stable env $(PONYC) $(SRC_DIR)/test -o $(BUILD_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

docs: $(SOURCE_FILES) $(BUILD_DIR)
	stable env $(PONYC) --pass=docs --docs-public $(target) -o $(BUILD_DIR)

test: $(BUILD_DIR)/test
	$(BUILD_DIR)/test

clean:
	rm -rf $(BUILD_DIR)
