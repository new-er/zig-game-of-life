const std = @import("std");

pub fn allocateTiles(rows: usize, cols: usize) ![][]bool {
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

    for (0..tiles.len) |row| {
        for (0..tiles[row].len) |col| {
            const randomBool = rand.boolean();
            tiles[row][col] = randomBool;
        }
    }
}

pub fn updateTiles(tiles: [][]bool) [][]bool {
    const rows = tiles.len;
    const cols = tiles[0].len;
    var newTiles = allocateTiles(rows, cols) catch |err| {
        std.debug.print("Error allocating new tiles: {}\n", .{err});
        return tiles;
    };

    for (0..rows) |row| {
        for (0..cols) |col| {
            const alive = tiles[row][col];
            const neighbors = countAliveNeighbors(tiles, row, col);
            if (alive) {
                newTiles[row][col] = neighbors == 2 or neighbors == 3;
            } else {
                newTiles[row][col] = neighbors == 3;
            }
        }
    }
    return newTiles;
}

pub fn countAliveNeighbors(tiles: [][]bool, row: u64, col: u64) u8 {
    const rows = tiles.len;
    const cols = tiles[0].len;
    var count: u8 = 0;

    for (0..3) |r| {
        for (0..3) |c| {
            if (r == 1 and c == 1) continue; // Skip the cell itself
            const rowI: i64 = @intCast(r);
            const colI: i64 = @intCast(c);
            const neighborRow = getIndexSafe(row, rows, rowI - 1);
            const neighborCol = getIndexSafe(col, cols, colI - 1);
            if (tiles[neighborRow][neighborCol]) {
                count += 1;
            }
        }
    }

    return count;
}

fn getIndexSafe(index: usize, length: usize, delta: isize) usize {
    std.debug.assert(length > 0);
    const signed_index: isize = @intCast(index);
    const signed_len: isize = @intCast(length);

    const shifted = signed_index + delta;
    const wrapped = @mod(shifted, signed_len);
    return @intCast(wrapped);
}
