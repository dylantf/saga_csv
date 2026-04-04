CURDIR := $(shell pwd)
BASEDIR := $(abspath $(CURDIR)/..)
PRIV_DIR := $(BASEDIR)/priv
NIF_NAME := saga_csv_nif

.DEFAULT_GOAL := $(PRIV_DIR)/$(NIF_NAME).so

$(PRIV_DIR)/$(NIF_NAME).so:
	@mkdir -p $(PRIV_DIR)
	@cargo build --release
	@cp target/release/lib$(NIF_NAME).so $(PRIV_DIR)/$(NIF_NAME).so

clean:
	@cargo clean
	@rm -f $(PRIV_DIR)/$(NIF_NAME).so
