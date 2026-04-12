import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { componentTagger } from "lovable-tagger";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "");
  // Khớp `PORT` trong apps/api (.env.example dùng 3001; Nest mặc định 3000 nếu không set PORT).
  const apiTarget = env.VITE_API_PROXY_TARGET || "http://127.0.0.1:3001";

  return {
    server: {
      host: "::",
      port: 8080,
      /** Không tự nhảy sang 8081… — tránh bookmark/proxy lệch sau restart. */
      strictPort: true,
      hmr: {
        overlay: false,
      },
      proxy: {
        "/api": {
          target: apiTarget,
          changeOrigin: true,
          rewrite: (p) => p.replace(/^\/api/, ""),
        },
      },
    },
    plugins: [react(), mode === "development" && componentTagger()].filter(Boolean),
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "./src"),
      },
      dedupe: ["react", "react-dom", "react/jsx-runtime", "react/jsx-dev-runtime", "@tanstack/react-query", "@tanstack/query-core"],
    },
  };
});
