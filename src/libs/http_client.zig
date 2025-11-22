const std = @import("std");
const zul = @import("zul");

pub const HttpError = error{
    ConnectionFailed,
    InvalidResponse,
    Unauthorized,
    ServerError,
};

pub const HttpResponse = struct {
    status_code: u16,
    body: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *HttpResponse) void {
        self.allocator.free(self.body);
    }
};

/// Make an HTTP GET request with Authorization header
pub fn httpGet(
    allocator: std.mem.Allocator,
    url: []const u8,
    access_token: ?[]const u8,
) !HttpResponse {
    // Create HTTP client
    var client = zul.http.Client.init(allocator);
    defer client.deinit();

    // Create request
    var req = try client.request(url);
    defer req.deinit();

    // Add Authorization header if token is provided
    var auth_header_mem: ?[]u8 = null;
    defer if (auth_header_mem) |mem| allocator.free(mem);

    if (access_token) |token| {
        // Allocate buffer for "Bearer " prefix + token (7 chars + token length)
        const auth_header_len = 7 + token.len;
        auth_header_mem = try allocator.alloc(u8, auth_header_len);

        const auth_header = try std.fmt.bufPrint(auth_header_mem.?, "Bearer {s}", .{token});
        try req.header("authorization", auth_header);
    }

    // Execute request and get response
    var res = try req.getResponse(.{});
    const status_code = res.status;

    // Read response body
    var body_builder = try res.allocBody(allocator, .{});
    defer body_builder.deinit();

    // Convert StringBuilder to []const u8 using copy() to get owned slice
    const body = try body_builder.copy(allocator);

    return HttpResponse{
        .status_code = status_code,
        .body = body,
        .allocator = allocator,
    };
}
