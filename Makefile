BROWSER = firefox
TEST_COV_D = /tmp/pyml_bindgen

.PHONY: all_dev
all_dev: clean build_dev test_dev

.PHONY: all_release
all_release: clean build_release test_release

.PHONY: build_dev
build_dev:
	dune build --profile=dev

.PHONY: build_release
build_release:
	dune build --profile=release

.PHONY: check
check:
	dune build @check

.PHONY: clean
clean:
	dune clean

.PHONY: deps
deps:
	opam install ./pyml_bindgen.opam --deps-only --with-doc --with-test

.PHONY: deps_dev
deps_dev:
	opam install ./pyml_bindgen-dev.opam --deps-only --with-doc --with-test

.PHONY: install_dev
install_dev:
	dune install --profile=dev

.PHONY: install_release
install_release:
	dune install --profile=release

.PHONY: promote
promote:
	dune promote

.PHONY: uninstall
uninstall:
	dune uninstall

.PHONY: test_dev
test_dev:
	dune runtest --profile=dev

.PHONY: test_release
test_release:
	dune runtest --profile=release

.PHONY: test_coverage
test_coverage:
	if [ -d $(TEST_COV_D) ]; then rm -r $(TEST_COV_D); fi
	mkdir -p $(TEST_COV_D)
	BISECT_FILE=$(TEST_COV_D)/pyml_bindgen dune runtest --no-print-directory \
	  --instrument-with bisect_ppx --force
	bisect-ppx-report html --coverage-path $(TEST_COV_D)
	bisect-ppx-report summary --coverage-path $(TEST_COV_D)

.PHONY: test_coverage_open
test_coverage_open: test_coverage
	$(BROWSER) _coverage/index.html

.PHONY: send_coverage
send_coverage: test_coverage
	bisect-ppx-report send-to Coveralls --coverage-path $(TEST_COV_D)
