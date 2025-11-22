const std = @import("std");
const httpz = @import("httpz");
const RequestContext = @import("../../../app/app.zig").RequestContext;
const responses = @import("../../common/responses.zig");
const TestService = @import("../../services/test_service.zig").TestService;
const logz = @import("logz");

pub fn testh(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    const query = try req.query();
    const limit_str = query.get("limit") orelse "10";
    const limit = std.fmt.parseInt(i32, limit_str, 10) catch 10;

    // logz.info().string("msg", "Handling /test").int("limit", limit).log();

    // Simulate memory allocation using arena allocator (ctx.allocator)
    const large_struct = try ctx.allocator.create(TestService.LargeStruct);
    @memset(large_struct, 0);

    try responses.sendSuccess(res, .{
        .limit = limit,
        .arena_allocation_size = large_struct.len,
    });
}

pub fn testServiceHandler(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    _ = req;
    // logz.info().string("msg", "Handling /test-service").log();
    // Use the service which uses the main allocator
    const result = try ctx.app.test_service.allocateHeavy();
    defer ctx.app.test_service.allocator.destroy(result);

    try responses.sendSuccess(res, .{
        .message = "Allocated 1MB using main allocator",
        .size = result.len,
    });
}

pub fn testErrorArena(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    _ = req;
    _ = res;
    // logz.info().string("msg", "Handling /test-error-arena").log();
    // Allocate using arena
    const large_struct = try ctx.allocator.create(TestService.LargeStruct);
    @memset(large_struct, 0);

    // Simulate error
    return error.SimulatedError;
}

pub fn testErrorMain(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    _ = req;
    _ = res;
    // logz.info().string("msg", "Handling /test-error-main").log();
    // Allocate using main allocator
    const result = try ctx.app.test_service.allocateHeavy();
    errdefer ctx.app.test_service.allocator.destroy(result);
    defer ctx.app.test_service.allocator.destroy(result);

    // Simulate error
    return error.SimulatedError;
}

const UserRow = struct {
    id: []const u8,
    email: []const u8,
};

pub fn testDB(ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) !void {
    _ = req;
    // logz.info().string("msg", "Handling /test-db").log();

    // Fetch data from database
    const query = "SELECT id, email FROM auth_users LIMIT 10";
    var result = try ctx.app.db.query(query, .{});
    defer result.deinit();

    var users = std.ArrayList(UserRow){};

    while (try result.next()) |row| {
        const id = row.get([]const u8, 0);
        const email = row.get([]const u8, 1);
        try users.append(ctx.allocator, .{ .id = id, .email = email });
    }

    try responses.sendSuccess(res, .{
        .users = users.items,
    });
}
