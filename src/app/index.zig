const AppRouterGroup = @import("router.zig").AppRouteGroup;
const RequestMethods = @import("httpz").Method;
const test_handlers = @import("../api/protocol/http/test.zig");

pub const routerList = [_]AppRouterGroup{
    .{
        .base_path = "/api/v1",
        .routes = &.{
            .{
                .path = "/test",
                .method = RequestMethods.GET,
                .handler = test_handlers.testh,
            },
            .{
                .path = "/test-service",
                .method = RequestMethods.GET,
                .handler = test_handlers.testServiceHandler,
            },
            .{
                .path = "/test-error-arena",
                .method = RequestMethods.GET,
                .handler = test_handlers.testErrorArena,
            },
            .{
                .path = "/test-error-main",
                .method = RequestMethods.GET,
                .handler = test_handlers.testErrorMain,
            },
            .{
                .path = "/test-db",
                .method = RequestMethods.GET,
                .handler = test_handlers.testDB,
            },
        },
    },
};
