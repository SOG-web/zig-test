const std = @import("std");
const Parsed = std.json.Parsed;

fn destroyValue(comptime T: type, allocator: std.mem.Allocator, value: T) void {
    switch (@typeInfo(T)) {
        .pointer => |info| switch (info.size) {
            .slice => {
                const Child = info.child;
                if (Child == u8) {
                    allocator.free(@constCast(value));
                } else {
                    for (value) |item| {
                        destroyValue(Child, allocator, item);
                    }
                    allocator.free(@constCast(value));
                }
            },
            else => {},
        },
        .array => |info| {
            const Child = info.child;
            inline for (0..info.len) |idx| {
                destroyValue(Child, allocator, value[idx]);
            }
        },
        .@"struct" => |info| {
            inline for (info.fields) |field| {
                if (field.is_comptime) continue;
                destroyValue(field.type, allocator, @field(value, field.name));
            }
        },
        .optional => |info| {
            if (value) |inner| {
                destroyValue(info.child, allocator, inner);
            }
        },
        else => {},
    }
}

fn cloneValue(comptime T: type, allocator: std.mem.Allocator, value: T) !T {
    return switch (@typeInfo(T)) {
        .pointer => |info| switch (info.size) {
            .slice => {
                if (value.len == 0) return value;

                const Child = info.child;
                if (Child == u8) {
                    return try allocator.dupe(u8, value);
                }

                var new_slice = try allocator.alloc(Child, value.len);
                var idx: usize = 0;
                errdefer {
                    while (idx > 0) {
                        idx -= 1;
                        destroyValue(Child, allocator, new_slice[idx]);
                    }
                    allocator.free(new_slice);
                }

                while (idx < value.len) : (idx += 1) {
                    new_slice[idx] = try cloneValue(Child, allocator, value[idx]);
                }

                return new_slice;
            },
            else => value,
        },
        .array => |info| {
            const Child = info.child;
            var result: T = undefined;
            inline for (0..info.len) |idx| {
                result[idx] = try cloneValue(Child, allocator, value[idx]);
            }
            return result;
        },
        .@"struct" => |info| {
            var result: T = undefined;
            inline for (info.fields) |field| {
                if (field.is_comptime) continue;
                @field(result, field.name) = try cloneValue(field.type, allocator, @field(value, field.name));
            }
            return result;
        },
        .optional => |info| {
            var optional_result: ?info.child = null;
            if (value) |inner| {
                optional_result = try cloneValue(info.child, allocator, inner);
            }
            return optional_result;
        },
        else => value,
    };
}

pub fn freeStruct(comptime T: type, allocator: std.mem.Allocator, value: *T) void {
    destroyValue(T, allocator, value.*);
}

pub fn stringifyStruct(
    allocator: std.mem.Allocator,
    value: anytype,
) ![]u8 {
    var buf = std.ArrayList(u8){};
    defer buf.deinit(allocator);

    var writer = buf.writer(allocator);
    var adapter = writer.adaptToNewApi(&.{});
    const w: *std.Io.Writer = &adapter.new_interface;

    try std.json.fmt(
        value,
        .{},
    ).format(w);
    return buf.toOwnedSlice(allocator);
}

pub fn parseStruct(comptime T: type, allocator: std.mem.Allocator, json_str: []const u8) !T {
    // Parse the JSON string into a std.json.Value
    const parsed: Parsed(T) = try std.json.parseFromSlice(
        T,
        allocator,
        json_str,
        .{
            .ignore_unknown_fields = true,
        },
    );
    defer parsed.deinit();

    return try cloneValue(T, allocator, parsed.value);
}

test "stringifyStruct" {
    const allocator = std.testing.allocator;
    const Add = struct { left: u8, right: u8 };

    const EmailAddress = struct {
        name: ?[]const u8 = null,
        address: []const u8,
        fields: struct { name: ?[]const u8 = "none", add: Add },
    };

    const address = EmailAddress{
        .name = "ola",
        .address = "address",
        .fields = .{
            .add = .{ .left = 10, .right = 20 },
        },
    };
    const json = try stringifyStruct(allocator, address);
    defer allocator.free(json);
    try std.testing.expectEqualStrings(
        "{\"name\":\"ola\",\"address\":\"address\",\"fields\":{\"name\":\"none\",\"add\":{\"left\":10,\"right\":20}}}",
        json,
    );
}

test "parseStruct" {
    const allocator = std.testing.allocator;

    const Add = struct { left: u8, right: u8 };

    const EmailAddress = struct {
        name: ?[]const u8 = null,
        address: []const u8,
        fields: struct { name: ?[]const u8 = "none", add: Add },
    };

    const json = "{\"name\":\"ola\",\"address\":\"address\",\"fields\":{\"name\":\"none\",\"add\":{\"left\":10,\"right\":20}}}";
    var address = try parseStruct(EmailAddress, allocator, json);
    errdefer freeStruct(EmailAddress, allocator, &address);
    defer freeStruct(EmailAddress, allocator, &address);

    try std.testing.expect(address.name != null);
    try std.testing.expectEqualStrings("ola", address.name.?);
    try std.testing.expectEqualStrings("address", address.address);
    try std.testing.expect(address.fields.name != null);
    try std.testing.expectEqualStrings("none", address.fields.name.?);
    try std.testing.expectEqual(@as(u8, 10), address.fields.add.left);
    try std.testing.expectEqual(@as(u8, 20), address.fields.add.right);
}

test "parseStruct array" {
    const allocator = std.testing.allocator;

    const Add = struct { left: u8, right: u8 };

    const EmailAddress = struct {
        name: ?[]const u8 = null,
        address: []const u8,
        fields: struct { name: ?[]const u8 = "none", add: Add },
    };

    var arr = std.ArrayList(EmailAddress){};
    defer arr.deinit(allocator);

    try arr.append(allocator, .{
        .name = "ola",
        .address = "address",
        .fields = .{
            .add = .{ .left = 10, .right = 20 },
        },
    });

    try arr.append(allocator, .{
        .name = "ola",
        .address = "address",
        .fields = .{
            .add = .{ .left = 10, .right = 20 },
        },
    });

    const json = try stringifyStruct(allocator, arr.items);
    defer allocator.free(json);
    try std.testing.expectEqualStrings(
        "[{\"name\":\"ola\",\"address\":\"address\",\"fields\":{\"name\":\"none\",\"add\":{\"left\":10,\"right\":20}}},{\"name\":\"ola\",\"address\":\"address\",\"fields\":{\"name\":\"none\",\"add\":{\"left\":10,\"right\":20}}}]",
        json,
    );

    var parsed = try parseStruct([]EmailAddress, allocator, json);
    defer freeStruct([]EmailAddress, allocator, &parsed);
    try std.testing.expectEqual(@as(usize, 2), parsed.len);
    try std.testing.expect(parsed[0].name != null);
    try std.testing.expectEqualStrings("ola", parsed[0].name.?);
    try std.testing.expectEqualStrings("address", parsed[0].address);
    try std.testing.expect(parsed[0].fields.name != null);
    try std.testing.expectEqualStrings("none", parsed[0].fields.name.?);
    try std.testing.expectEqual(@as(u8, 10), parsed[0].fields.add.left);
    try std.testing.expectEqual(@as(u8, 20), parsed[0].fields.add.right);
    try std.testing.expect(parsed[1].name != null);
    try std.testing.expectEqualStrings("ola", parsed[1].name.?);
}
