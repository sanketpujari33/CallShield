import express from "express";
import cors from "cors";
import helmet from "helmet";
import { config } from "./config.js";
import { reportsRouter } from "./routes/reportsRouter.js";
import { dataRouter } from "./routes/dataRouter.js";
import { lookupRouter } from "./routes/lookupRouter.js";
import { adminRouter } from "./routes/adminRouter.js";

export const app = express();

// Security and middleware
app.use(
  helmet({
    contentSecurityPolicy: false, // allow inline html for API info page
  })
);
app.use(cors());
app.use(express.json({ limit: "100kb" }));

// Landing Page
app.get("/", (req, res) => {
  res.type("html").send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CallShield API Server</title>
  <style>
    body { background: #0d1117; color: #c9d1d9; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 20px; }
    .card { background: #161b22; border: 1px solid #30363d; border-radius: 16px; padding: 36px; max-width: 540px; width: 100%; box-shadow: 0 16px 32px rgba(0,0,0,0.5); }
    h1 { color: #58a6ff; font-size: 26px; margin: 0 0 8px 0; display: flex; align-items: center; gap: 10px; }
    .tag { background: #238636; color: #ffffff; font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 20px; text-transform: uppercase; }
    p { color: #8b949e; line-height: 1.6; margin: 16px 0; font-size: 14px; }
    .endpoints { background: #0d1117; border: 1px solid #30363d; border-radius: 8px; padding: 14px; margin: 20px 0; font-family: monospace; font-size: 13px; }
    .endpoints div { margin: 6px 0; }
    .method { color: #7ee787; font-weight: bold; }
    .post { color: #ffa657; }
    a { color: #58a6ff; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="card">
    <h1>🛡️ CallShield <span class="tag">Active</span></h1>
    <p>CallShield Node.js API Server powering community spam reporting, sharded database sync, and real-time caller ID enrichment.</p>
    <div class="endpoints">
      <div><span class="method post">POST</span> /api/reports - Submit spam report</div>
      <div><span class="method">GET</span> /api/data/manifest - Database manifest</div>
      <div><span class="method">GET</span> /api/data/shards/:key - 256 content shards</div>
      <div><span class="method">GET</span> /api/data/hot_numbers - Hot list numbers</div>
      <div><span class="method">GET</span> /api/lookup/:number - Multi-source Caller ID</div>
      <div><span class="method">GET</span> /api/health - Service health & status</div>
    </div>
    <p style="font-size: 12px; color: #484f58;">No user tracking or private data stored. E.164 normalized.</p>
  </div>
</body>
</html>`);
});

// Mount API routes
app.use("/api/reports", reportsRouter);
app.use("/report", reportsRouter); // backwards compatibility
app.use("/api/data", dataRouter);
app.use("/api/lookup", lookupRouter);
app.use("/api", adminRouter);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: "Endpoint not found" });
});

// Error Handler
app.use((err, req, res, next) => {
  console.error("Unhandled server error:", err);
  res.status(500).json({ error: "Internal server error" });
});

// Only listen if executed directly
if (process.argv[1] && process.argv[1].endsWith("server.js") && process.env.NODE_ENV !== "test") {
  app.listen(config.port, config.host, () => {
    console.log(`🛡️ CallShield Server listening at http://${config.host}:${config.port}`);
  });
}
