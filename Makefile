JULIA=$(shell which julia)
TEST_PROCEDURE="import Pkg;Pkg.test()"

format:
	$(JULIA) format_project.jl

test%:
	$(JULIA) $* --project -e $(TEST_PROCEDURE) 2&> test-$*.log

testall: test+lts test+beta test+release

clean:
	rm test*.log

.PHONY: format, test, testall, clean
