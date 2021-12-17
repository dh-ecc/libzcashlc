SHELL := zsh
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

PLATFORMS = ios-device macos ios-simulator
IOS_DEVICE_ARCHS = aarch64-apple-ios
IOS_SIM_ARCHS_STABLE = x86_64-apple-ios
IOS_SIM_ARCHS_NIGHTLY = aarch64-apple-ios-sim
MACOS_ARCHS = x86_64-apple-darwin aarch64-apple-darwin
IOS_SIM_ARCHS = $(IOS_SIM_ARCHS_STABLE) $(IOS_SIM_ARCHS_NIGHTLY)

RUST_SRCS = $(shell find rust -name "*.rs") Cargo.toml
STATIC_LIBS = $(shell find target -name "libzcashlc.a")

# make static libraries: ios-sim-x86, ios-sim-arm64, mac-x86 mac-arm64, ios-device-arm64
# lipo them for universal static libraries: ios-sim-x86, ios-sim-arm64 -> ios-sim, mac-x86 mac-arm64 -> mac, ios-device-arm64 -> ios-device
# make them frameworks: (can't remember why)
# create folder structure: ios-arm64, ios-arm64_x86_64-simulator, macos-arm64_x86_64

clean:
	rm -rf products
	rm -rf targets

xcframework: products/libzcashlc.xcframework
.PHONY: xcframework

products/libzcashlc.xcframework: $(PLATFORMS)
	rm -rf $@
	mkdir -p $@
	cp -R products/ios-device/frameworks $@/ios-arm64
	cp -R products/ios-simulator/frameworks $@/ios-arm64_x86_64-simulator
	cp -R products/macos/frameworks $@/macos-arm64_x86_64
	cp support/Info.plist $@

frameworks: $(PLATFORMS)
.PHONY: frameworks

$(PLATFORMS): %: products/%/frameworks/libzcashlc.framework
.PHONY: $(PLATFORMS)

products/%/frameworks/libzcashlc.framework: products/%/universal/libzcashlc.a
	rm -rf $@
	mkdir -p $@
	cp products/$*/universal/libzcashlc.a $@/libzcashlc
	cp -R target/Headers $@
	mkdir $@/Modules
	cp support/module.modulemap $@/Modules

products/macos/universal/libzcashlc.a: $(MACOS_ARCHS)
	mkdir -p $(@D)
	lipo -create $(shell find products/macos/static-libraries -name "libzcashlc.a") -output $@

products/ios-simulator/universal/libzcashlc.a: $(IOS_SIM_ARCHS)
	mkdir -p $(@D)
	lipo -create $(shell find products/ios-simulator/static-libraries -name "libzcashlc.a") -output $@

products/ios-device/universal/libzcashlc.a: $(IOS_DEVICE_ARCHS)
	mkdir -p $(@D)
	lipo -create $(shell find products/ios-device/static-libraries -name "libzcashlc.a") -output $@

$(MACOS_ARCHS): %: stable-%
	mkdir -p products/macos/static-libraries/$*
	# cp $< products/macos/static-libraries/$*
	cp target/$*/debug/libzcashlc.a products/macos/static-libraries/$*
.PHONY: $(MACOS_ARCHS)

$(IOS_DEVICE_ARCHS): %: stable-%
	mkdir -p products/ios-device/static-libraries/$*
	cp target/$*/debug/libzcashlc.a products/ios-device/static-libraries/$*
.PHONY: $(IOS_DEVICE_ARCHS)

$(IOS_SIM_ARCHS_STABLE): %: stable-%
	mkdir -p products/ios-simulator/static-libraries/$*
	cp target/$*/debug/libzcashlc.a products/ios-simulator/static-libraries/$*
.PHONY: $(IOS_SIM_ARCHS_STABLE)

$(IOS_SIM_ARCHS_NIGHTLY): %: nightly-%
	mkdir -p products/ios-simulator/static-libraries/$*
	cp target/$*/debug/libzcashlc.a products/ios-simulator/static-libraries/$*
.PHONY: $(IOS_SIM_ARCHS_NIGHTLY)

nightly-%:
	sh -c "RUSTUP_TOOLCHAIN=nightly-2021-09-24 cargo build --manifest-path Cargo.toml --target $*"

stable-%: # target/%/debug/libzcashlc.a:
	cargo build --manifest-path Cargo.toml --target $*


# products/static-libraries/ios-simulator/libzcashlc.a: $(RUST_SRCS)
# 	mkdir -p $(@D)
# 	echo ${IOS_SIM_ARCHS_STABLE} \
# 	| tr ' ' '\0' \
# 	| xargs -0 -I% \
# 	cargo build --manifest-path Cargo.toml --target %
# 	echo ${IOS_SIM_ARCHS_NIGHTLY} \
# 	| tr ' ' '\n' \
# 	| xargs -n1 -I% \
# 	sh -c "RUSTUP_TOOLCHAIN=nightly-2021-09-24 cargo build --manifest-path Cargo.toml --target %"
# 	echo "${IOS_SIM_ARCHS}" \
# 	| tr ' ' '\n' \
# 	| xargs -I% \
# 	echo "target/%/debug/libzcashlc.a" \
# 	| tr '\n' ' ' \
# 	| { read libraries; sh -c "lipo -create $$libraries -output $@" }

# products/static-libraries/ios-device/libzcashlc.a: $(RUST_SRCS)
# 	mkdir -p $(@D)
# 	echo ${IOS_DEVICE_ARCHS} \
# 	| tr ' ' '\0' \
# 	| xargs -0 -I% \
# 	cargo build --manifest-path Cargo.toml --target %
# 	echo "${IOS_DEVICE_ARCHS}" \
# 	| tr ' ' '\n' \
# 	| xargs -I% \
# 	echo "target/%/debug/libzcashlc.a" \
# 	| tr '\n' ' ' \
# 	| { read libraries; sh -c "lipo -create $$libraries -output $@" }

# products/static-libraries/macos/libzcashlc.a: $(RUST_SRCS)
# 	mkdir -p $(@D)
# 	echo ${MACOS_ARCHS} \
# 	| tr ' ' '\0' \
# 	| xargs -0 -I% \
# 	cargo build --manifest-path Cargo.toml --target %
# 	echo "${MACOS_ARCHS}" \
# 	| tr ' ' '\n' \
# 	| xargs -I% \
# 	echo "target/%/debug/libzcashlc.a" \
# 	| tr '\n' ' ' \
# 	| { read libraries; sh -c "lipo -create $$libraries -output $@" }
