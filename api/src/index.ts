import cors from "cors";
import express from "express";
import { checkDbConnection } from "./db/pool";
import authRoutes from "./routes/auth";
import credentialsRoutes from "./routes/credentials";
import leaveRoutes from "./routes/leave";
import profileRoutes from "./routes/profile";
import requestsRoutes from "./routes/requests";
import rosterRoutes from "./routes/roster";
import shiftsRoutes from "./routes/shifts";

const app = express();
const port = Number(process.env.PORT ?? 3001);
const version = process.env.APP_VERSION ?? "0.1.0";

const corsOrigin = process.env.CORS_ORIGIN?.split(",").map((o) => o.trim()) ?? [
  "http://localhost:3000",
];

app.use(
  cors({
    origin: corsOrigin,
    credentials: true,
  }),
);
app.use(express.json());

app.get("/api/health", async (_req, res) => {
  const dbOk = await checkDbConnection();
  res.status(dbOk ? 200 : 503).json({
    status: dbOk ? "ok" : "degraded",
    version,
    db: dbOk ? "connected" : "unavailable",
    timestamp: new Date().toISOString(),
  });
});

app.use("/api/auth", authRoutes);
app.use("/api/profile", profileRoutes);
app.use("/api/credentials", credentialsRoutes);
app.use("/api/shifts", shiftsRoutes);
app.use("/api/roster", rosterRoutes);
app.use("/api/leave", leaveRoutes);
app.use("/api/requests", requestsRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: "Not found" });
});

app.listen(port, () => {
  console.log(`AbilityERP API listening on port ${port} (v${version})`);
});

export default app;
