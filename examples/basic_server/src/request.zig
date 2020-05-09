const std = @import("std");
const Allocator = std.mem.Allocator;
const h11 = @import("h11");

pub const Request = struct {
    allocator: *Allocator,
    method: []const u8,
    target: []const u8,
    headers: []h11.HeaderField,
    body: []const u8,
    // `buffer` stores the bytes read from the socket.
    // This allow to keep `headers` and `body` fields accessible after
    // the client  connection is deinitialized.
    buffer: []const u8,

    pub fn init(allocator: *Allocator) Request {
        return Request{
            .allocator = allocator,
            .method = "",
            .target = "",
            .headers = &[_]h11.HeaderField{},
            .body = &[_]u8{},
            .buffer = &[_]u8{}
        };
    }

    pub fn deinit(self: *Request) void {
        self.allocator.free(self.headers);
        self.allocator.free(self.buffer);
    }
};
