
test: libfreetype
	zig test src/window.zig -rpath modules/zig-freetype2/modules/freetype2/objs/libs --library-path modules/zig-freetype2/modules/freetype2/objs/.libs --library SDL2_image --library SDL2 --library freetype --library c

libfreetype: modules/zig-freetype2/modules/freetype2/objs/.libs/libfreetype.so

modules/zig-freetype2/modules/freetype2/objs/.libs/libfreetype.so:
	cd modules/zig-freetype2/modules/freetype2 && sh ./autogen.sh && ./configure && make -j5

clean:
	rm -rf zig-cache modules/zig-freetype2/modules/freetype2/objs/.o modules/freetype2/objs/.libs
