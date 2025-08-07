import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [react()],
    resolve: {
        preserveSymlinks: true
    },
    build: {
        outDir: "../backend/static",
        emptyOutDir: true,
        sourcemap: true,
        rollupOptions: {
            output: {
                manualChunks: id => {
                    if (id.includes("@fluentui/react-icons")) {
                        return "fluentui-icons";
                    } else if (id.includes("@fluentui/react")) {
                        return "fluentui-react";
                    } else if (id.includes("node_modules")) {
                        return "vendor";
                    }
                }
            }
        },
        target: "esnext"
    },
    server: {
        proxy: {
            "/content/": "http://localhost:3001",
            "/auth_setup": "http://localhost:3001",
            "/.auth/me": "http://localhost:3001",
            "/ask": "http://localhost:3001",
            "/chat": "http://localhost:3001",
            "/speech": "http://localhost:3001",
            "/config": "http://localhost:3001",
            "/upload": "http://localhost:3001",
            "/delete_uploaded": "http://localhost:3001",
            "/list_uploaded": "http://localhost:3001",
            "/chat_history": "http://localhost:3001"
        }
    }
});
