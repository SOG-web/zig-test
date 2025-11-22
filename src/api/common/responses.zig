const std = @import("std");
const httpz = @import("httpz");

/// Send a successful JSON response
pub fn sendSuccess(res: *httpz.Response, data: anytype) !void {
    res.status = 200;
    res.content_type = .JSON;
    try res.json(.{
        .success = true,
        .data = data,
    }, .{});
}

/// Send an error JSON response
pub fn sendError(res: *httpz.Response, status: u16, message: []const u8) !void {
    res.status = status;
    res.content_type = .JSON;
    try res.json(.{
        .success = false,
        .@"error" = message,
    }, .{});
}
