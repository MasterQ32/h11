const Allocator = std.mem.Allocator;
const h11 = @import("h11");
const std = @import("std");

pub const Response = struct {
    allocator: *Allocator,
    statusCode: h11.StatusCode,
    headers: []h11.HeaderField,
    body: []const u8,

    pub fn init(allocator: *Allocator) Response {
        return Response{
            .allocator = allocator,
            .statusCode = .Ok,
            .headers = &[_]h11.HeaderField{},
            .body = &[_]u8{},
        };
    }

    pub fn deinit(self: *Response) void {
        self.allocator.free(self.headers);
    }
};
