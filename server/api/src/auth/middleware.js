const env = require('../config/env');
const ApiError = require('../lib/ApiError');
const { decode } = require('./secrets');

const unauthorized = (message) => new ApiError(401, 'unauthorized', message);
const forbidden = (code, message) => new ApiError(403, code, message);

/**
 * Require a session token and put its claims on req.auth ({ sub, role, childId }).
 * With AUTH_REQUIRED=0 a request without a token passes with req.auth = null (research scripts, curl);
 * a token that is sent is still checked and still scopes the request.
 */
function authenticate(req, _res, next) {
  const [scheme, token] = (req.get('authorization') || '').split(' ');
  if (scheme !== 'Bearer' || !token) {
    if (env.authRequired) return next(unauthorized('Sign in first.'));
    req.auth = null;
    return next();
  }
  try {
    req.auth = decode(token, 'session');
    return next();
  } catch {
    return next(unauthorized('The session has expired or is invalid; sign in again.'));
  }
}

/** A child account may act only for its own child; therapists (and auth-off) may act for any. */
function assertChild(req, childId) {
  if (!req.auth || req.auth.role !== 'child' || childId === undefined) return;
  if (childId !== req.auth.childId) throw forbidden('other_child', 'This account can only act for its own child.');
}

function requireRole(...roles) {
  return (req, _res, next) => {
    if (req.auth && !roles.includes(req.auth.role)) return next(forbidden('role_not_allowed', `Only ${roles.join(' / ')} accounts can do this.`));
    return next();
  };
}

/**
 * Parent-mode actions need X-Parent-Token from POST /api/auth/parent-mode, for the same child.
 * Therapists act as the SLP and don't need one. `when(req)` limits the check to some requests.
 */
function requireParentMode(when = () => true) {
  return (req, _res, next) => {
    if (!req.auth || req.auth.role !== 'child' || !when(req)) return next();
    const token = req.get('x-parent-token');
    if (!token) return next(forbidden('parent_mode_required', 'A parent must enter the parent-mode PIN first.'));
    try {
      const claims = decode(token, 'parent');
      if (claims.sub !== req.auth.sub) throw new Error('other account');
      return next();
    } catch {
      return next(forbidden('parent_mode_required', 'Parent mode has expired; enter the PIN again.'));
    }
  };
}

module.exports = { authenticate, assertChild, requireRole, requireParentMode };
