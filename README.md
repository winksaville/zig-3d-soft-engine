# 3D Soft engine written in zig

This is a first attempt by a person with no experience in
creating a 3D engine. So take everything you see with a
huge grain of salt. But if you have suggestions feel free to
raise an issure, provide a PR or contact me.

The engine is based on David Rousset's [tutorial](https://www.davrous.com/2013/06/13/tutorial-series-learning-how-to-write-a-3d-soft-engine-from-scratch-in-c-typescript-or-javascript/).

At the moment the code uses Marc Tiehuis's [sdl2]() code to implement scribling black dots in a white window. This code is based on Daniel D'Agostino [SDL2 Pixel Drawing tutorial](https://dzone.com/articles/sdl2-pixel-drawing) and the code is [here](https://bitbucket.org/dandago/gigilabs/src/6d0e98732ca84d7d2b6cc9099faa9f4ec548e103/Sdl2PixelDrawing/Sdl2PixelDrawing/main.cpp?at=master&fileviewer=file-view-default).

## Dependencies

* [Git Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
* [zig](https://ziglang.org/)
* [SDL2](https://www.libsdl.org/)
* [zig-sdl2](https://github.com/tiehuis/zig-sdl2) brought in as a submode and created by Marc TieHuis.

## Checkout
```
git clone --recurse-submodules https://github.com/winksaville/zig-3d-soft-engine
```

## Build
```
zig build
```

## Run
```
./3d-soft-engine
```
