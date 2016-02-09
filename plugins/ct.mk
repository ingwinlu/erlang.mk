# Copyright (c) 2013-2015, Loïc Hoguin <essen@ninenines.eu>
# This file is part of erlang.mk and subject to the terms of the ISC License.
# TODO work around hardcoded test paths

.PHONY: ct apps-ct distclean-ct

# Configuration.

CT_OPTS ?=

ifndef t
CT_EXTRA =
else
ifeq (,$(findstring :,$t))
CT_EXTRA = -group $t
else
t_words = $(subst :, ,$t)
CT_EXTRA = -group $(firstword $(t_words)) -case $(lastword $(t_words))
endif
endif

# Core targets.

tests:: ct

distclean:: distclean-ct

help::
	$(verbose) printf "%s\n" "" \
		"Common_test targets:" \
		"  ct          Run all the common_test suites for this project" \
		"" \
		"All your common_test suites have their associated targets." \
		"A suite named http_SUITE can be ran using the ct-http target." \
		"Suites in apps can be run via apps-ct-APPNAME-SUITE"

# Plugin-specific targets.

ct_run = ct_run \
	-no_auto_compile \
	-noinput \
	-pa $(CURDIR)/ebin $(DEPS_DIR)/*/ebin $(APPS_DIR)/*/ebin $(1) \
	-dir $(1) \
	-logdir $(CURDIR)/logs \
	-suite $(addsuffix _SUITE,$(2)) \
	-sname ct_$(PROJECT) \
	$(CT_EXTRA) \
	$(CT_OPTS)

ct_find_suites = $(sort $(subst _SUITE.erl,,$(notdir $(call core_find,$(1),*_SUITE.erl))))

define ct_suite_target
ct-$1: test-build
	$(verbose) mkdir -p $(CURDIR)/logs/
	$(gen_verbose) $(call ct_run,$(TEST_DIR),$1)
endef

define ct_app_target
apps-ct-$1: $(addprefix apps-ct-$1-,$(eval $(call ct_find_suites,$(APPS_DIR)/$(1)/test/)))

$(foreach test,$(eval $(call ct_find_suites,$(APPS_DIR)/$(1)/test/)),$(eval $(call ct_app_target_suite,$(1),$(test))))
endef

define ct_app_target_suite
apps-ct-$1-$2: test-build
	$(verbose) mkdir -p $(CURDIR)/logs/
	$(gen_verbose) $(call ct_run,$(APPS_DIR)/$(1)/test/,$(2))
endef

# local ct suites
$(foreach test,$(call ct_find_suites,$(TEST_DIR)/),$(call ct_suite_target,$(test)))

# ct targets for all apps
$(foreach app,$(ALL_APPS_DIRS),$(eval $(call ct_app_target,$(app))))

ct: $(addprefix ct-,$(call ct_find_suites,$(TEST_DIR)/)) $(ifneq($(ALL_APPS_DIRS),)apps-ct)

apps-ct: $(addprefix apps-ct-,$(ALL_APPS_DIRS))

distclean-ct:
	$(gen_verbose) rm -rf $(CURDIR)/logs/
