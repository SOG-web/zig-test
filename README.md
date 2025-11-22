# Vendor Server

This is the Vendor Server application.

## Load Testing

This project includes several shell scripts to perform load testing and verify memory usage behavior under different scenarios.

### Prerequisites
- Ensure the server is running (e.g., `make watch` or `zig build run`).
- Ensure `curl` is installed.

### 1. Heavy Memory Allocation (`load_test.sh`)
Tests memory allocation and deallocation for successful requests. It compares the Arena Allocator (automatically freed) vs. the Main Allocator (manually freed).

**Usage:**
```bash
# Run both Arena and Main allocator tests
./load_test.sh

# Run only Arena allocator test
./load_test.sh arena

# Run only Main allocator test
./load_test.sh main
```

**Endpoints Tested:**
- `/api/v1/test` (Arena Allocator)
- `/api/v1/test-service` (Main Allocator)

### 2. Error Case Memory Behavior (`load_test_error.sh`)
Tests memory behavior when handlers return errors. This is useful for verifying that memory is correctly freed even when requests fail.

**Usage:**
```bash
# Run both Arena and Main allocator error tests
./load_test_error.sh

# Run only Arena allocator error test
./load_test_error.sh arena

# Run only Main allocator error test
./load_test_error.sh main
```

**Endpoints Tested:**
- `/api/v1/test-error-arena` (Arena Allocator + Error)
- `/api/v1/test-error-main` (Main Allocator + Error)

### 3. Database Interaction (`load_test_db.sh`)
Tests database connectivity and memory usage during database operations.

**Usage:**
```bash
./load_test_db.sh
```

**Endpoints Tested:**
- `/api/v1/test-db` (Fetches data from `auth_users`)
