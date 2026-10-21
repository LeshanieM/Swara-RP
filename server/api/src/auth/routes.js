// /api/auth: one login per child (set up by a parent) plus a parent-mode PIN, and therapist logins.
const crypto = require('crypto');
const express = require('express');
const { z } = require('zod');
const env = require('../config/env');
const ApiError = require('../lib/ApiError');
const validate = require('../middleware/validate');
const run = require('../lib/run');
const Account = require('./Account');
const secrets = require('./secrets');
const { authenticate } = require('./middleware');

const router = express.Router();

const email = z.string().trim().toLowerCase().email().max(200);
const password = z.string().min(6).max(200);
const age = z.coerce.number().int().min(5).max(14);
const pin = z.string().regex(/^\d{4,6}$/, 'The PIN must be 4–6 digits.');

const register = z.discriminatedUnion('role', [
  z.object({
    role: z.literal('child'),
    name: z.string().trim().min(1).max(100),
    email,
    password,
    child: z.object({ firstName: z.string().trim().min(1).max(60), age }).strict(),
    parentPin: pin,
  }).strict(),
  z.object({
    role: z.literal('therapist'),
    name: z.string().trim().min(1).max(100),
    email,
    password,
    signupCode: z.string().min(1).max(200),
  }).strict(),
]);

const login = z.object({ email, password: z.string().min(1).max(200) }).strict();
const childUpdate = z.object({ firstName: z.string().trim().min(1).max(60).optional(), age: age.optional() }).strict();
const parentMode = z.object({ pin }).strict();

const sameSecret = (a, b) => {
  const x = Buffer.from(String(a));
  const y = Buffer.from(String(b));
  return x.length === y.length && crypto.timingSafeEqual(x, y);
};

// CH- plus 6 characters without look-alikes (0/O, 1/I).
const newChildId = () => {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return `CH-${Array.from(crypto.randomBytes(6), (b) => alphabet[b % alphabet.length]).join('')}`;
};

const session = (account) => ({ token: secrets.signSession(account), user: account.toJSON() });

async function current(req) {
  const account = req.auth && await Account.findById(req.auth.sub);
  if (!account) throw new ApiError(401, 'unauthorized', 'This account no longer exists; sign in again.');
  return account;
}

router.post('/register', validate(register), run(async (req, res) => {
  const body = req.valid.body;
  if (await Account.exists({ email: body.email })) {
    throw new ApiError(409, 'email_taken', 'An account with this email already exists.');
  }
  const account = new Account({ email: body.email, role: body.role, name: body.name });
  account.passwordHash = await secrets.hash(body.password);
  if (body.role === 'therapist') {
    if (!env.therapistSignupCode) throw new ApiError(403, 'therapist_signup_disabled', 'Therapist sign-up is not enabled on this server.');
    if (!sameSecret(body.signupCode, env.therapistSignupCode)) throw new ApiError(403, 'invalid_signup_code', 'The therapist code is not correct.');
  } else {
    account.child = { childId: newChildId(), firstName: body.child.firstName, age: body.child.age };
    account.parentPinHash = await secrets.hash(body.parentPin);
  }
  try {
    await account.save();
  } catch (err) {
    if (err.code === 11000) throw new ApiError(409, 'email_taken', 'An account with this email already exists.');
    throw err;
  }
  res.status(201).json(session(account));
}));

router.post('/login', validate(login), run(async (req, res) => {
  const { email: address, password: secret } = req.valid.body;
  const account = await Account.findOne({ email: address });
  if (!account || !(await secrets.verify(secret, account.passwordHash))) {
    throw new ApiError(401, 'invalid_credentials', 'The email or password is not correct.');
  }
  res.json(session(account));
}));

// These are about the signed-in account, so they need a session even when AUTH_REQUIRED=0.
const signedIn = [authenticate, (req, _res, next) => next(req.auth ? undefined : new ApiError(401, 'unauthorized', 'Sign in first.'))];

router.get('/me', signedIn, run(async (req, res) => {
  res.json({ user: (await current(req)).toJSON() });
}));

router.patch('/me/child', signedIn, validate(childUpdate), run(async (req, res) => {
  const account = await current(req);
  if (account.role !== 'child') throw new ApiError(403, 'role_not_allowed', 'Only child accounts have a child profile.');
  Object.assign(account.child, req.valid.body);
  await account.save();
  res.json({ user: account.toJSON() });
}));

router.post('/parent-mode', signedIn, validate(parentMode), run(async (req, res) => {
  const account = await current(req);
  if (account.role !== 'child') throw new ApiError(403, 'role_not_allowed', 'Parent mode belongs to child accounts.');
  if (!(await secrets.verify(req.valid.body.pin, account.parentPinHash))) {
    throw new ApiError(403, 'invalid_pin', 'The PIN is not correct.');
  }
  res.json({ parentToken: secrets.signParent(account), expiresInSec: env.parentModeMinutes * 60 });
}));

module.exports = router;
