const std = @import("std");
const logz = @import("logz");
const Config = @import("config.zig").Config;
const pg = @import("pg");
const App = @import("app/app.zig").App;
const httpz = @import("httpz");
const router_list = @import("app/router.zig");
const TestService = @import("api/services/test_service.zig").TestService;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Initialize logz early before any logging
    try logz.setup(allocator, .{
        .level = .Info,
        .pool_size = 100,
        .buffer_size = 4096,
        .large_buffer_count = 8,
        .large_buffer_size = 16384,
        .output = .stdout,
        .encoding = .json,
    });
    defer logz.deinit();

    // Load configuration from .env file
    var config = try Config.loadFromEnv(allocator);
    defer config.deinit();

    logz.info().string("msg", "Starting reps server").int("port", config.server_port).log();
    logz.info().string("msg", "Auth server URL").string("url", config.auth_server_url).log();

    // Initialize database connection pool
    var db = try pg.Pool.init(allocator, .{
        .size = config.db_pool_size,
        .timeout = 30 * std.time.ms_per_s,
        .connect = .{
            .port = config.db_port,
            .host = config.db_host,
        },
        .auth = .{
            .username = config.db_user,
            .password = config.db_password,
            .database = config.db_name,
        },
    });
    defer db.deinit();

    var test_service = TestService.init(allocator);

    // Initialize app
    var app = App{
        .db = db,
        .config = &config,
        .test_service = &test_service,
    };
    defer app.deinit();

    // Initialize HTTP server
    var server = try httpz.Server(*App).init(
        allocator,
        .{
            .port = config.server_port,
            .address = "0.0.0.0",
        },
        &app,
    );

    defer {
        server.deinit();
        server.stop();
    }

    // Create CORS middleware
    const cors = try server.middleware(httpz.middleware.Cors, .{
        .origin = config.cors_origin,
        .headers = config.cors_headers,
        .methods = config.cors_methods,
        .max_age = config.cors_max_age,
        .credentials = config.cors_credentials,
    });

    // Setup router with CORS
    const router = try server.router(.{ .middlewares = &.{cors} });

    // Register vendor routes
    try router_list.setRoutes(router);

    logz.info().string("msg", "Vendor server is running").int("port", config.server_port).log();
    var url_buf: [256]u8 = undefined;
    const api_url = try std.fmt.bufPrint(&url_buf, "http://localhost:{d}/api/vendors", .{config.server_port});
    logz.info().string("msg", "Vendor API available").string("url", api_url).log();

    // Start listening
    try server.listen();
}
