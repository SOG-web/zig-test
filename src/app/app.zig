const std = @import("std");
const httpz = @import("httpz");
const pg = @import("pg");
const Config = @import("../config.zig").Config;
const logz = @import("logz");
const TestService = @import("../api/services/test_service.zig").TestService;

pub const App = struct {
    db: *pg.Pool,
    config: *const Config,
    test_service: *TestService,

    pub fn deinit(self: *App) void {
        _ = self;
    }

    pub fn dispatch(self: *App, action: RouterAction, req: *httpz.Request, res: *httpz.Response) !void {
        //logz.info().string("msg", "Request received").string("method", @tagName(req.method)).string("path", req.url.path).log();
        var ctx = RequestContext{
            .allocator = req.arena,
            .app = self,
        };
        defer ctx.deinit();

        try action(&ctx, req, res);
        //logz.info().string("msg", "Request processed").string("method", @tagName(req.method)).string("path", req.url.path).log();
    }

    pub fn notFound(_: *App, req: *httpz.Request, res: *httpz.Response) !void {
        //logz.info().string("method", @tagName(req.method)).string("path", req.url.path).int("status", 404).log();
        res.status = 404;
        res.body = "Not Found";
        _ = req;
    }

    pub fn uncaughtError(_: *App, req: *httpz.Request, res: *httpz.Response, err: anyerror) void {
        //logz.err().string("method", @tagName(req.method)).string("path", req.url.path).err(err).int("status", 500).log();
        res.status = 500;
        res.json(.{
            .success = false,
            .error_message = @errorName(err),
        }, .{}) catch |send_err| {
            logz.err().err(send_err).string("msg", "Error sending error response").log();
            res.status = 500;
            res.body = "Internal server error";
        };
        _ = req;
    }
};

pub const RequestContext = struct {
    allocator: std.mem.Allocator,
    app: *App,

    pub fn deinit(self: *RequestContext) void {
        _ = self;
    }
};

pub const RequestHandler = *const fn (ctx: *RequestContext, req: *httpz.Request, res: *httpz.Response) anyerror!void;

pub const RouterType = *httpz.Router(*App, RequestHandler);

pub const RouterAction = httpz.Action(*RequestContext);
