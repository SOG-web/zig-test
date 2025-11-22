const std = @import("std");
const logz = @import("logz");

pub const TestService = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) TestService {
        return .{
            .allocator = allocator,
        };
    }

    pub fn doSomethingWithAllocator(self: *TestService) ![]u8 {
        // logz.info().string("msg", "TestService: doSomethingWithAllocator").log();
        const msg = "Hello from TestService using main allocator!";
        const memory = try self.allocator.alloc(u8, msg.len);
        @memcpy(memory, msg);
        return memory;
    }

    pub const LargeStruct = [1024 * 1024]u8; // 1MB struct

    pub fn allocateHeavy(self: *TestService) !*LargeStruct {
        // logz.info().string("msg", "TestService: allocateHeavy").log();
        const ptr = try self.allocator.create(LargeStruct);
        @memset(ptr, 0);
        return ptr;
    }
};
