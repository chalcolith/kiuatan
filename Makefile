
debug ?= no

ifeq ($(debug),no)
	PONYC = ponyc
else
	PONYC = ponyc --debug
endif

SOURCE_FILES := $(shell find . -name \*.pony)

bin/kiuatan: ${SOURCE_FILES}
	mkdir -p bin
	${PONYC} kiuatan -o bin

test: bin/kiuatan
	bin/kiuatan

clean:
	rm -rf bin

all: bin/kiuatan

.PHONY: all
