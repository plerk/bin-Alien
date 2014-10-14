WGET=wget
RM=rm -f
MV=mv
MKDIR=mkdir -p

TARGET=i586-mingw32msvc

HOST_ARCH=$(TARGET)

BUILD_ROOT=/home/ollisg/dev/bin-libarchive
BUILD_ARCH=$(TARGET)
BUILD_PREFIX=$(BUILD_ROOT)/local/$(LIBARCHIVE_VERSION)-$(BUILD_ARCH)/libarchive

LIBARCHIVE_VERSION=3.1.2
LIBARCHIVE_TAR=$(BUILD_ROOT)/src/libarchive-$(LIBARCHIVE_VERSION).tar.gz
LIBARCHIVE_CONFIGURE=--prefix=$(BUILD_PREFIX) \
	--without-xml2                        \
	--host=$(HOST_ARCH)                   \
	--build=$(BUILD_ARCH)
LIBARCHIVE_BIN=$(BUILD_ROOT)/dist/libarchive-$(LIBARCHIVE_VERSION)-$(BUILD_ARCH).tar.gz


libarchive: $(LIBARCHIVE_BIN)

$(LIBARCHIVE_BIN): $(LIBARCHIVE_TAR)
	$(MKDIR) build
	cd build ; tar zxf $(LIBARCHIVE_TAR)
	cd build/libarchive-$(LIBARCHIVE_VERSION) ; ./configure $(LIBARCHIVE_CONFIGURE) && make V=1 && rm -rf $(BUILD_PREFIX) &&make V=1 install
	$(MKDIR) $(BUILD_ROOT)/dist
	cd $(BUILD_PREFIX)/.. ; tar zcvf $(LIBARCHIVE_BIN) libarchive

$(LIBARCHIVE_TAR):
	$(WGET) http://www.libarchive.org/downloads/libarchive-3.1.2.tar.gz -O $(LIBARCHIVE_TAR).tmp
	$(MV) $(LIBARCHIVE_TAR).tmp $(LIBARCHIVE_TAR)

clean:
	$(RM) src/*.tmp
	$(RM) -r local
	$(RM) -r build

realclean: clean
	$(RM) src/*.tar.gz
