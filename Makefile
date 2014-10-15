WGET=wget
RM=rm -f
MV=mv
CP=cp
MKDIR=mkdir -p
PERL=perl

HOST_ARCH=i586-mingw32msvc

BUILD_ROOT=/home/ollisg/dev/bin-libarchive
BUILD_ARCH=x86_64-unknown-linux
BUILD_PREFIX=$(BUILD_ROOT)/local/$(LIBARCHIVE_VERSION)-$(BUILD_ARCH)/libarchive

LIBARCHIVE_VERSION=3.1.2
LIBARCHIVE_SRC_TAR=$(BUILD_ROOT)/src/libarchive-$(LIBARCHIVE_VERSION).tar.gz
LIBARCHIVE_CONFIGURE=--prefix=$(BUILD_PREFIX) \
	--without-xml2                        \
	--host=$(HOST_ARCH)                   \
	--build=$(BUILD_ARCH)
LIBARCHIVE_BIN_TAR=$(BUILD_ROOT)/dist/libarchive-$(LIBARCHIVE_VERSION)-$(HOST_ARCH).tar.gz
LIBARCHIVE_INSTALLER=$(BUILD_ROOT)/dist/libarchive-$(LIBARCHIVE_VERSION)-$(HOST_ARCH)-setup.exe
LIBARCHIVE_INSTALLER_OPTIONS=\
	--appname=libarchive			\
	--orgname='White Dactyl Labs'		\
	--version=$(LIBARCHIVE_VERSION)		\
	--icon=resource/icon.ico                \
	--nsi=$(BUILD_ROOT)/dist/libarchive-$(LIBARCHIVE_VERSION)-$(HOST_ARCH)-setup.nsi
	--description='Multi-format archive and compression library'

all: win32 win64

win32:
	$(MAKE) libarchive BUILD_ROOT=`pwd` HOST_ARCH=i586-mingw32msvc

win64:
	$(MAKE) libarchive BUILD_ROOT=`pwd` HOST_ARCH=x86_64-w64-mingw32

libarchive: $(LIBARCHIVE_BIN_TAR) $(LIBARCHIVE_INSTALLER)

$(LIBARCHIVE_INSTALLER): $(LIBARCHIVE_BIN_TAR)
	$(PERL) script/create_installer.pl $(LIBARCHIVE_BIN_TAR) --setup=$(LIBARCHIVE_INSTALLER) $(LIBARCHIVE_INSTALLER_OPTIONS)

$(LIBARCHIVE_BIN_TAR): $(LIBARCHIVE_SRC_TAR)
	$(MKDIR) build
	$(RM) -r build/libarchive-$(LIBARCHIVE_VERSION)
	cd build ; tar zxf $(LIBARCHIVE_SRC_TAR)
	cd build/libarchive-$(LIBARCHIVE_VERSION) ; ./configure $(LIBARCHIVE_CONFIGURE) && make V=1 && rm -rf $(BUILD_PREFIX) && make V=1 install
	$(MKDIR) $(BUILD_ROOT)/dist
	$(PERL) script/update_pkgconfig.pl $(BUILD_PREFIX)
	$(PERL) script/install_doco.pl build/libarchive-$(LIBARCHIVE_VERSION)/COPYING  $(BUILD_PREFIX)
	$(PERL) script/install_doco.pl build/libarchive-$(LIBARCHIVE_VERSION)/README   $(BUILD_PREFIX)
	$(PERL) script/install_doco.pl build/libarchive-$(LIBARCHIVE_VERSION)/NEWS     $(BUILD_PREFIX)
	cd $(BUILD_PREFIX)/.. ; tar zcvf $(LIBARCHIVE_BIN_TAR) libarchive

$(LIBARCHIVE_SRC_TAR):
	$(WGET) http://www.libarchive.org/downloads/libarchive-3.1.2.tar.gz -O $(LIBARCHIVE_SRC_TAR).tmp
	$(MV) $(LIBARCHIVE_SRC_TAR).tmp $(LIBARCHIVE_SRC_TAR)

clean:
	$(RM) src/*.tmp
	$(RM) -r local
	$(RM) -r build

realclean: clean
	$(RM) src/*.tar.gz
