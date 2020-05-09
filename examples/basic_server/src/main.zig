const Address = std.net.Address;
const allocator = std.heap.page_allocator;
const std = @import("std");
const Request = @import("request.zig").Request;
const Response = @import("response.zig").Response;
const Server = @import("server.zig").Server;


pub fn main() anyerror!void {
    var addr = try Address.parseIp("127.0.0.1", 8080);
    std.debug.warn("Listening on adress 127.0.0.1:8080...\n", .{});

    var server = Server.init(allocator);
    try server.listen(addr, callback);
}

fn callback(request: Request, response: *Response) void {
    response.statusCode = .Ok;
    response.body = "Hello World!"; // Segfault
}
