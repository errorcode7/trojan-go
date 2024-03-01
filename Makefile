NAME := trojan-go
PACKAGE_NAME := github.com/p4gefau1t/trojan-go
VERSION := `git describe --dirty`
COMMIT := `git rev-parse HEAD`

TARGET := $(DESTDIR)$(prefix)
PLATFORM := linux
BUILD_DIR := build
VAR_SETTING := -X $(PACKAGE_NAME)/constant.Version=$(VERSION) -X $(PACKAGE_NAME)/constant.Commit=$(COMMIT)
GOBUILD = env CGO_ENABLED=0 $(GO_DIR)go build -tags "full" -trimpath -ldflags="-s -w -buildid= $(VAR_SETTING)" -o $(BUILD_DIR)

.PHONY: trojan-go release test
normal: clean trojan-go

clean:
	rm -rf $(BUILD_DIR)
	rm -f *.zip
	rm -f *.dat

geoip.dat:
	wget --no-check-certificate https://github.com/v2fly/geoip/raw/release/geoip.dat

geoip-only-cn-private.dat:
	wget --no-check-certificate https://github.com/v2fly/geoip/raw/release/geoip-only-cn-private.dat

geosite.dat:
	wget --no-check-certificate https://github.com/v2fly/domain-list-community/raw/release/dlc.dat -O geosite.dat

test:
	# Disable Bloomfilter when testing
	SHADOWSOCKS_SF_CAPACITY="-1" $(GO_DIR)go test -v ./...

trojan-go:
	mkdir -p $(BUILD_DIR)
	$(GOBUILD)

install: $(BUILD_DIR)/$(NAME) geoip.dat geoip-only-cn-private.dat geosite.dat
	install -d $(TARGET)/etc/$(NAME) $(TARGET)/usr/lib/systemd/system/
	install example/*.json $(TARGET)/etc/$(NAME)/
	install -D $(BUILD_DIR)/$(NAME) $(TARGET)/usr/bin/$(NAME)
	install -D example/$(NAME).service $(TARGET)/usr/lib/systemd/system/
	install -D example/$(NAME)@.service $(TARGET)/usr/lib/systemd/system/
	$(shell [[ "$LD_LIBRARY_PATH:" = *libfakeroot:* ]] || systemctl daemon-reload)
	install -D geosite.dat $(TARGET)/usr/share/$(NAME)/geosite.dat
	install -D geoip.dat $(TARGET)/usr/share/$(NAME)/geoip.dat
	install -D geoip-only-cn-private.dat $(TARGET)/usr/share/$(NAME)/geoip-only-cn-private.dat
	ln -fs $(TARGET)/usr/share/$(NAME)/geoip.dat $(TARGET)/usr/bin/
	ln -fs $(TARGET)/usr/share/$(NAME)/geoip-only-cn-private.dat $(TARGET)/usr/bin/
	ln -fs $(TARGET)/usr/share/$(NAME)/geosite.dat $(TARGET)/usr/bin/

uninstall:
	rm $(TARGET)/usr/lib/systemd/system/$(NAME).service
	rm $(TARGET)/usr/lib/systemd/system/$(NAME)@.service
	$(shell [[ "$LD_LIBRARY_PATH:" = *libfakeroot:* ]] || systemctl daemon-reload)
	rm $(TARGET)/usr/bin/$(NAME)
	rm -rd $(TARGET)/etc/$(NAME)
	rm -rd $(TARGET)/usr/share/$(NAME)
	rm $(TARGET)/usr/bin/geoip.dat
	rm $(TARGET)/usr/bin/geoip-only-cn-private.dat
	rm $(TARGET)/usr/bin/geosite.dat

%.zip: % geosite.dat geoip.dat geoip-only-cn-private.dat
	@zip -du $(NAME)-$@ -j $(BUILD_DIR)/$</*
	@zip -du $(NAME)-$@ example/*
	@-zip -du $(NAME)-$@ *.dat
	@echo "<<< ---- $(NAME)-$@"

release: geosite.dat geoip.dat geoip-only-cn-private.dat darwin-amd64.zip darwin-arm64.zip linux-386.zip linux-amd64.zip \
	linux-arm.zip linux-armv5.zip linux-armv6.zip linux-armv7.zip linux-armv8.zip \
	linux-mips-softfloat.zip linux-mips-hardfloat.zip linux-mipsle-softfloat.zip linux-mipsle-hardfloat.zip \
	linux-mips64.zip linux-mips64le.zip freebsd-386.zip freebsd-amd64.zip \
	windows-386.zip windows-amd64.zip windows-arm.zip windows-armv6.zip windows-armv7.zip windows-arm64.zip

darwin-amd64:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=amd64 GOOS=darwin $(GOBUILD)/$@

darwin-arm64:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=arm64 GOOS=darwin $(GOBUILD)/$@

linux-386:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=386 GOOS=linux $(GOBUILD)/$@

linux-amd64:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=amd64 GOOS=linux $(GOBUILD)/$@

linux-arm:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=arm GOOS=linux $(GOBUILD)/$@

linux-armv5:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=arm GOOS=linux GOARM=5 $(GOBUILD)/$@

linux-armv6:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=arm GOOS=linux GOARM=6 $(GOBUILD)/$@

linux-armv7:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=arm GOOS=linux GOARM=7 $(GOBUILD)/$@

linux-armv8:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=arm64 GOOS=linux $(GOBUILD)/$@

linux-mips-softfloat:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=mips GOMIPS=softfloat GOOS=linux $(GOBUILD)/$@

linux-mips-hardfloat:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=mips GOMIPS=hardfloat GOOS=linux $(GOBUILD)/$@

linux-mipsle-softfloat:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=mipsle GOMIPS=softfloat GOOS=linux $(GOBUILD)/$@

linux-mipsle-hardfloat:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=mipsle GOMIPS=hardfloat GOOS=linux $(GOBUILD)/$@

linux-mips64:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=mips64 GOOS=linux $(GOBUILD)/$@

linux-mips64le:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=mips64le GOOS=linux $(GOBUILD)/$@

freebsd-386:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=386 GOOS=freebsd $(GOBUILD)/$@

freebsd-amd64:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=amd64 GOOS=freebsd $(GOBUILD)/$@

windows-386:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=386 GOOS=windows $(GOBUILD)/$@

windows-amd64:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=amd64 GOOS=windows $(GOBUILD)/$@

windows-arm:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=arm GOOS=windows $(GOBUILD)/$@

windows-armv6:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=arm GOOS=windows GOARM=6 $(GOBUILD)/$@

windows-armv7:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=arm GOOS=windows GOARM=7 $(GOBUILD)/$@

windows-arm64:
	mkdir -p $(BUILD_DIR)/$@
	GOARCH=arm64 GOOS=windows $(GOBUILD)/$@
