#!/bin/bash

# usage: . ./tools.sh tooldir [tool]...

# define toolchain
XCODE_APP=`dirname \`dirname \\\`xcode-select -p \\\`\``
XCODE_DEVELOPER_PREFIX=$XCODE_APP/Contents/Developer
CCTOOLCHAIN_PREFIX=$XCODE_APP/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
OLDPATH=$PATH
export PATH=$TOOL_PREFIX/usr/bin:$PATH
export PATH=$CCTOOLCHAIN_PREFIX/usr/bin:$PATH

# define build environment
TOOL_DIR="$1"
if test ".$TOOL_DIR" = "." ; then 
	TOOL_DIR="`pwd`/tools"
fi
if test ".$DOWNLOAD_DIR" = "." ; then
	DOWNLOAD_DIR="$TOOL_DIR/downloads"
fi
if test ".$TMP" = "." ; then
	TMP=/tmp
fi
if test ".$TMP_DIR" = "." ; then
	TMP_DIR="$TMP/$$.work"
fi

download_and_open() {
	URL="$1"
	FILE="$DOWNLOAD_DIR/`basename $URL`"
	DEST="$2"
	if ! test -f "$FILE" ; then 
		pushd "$DOWNLOAD_DIR"
		curl -O -L "$URL"
		popd
	fi
	if test -d "$DEST" ; then
		return
	fi
	rm -fr "$TMP_DIR/dno"	
	mkdir -p "$TMP_DIR/dno"	
	pushd "$TMP_DIR/dno"	
	tar -xvf "$FILE"
	mv * "$DEST"
	popd
	rm -fr "$TMP_DIR/dno"	
}

clone_or_update() {
	URL="$1"
	DEST="$2"
	if ! test -d "$DEST" ; then 
		git clone "$URL" "$DEST"
	else
		pushd "$DEST"
		git pull 
		popd
	fi	
}

build_autoconf() {
	if test -d "$TOOL_DIR/autoconf" ; then
		return
	fi
	download_and_open http://ftpmirror.gnu.org/autoconf/autoconf-2.69.tar.gz "$TOOL_DIR/autoconf"
	pushd "$TOOL_DIR/autoconf"
	./configure --prefix=`pwd`
	make install
	popd
}

build_cmake() {
	if test -d "$TOOL_DIR/cmake" ; then 
		return
	fi
	download_and_open https://github.com/Kitware/CMake/releases/download/v3.14.3/cmake-3.14.3-Darwin-x86_64.tar.gz "$TOOL_DIR/cmake"
}

build_mvn() {
	if test -d "$TOOL_DIR/apache-maven"; then
		return
	fi
	download_and_open http://muug.ca/mirror/apache-dist/maven/maven-3/3.6.1/binaries/apache-maven-3.6.1-bin.tar.gz "$TOOL_DIR/apache-maven"
}

build_freetype() {
	if test -d "$TOOL_DIR/freetype" ; then
		return
	fi
	download_and_open https://nongnu.freemirror.org/nongnu/freetype/freetype-2.9.tar.gz "$TOOL_DIR/freetype"
	pushd "$TOOL_DIR/freetype"
	./configure
	make
	popd
}

build_mercurial() {
	if test -f "$TOOL_DIR/mercurial/hg" ; then
		return
	fi
	download_and_open https://www.mercurial-scm.org/release/mercurial-4.9.tar.gz "$TOOL_DIR/mercurial"
	pushd "$TOOL_DIR/mercurial"
	make local
	popd
}

build_bootstrap_jdk8() {
	if test -d "$TOOL_DIR/jdk8u" ; then
		return
	fi
	download_and_open https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u202-b08/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz "$TOOL_DIR/jdk8u"
}

build_bootstrap_jdk10() {
	if test -d "$TOOL_DIR/jdk10u" ; then
		return
	fi
	download_and_open https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u202-b08/OpenJDK8U-jdk_x64_mac_hotspot_8u202b08.tar.gz "$TOOL_DIR/jdk10u"
}

build_bootstrap_jdk11() {
	if test -d "$TOOL_DIR/jdk11u" ; then
                return
        fi
        download_and_open https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.2%2B9/OpenJDK11U-jdk_x64_mac_hotspot_11.0.2_9.tar.gz "$TOOL_DIR/jdk11u"
}

build_bootstrap_jdk12() {
        if test -d "$TOOL_DIR/jdk12u" ; then
                return
        fi
        download_and_open https://github.com/AdoptOpenJDK/openjdk12-binaries/releases/download/jdk-12%2B33/OpenJDK12U-jdk_x64_mac_hotspot_12_33.tar.gz "$TOOL_DIR/jdk12u"
}

build_webrev() {
	if test -f "$TOOL_DIR/webrev/webrev.ksh" ; then
		return
	fi
	pushd "$TOOL_DIR"
	mkdir -p "$TOOL_DIR/webrev"
	cd "$TOOL_DIR/webrev"
	curl -O -L https://hg.openjdk.java.net/code-tools/webrev/raw-file/tip/webrev.ksh
	chmod 755 webrev.ksh
	popd
}

buildtools() {
	mkdir -p "$DOWNLOAD_DIR"
	mkdir -p "$TOOL_DIR"

	for tool in $* ; do 
		echo "building $tool"
		build_$tool
		if test $tool == "bootstrap_jdk8" ; then
			export JAVA_HOME=$TOOL_DIR/jdk8u/Contents/Home
		fi
		if test $tool = "bootstrap_jdk9" ; then
                        export JAVA_HOME=$TOOL_DIR/jdk9u/Contents/Home
                fi
		if test $tool = "bootstrap_jdk10" ; then
                        export JAVA_HOME=$TOOL_DIR/jdk10u/Contents/Home
                fi
		if test $tool = "bootstrap_jdk11" ; then
                        export JAVA_HOME=$TOOL_DIR/jdk11u/Contents/Home
                fi
		if test $tool = "bootstrap_jdk12" ; then
                        export JAVA_HOME=$TOOL_DIR/jdk12u/Contents/Home
                fi
	done
}

export PATH=$OLDPATH
export PATH=$TOOL_DIR/apache-maven/bin:$PATH
export PATH=$TOOL_DIR/autoconf/bin:$PATH
export PATH=$TOOL_DIR/cmake:$PATH
export PATH=$TOOL_DIR/mercurial:$PATH
# export PATH=$TOOL_DIR/apache-ant/bin:$PATH
export PATH=$TOOL_DIR/webrev:$PATH
export PATH=$TOOL_DIR/jtreg:$PATH
export PATH=$JAVA_HOME/bin:$PATH

mkdir -p "$TMP_DIR"
shift
buildtools $*
rm -fr "$TMP_DIR"
