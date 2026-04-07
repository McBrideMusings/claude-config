---
description: Configure a dev server to show only localhost + Tailscale network addresses
---

# Init Tailscale Local Dev

Apply the Tailscale dev server network pattern to the current project.

## Steps

1. **Detect the Tailscale IP** by running `tailscale ip -4`. If unavailable, fall back to `100.114.249.118`.

2. **Find the dev server config** in the current project. Look for (in order):
   - `vite.config.ts` / `vite.config.js`
   - `next.config.js` / `next.config.mjs` / `next.config.ts`
   - `webpack.config.js` / `webpack.config.ts`
   - Other dev server configs

3. **For Vite projects**: Add the `tailscaleNetwork()` plugin with the detected IP hardcoded as a const. Full implementation:

   ```typescript
   const TAILSCALE_IP = process.env.TAILSCALE_IP || '<detected-ip>'

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
   ```

   - Add `tailscaleNetwork()` to the `plugins` array
   - Ensure `server.host` is set to `'0.0.0.0'`
   - Add `type Plugin` to the vite import if not already present

4. **For other frameworks**: Apply equivalent configuration following the same principle — bind `0.0.0.0`, control what gets printed.

5. **Report** what was configured: the detected IP, which config file was modified, and what was added.
