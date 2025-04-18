const std = @import("std");

pub fn allocateTiles(rows: u16, cols: u16) ![][]bool {
    const allocator = std.heap.page_allocator;

    const outer = try allocator.alloc([]bool, rows);

    for (outer) |*row| {
        row.* = try allocator.alloc(bool, cols);
        for (row.*) |*cell| {
            cell.* = false;
        }
    }
    return outer;
}

pub fn randomizeTiles(tiles: [][]bool) !void {
     var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    for (0.. tiles.len) |row| {
        for (0..tiles[row].len) |col| {
            const randomBool = rand.boolean();
            tiles[row][col] = randomBool;
        }
    }
}

pub fn updateTiles(tiles: [][]bool) !void {
    // Update the tiles based on the rules of Conway's Game of Life
    const rows = tiles.len;
    const cols = tiles[0].len;

    for (0..rows) |row| {
        for (0..cols) |col| {
            const alive = tiles[row][col];
            const neighbors = countAliveNeighbors(tiles, row, col);
            if (alive) {
                tiles[row][col] = neighbors == 2 or neighbors == 3;
            } else {
                tiles[row][col] = neighbors == 3;
            }
        }
    }
}

pub fn countAliveNeighbors(tiles: [][]bool, x: u64, y: u64) u8 {
    const rows = tiles.len;
    const cols = tiles[0].len;
    var count: u8 = 0;

    // Check all 8 possible neighbors
    for (0..3) |i| {
        for (0..3) |j| {
            if (i == 1 and j == 1) continue;
            var xPos = x + i;
            if (x + i > 1) {
                xPos = x + i - 1;
            }
            var yPos = y + j ;
            if (y + j > 1) {
                yPos = y + j - 1;
            }

            if (xPos < 0 or xPos >= rows or yPos < 0 or yPos >= cols) continue;
            if (tiles[xPos][yPos]) {
                count += 1;
            }
        }
    }

    return count;
}
