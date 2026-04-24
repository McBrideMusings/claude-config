---
name: init-tailscale-local-dev
description: Dev servers must only show local + Tailscale addresses. Apply this whenever setting up, configuring, or modifying any dev server.
alwaysApply: true
---

# Tailscale Dev Server Network Config

## Rule

When configuring any dev server (Vite, Next.js, Webpack, etc.):

1. **Bind to `0.0.0.0`** so the server is accessible from all interfaces
2. **Print only two addresses**: `localhost` (local) and the Tailscale IP (network)
3. **Never print other network interface IPs** — they're noise, especially on machines with multiple interfaces

This is a hard rule. No exceptions.

## IP Detection

Get the Tailscale IP by running:

```bash
tailscale ip -4
```

Then hardcode it as a const in the config file:

```typescript
const TAILSCALE_IP = process.env.TAILSCALE_IP || '100.114.249.118'
```

Always support `process.env.TAILSCALE_IP` as an override.

## Vite: Gold Standard Implementation

This is the reference pattern. Use it directly for any Vite project:

```typescript
import { defineConfig, type Plugin } from 'vite'

const TAILSCALE_IP = process.env.TAILSCALE_IP || '100.114.249.118'

function tailscaleNetwork(): Plugin {
  return {
    name: 'tailscale-network',
    configureServer(server) {
      const print = server.printUrls
      server.printUrls = () => {
        if (server.resolvedUrls) {
          server.resolvedUrls.network = server.resolvedUrls.network.map(
            url => url.replace(/\/\/[^:]+:/, `//${TAILSCALE_IP}:`)
          )
        }
        print()
      }
    },
  }
}

export default defineConfig({
  plugins: [tailscaleNetwork()],
  server: {
    host: '0.0.0.0',
  },
})
```

**How it works**: The plugin intercepts Vite's `server.printUrls` method. Before printing, it rewrites all network URLs to use the Tailscale IP instead of whatever interfaces the OS detected. The local URL prints unchanged.

## Other Frameworks

For non-Vite frameworks, apply the same principle:

- **Bind** to `0.0.0.0` for accessibility
- **Override** the URL printing mechanism to show only `localhost` and the Tailscale IP
- Adapt the Vite pattern as a model — the core idea is: control what gets *printed*, not what gets *bound*

### Next.js

There is no clean plugin hook. Instead, set the hostname explicitly:

```js
// next.config.js
module.exports = {
  // Next.js doesn't print extra IPs when hostname is explicit
}
// Start with: next dev -H 0.0.0.0
// Then manually log the Tailscale URL in a custom server or poststart script
```

### Webpack Dev Server

```js
// webpack.config.js
module.exports = {
  devServer: {
    host: '0.0.0.0',
    // webpack-dev-server doesn't have a clean URL override hook;
    // set `client.webSocketURL` to the Tailscale IP for HMR
    client: {
      webSocketURL: `ws://100.114.249.118:<port>/ws`,
    },
  },
}
```
