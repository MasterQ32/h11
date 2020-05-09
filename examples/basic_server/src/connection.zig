const Allocator = std.mem.Allocator;
const File = std.fs.File;
const h11 = @import("h11");
const std = @import("std");
const Request = @import("request.zig").Request;
const Response = @import("response.zig").Response;
const StreamServer = std.net.StreamServer;

pub const Connection = struct {
    allocator: *Allocator,
    connection: h11.Server,
    socket: std.fs.File,

    pub fn init(allocator: *Allocator, socket: File) Connection {
        return Connection {
            .allocator = allocator,
            .connection = h11.Server.init(allocator),
            .socket = socket,
        };
    }

    pub fn accept(allocator: *Allocator, server: *StreamServer) !Connection {
        var connection = try server.accept();
        return Connection.init(allocator, connection.file);
    }

    pub fn deinit(self: *Connection) void {
        self.connection.deinit();
        self.socket.close();
    }

    pub fn readRequest(self: *Connection) !Request {
        var request = Request.init(self.allocator);

        while (true) {
            var event = try self.nextEvent();

            switch (event) {
                .Request => |*requestEvent| {
                    request.method = requestEvent.method;
                    request.target = requestEvent.target;
                    request.headers = requestEvent.headers;
                },
                .Data => |*dataEvent| {
                    request.body = dataEvent.body;
                },
                .EndOfMessage => {
                    request.buffer = self.connection.buffer.toOwnedSlice();
                    return request;
                },
                else => unreachable,
            }
        }
    }

    fn nextEvent(self: *Connection) !h11.Event {
        while (true) {
            var event = self.connection.nextEvent() catch |err| switch (err) {
                h11.EventError.NeedData => {
                    var requestBuffer = try self.allocator.alloc(u8, 4096);
                    defer self.allocator.free(requestBuffer);

                    var nBytes = try self.socket.read(requestBuffer);
                    try self.connection.receiveData(requestBuffer[0..nBytes]);
                    continue;
                },
                else => return err,
            };
            return event;
        }
    }

    pub fn send(self: *Connection, response: Response) !void {
        var data = try self.connection.send(h11.Event { .Response = h11.Response{ .statusCode = response.statusCode, .headers = response.headers }});
        _ = try self.socket.write(data);
        self.allocator.free(data);

        data = try self.connection.send(h11.Event { .Data = h11.Data{ .body = response.body }});
        _ = try self.socket.write(data);
        self.allocator.free(data);

        data = try self.connection.send(.EndOfMessage);
        _ = try self.socket.write(data);
        self.allocator.free(data);
    }
};
