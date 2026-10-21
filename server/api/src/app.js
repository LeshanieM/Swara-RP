const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const env = require('./config/env');
const { errorHandler, notFound } = require('./middleware/errorHandler');
const modules = require('./modules');
const { authenticate } = require('./auth/middleware');

const app = express();
app.disable('x-powered-by');
app.use(cors({ origin: env.corsOrigins.includes('*') ? true : env.corsOrigins }));
app.use(express.json({ limit: '100kb' }));
app.use(morgan('dev'));

app.use('/api/health', require('./routes/health'));
app.use('/api/auth', require('./auth/routes'));
app.use('/api/children', authenticate, require('./routes/children'));
// Every component route needs a session (unless AUTH_REQUIRED=0); a child account is limited to its own childId.
for (const m of modules) app.use(`/api/${m.name}`, authenticate, m.router);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
