const { assertChild } = require('../auth/middleware');

/**
 * Parse req[source] with a zod schema and replace it with the parsed value.
 * A parsed childId is also checked against the signed-in child account here, because
 * this runs after multer, so multipart bodies are covered too.
 */
const validate = (schema, source = 'body') => (req, _res, next) => {
  const parsed = schema.safeParse(req[source] ?? {});
  if (!parsed.success) return next(parsed.error);
  try {
    assertChild(req, parsed.data?.childId);
  } catch (err) {
    return next(err);
  }
  req.valid = { ...(req.valid || {}), [source]: parsed.data };
  return next();
};

module.exports = validate;
