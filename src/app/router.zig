const httpz = @import("httpz");
const RequestMethods = @import("httpz").Method;

const App = @import("app.zig").App;
const RequestContext = @import("app.zig").RequestContext;
const RequestHandler = @import("app.zig").RequestHandler;
const RouterAction = @import("app.zig").RouterAction;
const RouterType = @import("app.zig").RouterType;

pub const AppRouter = struct {
    path: []const u8,
    method: httpz.Method,
    handler: RequestHandler,
    data: ?*const anyopaque = null,
    dispatcher: ?httpz.Dispatcher(*App, RequestHandler) = null,
};

pub const AppRouteGroup = struct {
    base_path: []const u8,
    routes: []const AppRouter,
    data: ?*const anyopaque = null,
    dispatcher: ?httpz.Dispatcher(*App, RequestHandler) = null,
};

pub fn setRoutes(globalRouter: RouterType) !void {
    const grouplist = @import("index.zig").routerList;

    inline for (grouplist) |group| {
        var router = globalRouter.group(group.base_path, .{
            .data = group.data,
            .dispatcher = group.dispatcher,
        });

        inline for (group.routes) |r| {
            switch (r.method) {
                RequestMethods.GET => router.get(r.path, r.handler, .{
                    .data = r.data,
                    .dispatcher = r.dispatcher,
                }),
                RequestMethods.POST => router.post(r.path, r.handler, .{
                    .data = r.data,
                    .dispatcher = r.dispatcher,
                }),
                RequestMethods.PUT => router.put(r.path, r.handler, .{
                    .data = r.data,
                    .dispatcher = r.dispatcher,
                }),
                RequestMethods.PATCH => router.patch(r.path, r.handler, .{
                    .data = r.data,
                    .dispatcher = r.dispatcher,
                }),
                RequestMethods.DELETE => router.delete(r.path, r.handler, .{
                    .data = r.data,
                    .dispatcher = r.dispatcher,
                }),
                else => {},
            }
        }
    }
}
