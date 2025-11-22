const std = @import("std");
const logz = @import("logz");
const Env = @import("dotenv");
const httpz = @import("httpz");
const CookieSameSite = httpz.response.CookieOpts.SameSite;

pub const Config = struct {
    // Enviroment
    environment: []const u8,
    public_host: []const u8,

    // Database configuration
    db_host: []const u8,
    db_port: u16,
    db_user: []const u8,
    db_password: []const u8,
    db_name: []const u8,
    db_pool_size: u16,

    // Server configuration
    server_port: u16,

    // CORS configuration
    cors_origin: []const u8,
    cors_headers: []const u8,
    cors_methods: []const u8,
    cors_max_age: []const u8,
    cors_credentials: []const u8,

    // Auth server configuration
    auth_server_url: []const u8,
    auth_server_api_key: []const u8,

    // redis configuration
    redis_address: []const u8,
    redis_password: ?[]const u8,
    redis_db: []const u8,

    // storage configuration
    storage_backend: []const u8,
    storage_base_dir: []const u8,
    storage_public_base_url: []const u8,

    // s3 configuration
    s3_endpoint: []const u8,
    s3_access_key_id: []const u8,
    s3_secret_access_key: []const u8,
    s3_region: []const u8,
    s3_bucket: []const u8,
    s3_public_base_url: []const u8,

    // user api configuration
    user_api_base_url: []const u8,
    user_api_secret: []const u8,

    // notification service configuration
    notification_base_url: []const u8,
    notification_api_key: []const u8,
    notification_timeout: u16,

    allocator: std.mem.Allocator,
    env: Env,

    pub fn loadFromEnv(allocator: std.mem.Allocator) !Config {
        var env = try Env.initWithPath(allocator, ".env", 1024 * 1024, true);
        errdefer env.deinit();

        // load environment configuration
        const environment = try env.getRequired("ENVIRONMENT");
        const public_host = try env.getRequired("PUBLIC_HOST");

        // Load database configuration
        const db_host = try env.getRequired("DB_HOST");
        const db_port = try parseU16(&env, "DB_PORT");
        const db_user = try env.getRequired("DB_USER");
        const db_password = try env.getRequired("DB_PASSWORD");
        const db_name = try env.getRequired("DB_NAME");
        const db_pool_size = try parseU16(&env, "DB_POOL_SIZE");

        // Load server configuration
        const server_port = try parseU16(&env, "SERVER_PORT");

        // Load CORS configuration
        const cors_origin = try env.getRequired("CORS_ORIGIN");
        const cors_headers = try env.getRequired("CORS_HEADERS");
        const cors_methods = try env.getRequired("CORS_METHODS");
        const cors_max_age = try env.getRequired("CORS_MAX_AGE");
        const cors_credentials = try env.getRequired("CORS_CREDENTIALS");

        // Load auth server configuration
        const auth_server_url = try env.getRequired("AUTH_SERVER_URL");
        const auth_server_api_key = try env.getRequired("AUTH_SERVER_API_KEY");

        // Load redis configuration
        const redis_address = try env.getRequired("REDIS_ADDRESS");
        const redis_password = env.get("REDIS_PASSWORD");
        const redis_db = try env.getRequired("REDIS_DB");

        // Load storage configuration
        const storage_backend = try env.getRequired("STORAGE_BACKEND");
        const storage_base_dir = try env.getRequired("STORAGE_BASE_DIR");
        const storage_public_base_url = try env.getRequired("STORAGE_PUBLIC_BASE_URL");

        // Load s3 configuration
        const s3_endpoint = try env.getRequired("S3_ENDPOINT");
        const s3_access_key_id = try env.getRequired("S3_ACCESS_KEY");
        const s3_secret_access_key = try env.getRequired("S3_SECRET_KEY");
        const s3_region = try env.getRequired("S3_REGION");
        const s3_bucket = try env.getRequired("S3_BUCKET");
        const s3_public_base_url = try env.getRequired("S3_PUBLIC_BASE_URL");

        // Load user api configuration
        const user_api_base_url = try env.getRequired("USER_API_BASE_URL");
        const user_api_secret = try env.getRequired("USER_API_SECRET");

        // Load notification service configuration
        const notification_base_url = try env.getRequired("NOTIFICATION_BASE_URL");
        const notification_api_key = try env.getRequired("NOTIFICATION_API_KEY");
        const notification_timeout = try parseU16(&env, "NOTIFICATION_TIMEOUT");

        return Config{
            .environment = environment,
            .public_host = public_host,
            .db_host = db_host,
            .db_port = db_port,
            .db_user = db_user,
            .db_password = db_password,
            .db_name = db_name,
            .db_pool_size = db_pool_size,
            .server_port = server_port,
            .cors_origin = cors_origin,
            .cors_headers = cors_headers,
            .cors_methods = cors_methods,
            .cors_max_age = cors_max_age,
            .cors_credentials = cors_credentials,
            .auth_server_url = auth_server_url,
            .auth_server_api_key = auth_server_api_key,
            .redis_address = redis_address,
            .redis_password = redis_password,
            .redis_db = redis_db,
            .storage_backend = storage_backend,
            .storage_base_dir = storage_base_dir,
            .storage_public_base_url = storage_public_base_url,
            .s3_endpoint = s3_endpoint,
            .s3_access_key_id = s3_access_key_id,
            .s3_secret_access_key = s3_secret_access_key,
            .s3_region = s3_region,
            .s3_bucket = s3_bucket,
            .s3_public_base_url = s3_public_base_url,
            .user_api_base_url = user_api_base_url,
            .user_api_secret = user_api_secret,
            .notification_base_url = notification_base_url,
            .notification_api_key = notification_api_key,
            .notification_timeout = notification_timeout,
            .allocator = allocator,
            .env = env,
        };
    }

    pub fn deinit(self: *Config) void {
        self.env.deinit();
    }

    fn parseU16(env: *Env, key: []const u8) !u16 {
        const value = env.get(key) orelse {
            logz.err().string("msg", "Required environment variable missing").string("key", key).log();
            return error.MissingRequiredEnvVar;
        };
        return std.fmt.parseInt(u16, value, 10) catch |err| {
            logz.err().err(err).string("msg", "Failed to parse environment variable").string("key", key).string("type", "u16").log();
            return error.InvalidEnvVarFormat;
        };
    }

    fn parseU32(env: *Env, key: []const u8) !u32 {
        const value = env.get(key) orelse {
            logz.err().string("msg", "Required environment variable missing").string("key", key).log();
            return error.MissingRequiredEnvVar;
        };
        return std.fmt.parseInt(u32, value, 10) catch |err| {
            logz.err().err(err).string("msg", "Failed to parse environment variable").string("key", key).string("type", "u32").log();
            return error.InvalidEnvVarFormat;
        };
    }

    fn parseU64(env: *Env, key: []const u8) !u64 {
        const value = env.get(key) orelse {
            logz.err().string("msg", "Required environment variable missing").string("key", key).log();
            return error.MissingRequiredEnvVar;
        };
        return std.fmt.parseInt(u64, value, 10) catch |err| {
            logz.err().err(err).string("msg", "Failed to parse environment variable").string("key", key).string("type", "u64").log();
            return error.InvalidEnvVarFormat;
        };
    }

    fn parseBool(env: *Env, key: []const u8) !bool {
        const value = env.get(key) orelse {
            logz.err().string("msg", "Required environment variable missing").string("key", key).log();
            return error.MissingRequiredEnvVar;
        };
        if (std.mem.eql(u8, value, "true")) {
            return true;
        } else if (std.mem.eql(u8, value, "false")) {
            return false;
        } else {
            logz.err().string("msg", "Failed to parse environment variable as bool").string("key", key).string("expected", "true or false").log();
            return error.InvalidEnvVarFormat;
        }
    }

    fn parseSameSite(env: *Env, key: []const u8) !CookieSameSite {
        const value = env.get(key) orelse {
            logz.err().string("msg", "Required environment variable missing").string("key", key).log();
            return error.MissingRequiredEnvVar;
        };
        if (std.mem.eql(u8, value, "lax")) {
            return .lax;
        } else if (std.mem.eql(u8, value, "strict")) {
            return .strict;
        } else if (std.mem.eql(u8, value, "none")) {
            return .none;
        } else {
            logz.err().string("msg", "Failed to parse environment variable as SameSite").string("key", key).string("expected", "lax, strict, or none").log();
            return error.InvalidEnvVarFormat;
        }
    }
};
