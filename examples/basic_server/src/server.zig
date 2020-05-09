const Address = std.net.Address;
const Allocator = std.mem.Allocator;
const Connection = @import("connection.zig").Connection;
const Response = @import("response.zig").Response;
const std = @import("std");
const StreamServer = std.net.StreamServer;

pub const Server = struct {
    allocator: *Allocator,
    server: StreamServer,

    pub fn init(allocator: *Allocator) Server {
        return Server {
            .allocator = allocator,
            .server = StreamServer.init(.{})
        };
    }

    pub fn listen(self: *Server, address: Address, callback: var) !void {
        var server = &self.server;
        defer server.deinit();

        try self.server.listen(address);
        while (true) {
            var connection = Connection.accept(self.allocator, server) catch {
                std.debug.warn("Failed to accept the connection for some reasons; wait for the next...", .{});
                continue;
            };
            defer connection.deinit();

            var request = try connection.readRequest();
            defer request.deinit();

            var response = Response.init(self.allocator);
            defer response.deinit();

            // Give request to handler
            callback(request, &response);

            try connection.send(response);

            // Write response
            //_ = try connection.socket.write("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n");
        }
    }
};
