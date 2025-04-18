const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const game = @import("game.zig");
const std = @import("std");

pub fn main() !void {
    const tileCountX = 40;
    const tileCountY = 40;
    const windowSizeX = 640;
    const windowSizeY = 640;
    const tileSizeX = windowSizeX / tileCountX;
    const tileSizeY = windowSizeY / tileCountY;

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow("Game of Life", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, windowSizeX, windowSizeY, c.SDL_WINDOW_OPENGL) orelse
        {
            c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
    defer c.SDL_DestroyWindow(screen);

    const renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    const tiles = game.allocateTiles(tileCountX, tileCountY) catch |err| {
        c.SDL_Log("Error allocating tiles: %s", "s");
        return err;
    };
    game.randomizeTiles(tiles) catch |err| {
        c.SDL_Log("Error randomizing tiles: %s", "s");
        return err;
    };

    var quit = false;
    var lastUpdate = std.time.milliTimestamp();
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }

        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(renderer);

        for (tiles, 0..) |row, rowIndex| {
            for (row, 0..) |tile, colIndex| {
                if (tile) {
                    const rect = c.SDL_Rect{
                        .x = @intCast(colIndex * tileSizeX),
                        .y = @intCast(rowIndex * tileSizeY),
                        .w = tileSizeX,
                        .h = tileSizeY,
                    };

                    _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
                    _ = c.SDL_RenderFillRect(renderer, &rect);
                }
            }
        }
        c.SDL_RenderPresent(renderer);

        if (lastUpdate + 100 < std.time.milliTimestamp()) {
            lastUpdate = std.time.milliTimestamp();
            game.updateTiles(tiles) catch |err| {
                c.SDL_Log("Error updating tiles: %s", err);
                return err;
            };
        }

        c.SDL_Delay(17);
    }
}
