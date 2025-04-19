const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const game = @import("game.zig");
const std = @import("std");

const DragAction = enum {
    None,
    Set,
    Clear,
};

pub fn main() !void {
    const tileCountX = 50;
    const tileCountY = 50;
    const windowSizeX = 1024;
    const windowSizeY = 1024;
    const tileSizeX = windowSizeX / tileCountX;
    const tileSizeY = windowSizeY / tileCountY;

    var paused = false;
    var step = false;
    var dragAction = DragAction.None;

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

    var tiles = game.allocateTiles(tileCountX, tileCountY) catch |err| {
        c.SDL_Log("Error allocating tiles: %s", "s");
        return err;
    };

    var quit = false;
    var lastUpdate = std.time.milliTimestamp();
    var lastClick = std.time.milliTimestamp();
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_MOUSEBUTTONDOWN => {
                    if (event.button.button == c.SDL_BUTTON_LEFT) {
                        const x: u64 = @intCast(@divTrunc(event.button.x, tileSizeX));
                        const y: u64 = @intCast(@divTrunc(event.button.y, tileSizeY));
                        if (x < tileCountX and y < tileCountY) {
                            lastClick = std.time.milliTimestamp();
                            std.debug.print("clicked on tile ({}, {})\n", .{ x, y });
                            tiles[y][x] = !tiles[y][x];
                            if (tiles[y][x]) {
                                dragAction = DragAction.Set;
                            } else {
                                dragAction = DragAction.Clear;
                            }
                        }
                    }
                },
                c.SDL_MOUSEBUTTONUP => {
                    if (event.button.button == c.SDL_BUTTON_LEFT) {
                        dragAction = DragAction.None;
                    }
                },
                c.SDL_MOUSEMOTION => {
                    if (event.motion.state == c.SDL_BUTTON_LMASK) {
                        const x: u64 = @intCast(@divTrunc(event.motion.x, tileSizeX));
                        const y: u64 = @intCast(@divTrunc(event.motion.y, tileSizeY));
                        if (x < tileCountX and y < tileCountY) {
                            lastClick = std.time.milliTimestamp();
                            std.debug.print("dragged on tile ({}, {})\n", .{ x, y });
                            if (dragAction == DragAction.Set) {
                                tiles[y][x] = true;
                            } else if (dragAction == DragAction.Clear) {
                                tiles[y][x] = false;
                            }
                        }
                    }
                },
                c.SDL_KEYDOWN => {
                    if (event.key.keysym.sym == c.SDLK_SPACE) {
                        paused = !paused;
                    }
                    if (event.key.keysym.sym == c.SDLK_RETURN) {
                        step = true;
                    }
                    if (event.key.keysym.sym == c.SDLK_r) {
                        game.randomizeTiles(tiles) catch |err| {
                            c.SDL_Log("Error randomizing tiles: %s", "s");
                            return err;
                        };
                    }
                    if (event.key.keysym.sym == c.SDLK_ESCAPE) {
                        quit = true;
                    }
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

        if (paused or lastClick + 1000 > std.time.milliTimestamp()) {
            _ = c.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
            const pauseRect = c.SDL_Rect{
                .x = windowSizeX - 20,
                .y = 0,
                .w = 20,
                .h = 20,
            };
            _ = c.SDL_RenderFillRect(renderer, &pauseRect);
        }
        c.SDL_RenderPresent(renderer);

        if ((lastUpdate + 100 < std.time.milliTimestamp() and lastClick + 1000 < std.time.milliTimestamp() and !paused) or step) {
            step = false;
            lastUpdate = std.time.milliTimestamp();
            tiles = game.updateTiles(tiles);
        }

        c.SDL_Delay(17);
    }
}
