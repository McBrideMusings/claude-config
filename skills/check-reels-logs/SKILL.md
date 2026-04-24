---
name: check-reels-logs
description: Use when the user asks to check logs, review logs, look at errors, or debug issues with stash-reels. Queries the reels_logs SQLite table in the Stash database via GraphQL.
---

# Check Stash Reels Logs

Query the persistent logs stored in Stash's SQLite database by the stash-reels plugin logger.

## How It Works

The stash-reels plugin writes logs to a `reels_logs` table in Stash's SQLite database via the `execSQL`/`querySQL` GraphQL mutations. Logs include timestamp, level (debug/info/warn/error), tag (component name), message, and optional JSON data.

## Stash Server Address

The Stash server runs in Docker and is accessible at: `http://100.114.249.118:6969`

If that address fails, find it dynamically:
```bash
docker ps | grep stash
# Then use the mapped port from the output
```

## IMPORTANT: GraphQL Schema Notes

- Both `querySQL` and `execSQL` are **mutations** (not queries)
- `querySQL` returns `{ columns, rows }` — always select these subfields
- `execSQL` returns `{ rows_affected, last_insert_id }` — always select a subfield

## Query Commands

### Recent logs (last 100, most recent first):
```bash
curl -s http://100.114.249.118:6969/graphql -X POST -H "Content-Type: application/json" -d '{"query":"mutation { querySQL(sql: \"SELECT id, datetime(timestamp, '\''unixepoch'\'', '\''localtime'\'') as time, level, tag, message, data FROM reels_logs ORDER BY id DESC LIMIT 100\") { columns rows } }"}' | jq -r '.data.querySQL.rows[] | "\(.[1]) [\(.[2])] [\(.[3])] \(.[4])\(if .[5] then " | " + .[5] else "" end)"'
```

### Errors and warnings only:
```bash
curl -s http://100.114.249.118:6969/graphql -X POST -H "Content-Type: application/json" -d '{"query":"mutation { querySQL(sql: \"SELECT id, datetime(timestamp, '\''unixepoch'\'', '\''localtime'\'') as time, level, tag, message, data FROM reels_logs WHERE level IN ('\''error'\'', '\''warn'\'') ORDER BY id DESC LIMIT 100\") { columns rows } }"}' | jq -r '.data.querySQL.rows[] | "\(.[1]) [\(.[2])] [\(.[3])] \(.[4])\(if .[5] then " | " + .[5] else "" end)"'
```

### Logs for a specific tag/component:
Replace `TAG_NAME` with the tag (e.g., `init`, `behavior`, `gql`):
```bash
curl -s http://100.114.249.118:6969/graphql -X POST -H "Content-Type: application/json" -d '{"query":"mutation { querySQL(sql: \"SELECT id, datetime(timestamp, '\''unixepoch'\'', '\''localtime'\'') as time, level, tag, message, data FROM reels_logs WHERE tag = '\''TAG_NAME'\'' ORDER BY id DESC LIMIT 100\") { columns rows } }"}' | jq -r '.data.querySQL.rows[] | "\(.[1]) [\(.[2])] [\(.[3])] \(.[4])\(if .[5] then " | " + .[5] else "" end)"'
```

### Log count and build info:
```bash
curl -s http://100.114.249.118:6969/graphql -X POST -H "Content-Type: application/json" -d '{"query":"mutation { querySQL(sql: \"SELECT COUNT(*) as count, build_id, MIN(datetime(timestamp, '\''unixepoch'\'', '\''localtime'\'')), MAX(datetime(timestamp, '\''unixepoch'\'', '\''localtime'\'')) FROM reels_logs GROUP BY build_id\") { columns rows } }"}' | jq '.data.querySQL'
```

### Check if log table exists:
```bash
curl -s http://100.114.249.118:6969/graphql -X POST -H "Content-Type: application/json" -d '{"query":"mutation { querySQL(sql: \"SELECT name FROM sqlite_master WHERE type='\''table'\'' AND name='\''reels_logs'\''\") { columns rows } }"}' | jq '.data.querySQL'
```

### Raw JSON output (for programmatic parsing):
```bash
curl -s http://100.114.249.118:6969/graphql -X POST -H "Content-Type: application/json" -d '{"query":"mutation { querySQL(sql: \"SELECT * FROM reels_logs ORDER BY id DESC LIMIT 50\") { columns rows } }"}' | jq '.data.querySQL'
```

## Procedure

1. **Start by checking if the table exists and getting log stats** (count + build info query)
2. **If user reports a specific issue**, check errors/warnings first, then recent logs
3. **If exploring generally**, show the last 50-100 log entries
4. **Known tags** (component sources): `init`, `behavior`, `gql`, and any others added by `createLogger("tagName")` calls in the codebase
5. **If the Stash server is unreachable**, ask the user to verify Docker is running: `docker ps | grep stash`

## Log Table Schema

```sql
CREATE TABLE reels_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,       -- Unix epoch seconds
  level TEXT NOT NULL,               -- debug, info, warn, error
  tag TEXT NOT NULL,                 -- Component/module name
  message TEXT NOT NULL,             -- Human-readable message
  data TEXT,                         -- Optional JSON payload (max 2000 chars)
  build_id TEXT NOT NULL             -- Build timestamp, logs cleared on new build
);
```

## Important Notes

- Logs are **automatically cleared when a new build is deployed** (different build_id)
- Ring buffer caps at **1000 rows** (oldest deleted when exceeded)
- The logger batches writes every 3 seconds, so very recent logs may not be persisted yet
- `debug` level logs are included but may be noisy — filter by `warn`/`error` for issues
- The `data` column contains JSON-serialized extra context (error objects, scene IDs, etc.)
- To add logging to new components, use `import { createLogger } from "../utils/logger"` then `const log = createLogger("tagName")`
