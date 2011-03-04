# Makefile to build the SDK repository packages.

.PHONY: sdk_repo

# Define the name of a package zip file to generate
# $1=OS (e.g. linux-x86, windows, etc)
# $2=sdk zip (e.g. out/host/linux.../android-eng-sdk.zip)
# $3=package to create (e.g. tools, docs, etc.)
#
define sdk-repo-pkg-zip
$(dir $(2))/sdk-repo-$(1)-$(3).zip
endef

# Defines the rule to build an SDK repository package by zipping all
# the content of the given directory.
# E.g. given a folder out/host/linux.../sdk/android-eng-sdk/tools
# this generates an sdk-repo-linux-tools that contains tools/*
#
# $1=OS (e.g. linux-x86, windows, etc)
# $2=sdk zip (e.g. out/host/linux.../android-eng-sdk.zip)
# $3=package to create (e.g. tools, docs, etc.)
#
# The rule depends on the SDK zip file, which is defined by $2.
#
define mk-sdk-repo-pkg-1
$(call sdk-repo-pkg-zip,$(1),$(2),$(3)): $(2)
	@echo "Building SDK repository package $(3) from $(notdir $(2))"
	$(hide) cd $(dir $(2)) && \
			zip -9rq ../$(notdir $(call sdk-repo-pkg-zip,$(1),$(2),$(3))) \
					 $(basename $(2))/*
$(call dist-for-goals, sdk_repo, $(call sdk-repo-pkg-zip,$(1),$(2),$(3)))
endef

# Defines the rule to build an SDK repository package when the
# package directory contains a single platform-related inner directory.
# E.g. given a folder out/host/linux.../sdk/android-eng-sdk/samples/android-N
# this generates an sdk-repo-linux-samples that contains android-N/*
#
# $1=OS (e.g. linux-x86, windows, etc)
# $2=sdk zip (e.g. out/host/linux.../android-eng-sdk.zip)
# $3=package to create (e.g. platforms, samples, etc.)
#
# The rule depends on the SDK zip file, which is defined by $2.
#
define mk-sdk-repo-pkg-2
$(call sdk-repo-pkg-zip,$(1),$(2),$(3)): $(2)
	@echo "Building SDK repository package $(3) from $(notdir $(2))"
	$(hide) cd $(dir $(2))/$(3) && \
			zip -9rq ../../$(notdir $(call sdk-repo-pkg-zip,$(1),$(2),$(3))) \
					 $(basename $(2))/*
$(call dist-for-goals, sdk_repo, $(call sdk-repo-pkg-zip,$(1),$(2),$(3)))
endef


SDK_REPO_DEPS :=

# Rules for win_sdk

ifneq ($(WIN_SDK_ZIP),)

# docs, platforms and samples have nothing OS-dependent right now.
$(eval $(call mk-sdk-repo-pkg-1,windows,$(WIN_SDK_ZIP),tools))
$(eval $(call mk-sdk-repo-pkg-1,windows,$(WIN_SDK_ZIP),platform-tools))

SDK_REPO_DEPS += \
		$(call sdk-repo-pkg-zip,windows,$(WIN_SDK_ZIP),tools) \
        $(call sdk-repo-pkg-zip,windows,$(WIN_SDK_ZIP),platform-tools)

endif

# Rules for main host sdk

ifneq ($(filter sdk win_sdk,$(MAKECMDGOALS)),)

$(eval $(call mk-sdk-repo-pkg-1,$(HOST_OS),$(MAIN_SDK_ZIP),tools))
$(eval $(call mk-sdk-repo-pkg-1,$(HOST_OS),$(MAIN_SDK_ZIP),platform-tools))
$(eval $(call mk-sdk-repo-pkg-1,$(HOST_OS),$(MAIN_SDK_ZIP),docs))
$(eval $(call mk-sdk-repo-pkg-2,$(HOST_OS),$(MAIN_SDK_ZIP),platforms))
$(eval $(call mk-sdk-repo-pkg-2,$(HOST_OS),$(MAIN_SDK_ZIP),samples))

SDK_REPO_DEPS += \
		$(call sdk-repo-pkg-zip,$(HOST_OS),$(MAIN_SDK_ZIP),tools) \
		$(call sdk-repo-pkg-zip,$(HOST_OS),$(MAIN_SDK_ZIP),platform-tools) \
		$(call sdk-repo-pkg-zip,$(HOST_OS),$(MAIN_SDK_ZIP),docs) \
		$(call sdk-repo-pkg-zip,$(HOST_OS),$(MAIN_SDK_ZIP),platforms) \
		$(call sdk-repo-pkg-zip,$(HOST_OS),$(MAIN_SDK_ZIP),samples) \

endif

# Rules for sdk addon

ifneq ($(ADDON_SDK_ZIP),)

# ADDON_SDK_ZIP is defined in build/core/tasks/sdk-addon.sh and is
# already packaged correctly. All we have to do is dist it with
# a different destination name.

$(call dist-for-goals, sdk_repo, \
	$(ADDON_SDK_ZIP):$(notdir $(call sdk-repo-pkg-zip,$(HOST_OS),$(ADDON_SDK_ZIP),addon)))

endif


sdk_repo: $(SDK_REPO_DEPS)
	@echo "Packing of SDK repository done"
