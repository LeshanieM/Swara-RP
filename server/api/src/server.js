const env = require('./config/env');
const mongo = require('./db/mongo');
const app = require('./app');
const modules = require('./modules');

async function main() {
  try {
    await mongo.connect(env.mongoUri);
  } catch (err) {
    console.error(`[api] cannot reach MongoDB at ${env.mongoUri}: ${err.message}`);
    console.error('[api] start it with "docker compose up -d" in Swara-RP/server/ and retry.');
    process.exit(1);
  }

  for (const m of modules) {
    const recovered = await m.recover();
    if (recovered.requeued || recovered.failed || recovered.cleaned) console.log(`[api] ${m.name}: recovered unfinished jobs:`, recovered);
  }

  const server = app.listen(env.port, () => {
    console.log(`[api] listening on :${env.port}; components ${modules.map((m) => m.name).join(', ')}; speech service ${env.speechServiceUrl}; uploads ${env.uploadDir}`);
  });

  const shutdown = (signal) => {
    console.log(`[api] ${signal}: shutting down (unfinished jobs resume on next start)`);
    server.close(() => mongo.disconnect().finally(() => process.exit(0)));
    setTimeout(() => process.exit(0), 5000).unref();
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

main();
