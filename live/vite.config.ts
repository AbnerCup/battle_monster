import { defineConfig, type Plugin } from 'vite';
import { resolve } from 'node:path';
// @ts-ignore - módulo JS compartido con el servidor de producción
import { createAvatarHandler } from './server/avatarProxy.mjs';

function avatarProxy(): Plugin {
  const handle = createAvatarHandler({ cacheDir: resolve(__dirname, '.cache/avatars') });
  return {
    name: 'vortex-avatar-proxy',
    configureServer(server) {
      server.middlewares.use('/avatar', (req, res) => {
        handle(req, res);
      });
    },
    configurePreviewServer(server) {
      server.middlewares.use('/avatar', (req, res) => {
        handle(req, res);
      });
    },
  };
}

export default defineConfig({
  plugins: [avatarProxy()],
  server: { port: 5173, host: true },
  build: { target: 'es2022', chunkSizeWarningLimit: 2000 },
  test: { environment: 'node', include: ['tests/**/*.test.ts'] },
} as any);
