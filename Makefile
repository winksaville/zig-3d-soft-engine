
test: libfreetype
	zig test src/test-window.zig -rpath modules/zig-freetype2/modules/freetype2/objs/libs --library-path modules/zig-freetype2/modules/freetype2/objs/.libs --library SDL2_image --library SDL2 --library freetype --library c

testfilter: libfreetype
	zig test src/test-window.zig --test-filter $(testname) -rpath modules/zig-freetype2/modules/freetype2/objs/.libs --library-path modules/zig-freetype2/modules/freetype2/objs/.libs --library SDL2_image --library SDL2 --library freetype --library c

libfreetype: src/modules/zig-freetype2/modules/freetype2/objs/.libs/libfreetype.so

src/modules/zig-freetype2/modules/freetype2/objs/.libs/libfreetype.so:
	cd src/modules/zig-freetype2/modules/freetype2 && sh ./autogen.sh && ./configure && make -j5

clean:
	rm -rf zig-cache modules/zig-freetype2/modules/freetype2/objs/.o modules/zig-freetype2/modules/freetype2/objs/.libs
