# Read the PORT variable
include config.mk

all:	x86

arduino:
	$(MAKE) -C src

arduino-sim:
	$(MAKE) -C src
	if [ ! -d simavr ] ; then                            \
                git submodule init || exit 1 ;               \
                git submodule update || exit 1 ;             \
		$(MAKE) -C simavr/examples/board_simduino/ ; \
        fi
	cd src ; ./simduino

upload:
	$(MAKE) -C src upload
	@echo -e "Issue '\e[1mmake terminal\e[0m' to communicate over ${PORT}"

terminal:
	picocom -c -b 115200 --imap lfcrlf ${PORT}

x86:
	$(MAKE) -C src_x86

clean:
	$(MAKE) -C src clean
	rm -f src_x86/x86_forth

extract-forth-code:
	@cat README.md                                       \
	    | sed '1,/My Forth test/d'                       \
	    | grep '^    '                                   \
	    | grep -v OK                                     \
	    | sed 's,^    ,,'

test-address-sanitizer:
	$(MAKE) -C src_x86
	@$(MAKE) extract-forth-code                          \
	    | grep -v '^make'                                \
	    | ./src_x86/x86_forth

test-valgrind:
	$(MAKE) -C src_x86 valgrind
	@$(MAKE) extract-forth-code                          \
	    | grep -v '^make'                                \
	    | valgrind ./src_x86/x86_forth
	@echo "[-] Test PASSED."

test-arduino:
	@$(MAKE) extract-forth-code                          \
	    | grep -v '^make' > testing/scenario
	testing/test_forth.py -p ${PORT} -i testing/scenario

blink-arduino:
	testing/test_forth.py -p ${PORT} -i testing/blinky.fs

test-simulator:
	$(MAKE) -C src
	if [ ! -d simavr ] ; then                            \
                git submodule init || exit 1 ;               \
                git submodule update || exit 1 ;             \
		$(MAKE) -C simavr/examples/board_simduino/ ; \
        fi
	cd src ; ./simduino-test
	@$(MAKE) extract-forth-code                          \
	    | grep -v '^make' > testing/scenario
	testing/test_forth.py -p /tmp/simavr-uart0 -i testing/scenario
	@killall simduino.elf

test:
	$(MAKE) test-address-sanitizer
