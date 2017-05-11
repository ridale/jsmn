# You can put your build options here
-include config.mk



all: libjsmn.a example

libjsmn.a: jsmn.o jsmn_iterator.o
	$(AR) rc $@ $^

%.o: %.c jsmn.h
	$(CC) -c $(CFLAGS) $< -o $@

test: test_default test_iterator

test_default: test/tests.c
	$(CC) $(CFLAGS) $(LDFLAGS) $< -o test/$@
	./test/$@

test_iterator: test/tests_iterator.c
	$(CC) $(CFLAGS) $(LDFLAGS) $< -o test/$@
	./test/$@

test_coverage: test_default_lcov test_iterator_lcov
	mkdir -p $@
	lcov --no-external --directory . --base-directory . -c -o $@/$@.info
	genhtml -o $@ -t "jsmn" --num-spaces 2 $@/$@.info

test_default_lcov: test/tests.c
	$(CC) $(CFLAGS) $(LDFLAGS) $< -o test/$@ -coverage
	-./test/$@
	mv tests.gcda $@.gcda
	mv tests.gcno $@.gcno

test_iterator_lcov: test/tests_iterator.c
	$(CC) $(CFLAGS) $(LDFLAGS) $< -o test/$@ -coverage
	./test/$@

fuzz_default:
	afl-gcc example/jsondump.c jsmn.c jsmn_iterator.c -o test/$@ $(CFLAGS) $(LDFLAGS)
	afl-fuzz -i ./test/corpora/ -o ./test/fuzz ./test/$@

fuzz_iterator:
	afl-gcc example/jsonprint.c jsmn.c jsmn_iterator.c -o test/$@ $(CFLAGS) $(LDFLAGS)
	afl-fuzz -i ./test/corpora/ -o ./test/fuzz ./test/$@

fuzz_default_lcov:
	afl-gcc example/jsondump.c jsmn.c jsmn_iterator.c -o test/$@ $(CFLAGS) $(LDFLAGS) -coverage
	afl-fuzz -i ./test/corpora/ -o ./test/fuzz ./test/$@

fuzz_iterator_lcov:
	afl-gcc example/jsonprint.c jsmn.c jsmn_iterator.c -o test/$@ $(CFLAGS) $(LDFLAGS) -coverage
	afl-fuzz -i ./test/corpora/ -o ./test/fuzz ./test/$@

coverage:
	lcov --capture --directory . --output-file c_coverage.info
	genhtml c_coverage.info --output-directory ./test/lcov

jsmn_test.o: jsmn_test.c libjsmn.a

simple_example: example/simple.o libjsmn.a
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

jsondump: example/jsondump.o libjsmn.a
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

jsonprint: example/jsonprint.o libjsmn.a
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@

example: simple_example jsondump jsonprint

clean:
	rm -f *.o example/*.o
	rm -f *.a *.so
	rm -f simple_example
	rm -f jsondump jsondump jsonprint
	rm -f test/coverage.info
	rm -f test/test_default*
	rm -f test/test_iterator*
	rm -f test/fuzz_*
	rm -f *.gcno *.gcda
	rm -f c_coverage.info
	rm -rf test_coverage
	rm -rf test/lcov/
	rm -fr test/fuzz


.PHONY: all clean test example

