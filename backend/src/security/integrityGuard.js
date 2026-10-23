const fs = require('fs');
const path = require('path');

const backendRoot = path.resolve(__dirname, '../..');

function assertBackendIntegrity() {
  const forbiddenEntry = path.join(backendRoot, 'api.js');
  if (fs.existsSync(forbiddenEntry)) {
    throw new Error('Blocked backend startup: unexpected backend/api.js file.');
  }

  const packageJson = JSON.parse(
    fs.readFileSync(path.join(backendRoot, 'package.json'), 'utf8'),
  );
  for (const [name, command] of Object.entries(packageJson.scripts || {})) {
    if (/\bapi\.js\b/i.test(command)) {
      throw new Error(`Blocked backend startup: npm script "${name}" references api.js.`);
    }
  }

  const authPath = path.join(backendRoot, 'src', 'routes', 'auth.js');
  const authSource = fs.readFileSync(authPath, 'utf8');
  const authLines = authSource.split(/\r?\n/);
  const suspiciousAuthCode = [
    /\beval\s*\(/i,
    /\bnew\s+Function\s*\(/i,
    /\bglobal\s*\[/i,
    /\\u[0-9a-f]{4}/i,
    /\\x[0-9a-f]{2}/i,
  ];

  if (!/module\.exports\s*=\s*router;\s*$/.test(authSource)) {
    throw new Error('Blocked backend startup: auth.js has code after its router export.');
  }
  if (
    authLines.some((line) => line.length > 1000) ||
    suspiciousAuthCode.some((pattern) => pattern.test(authSource))
  ) {
    throw new Error('Blocked backend startup: suspicious code found in auth.js.');
  }

  const serverSource = fs.readFileSync(
    path.join(backendRoot, 'src', 'server.js'),
    'utf8',
  );
  if (!serverSource.includes("require('./security/integrityGuard').assertBackendIntegrity();")) {
    throw new Error('Backend integrity guard must run before server routes are loaded.');
  }
}

module.exports = { assertBackendIntegrity };

if (require.main === module) {
  try {
    assertBackendIntegrity();
    process.stdout.write('Backend integrity check passed.\n');
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  }
}
