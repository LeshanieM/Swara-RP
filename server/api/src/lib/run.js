/** Wrap an async route handler so rejected promises reach the error handler. */
const run = (fn) => async (req, res, next) => {
  try {
    await fn(req, res);
  } catch (err) {
    next(err);
  }
};

module.exports = run;
