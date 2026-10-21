const mongoose = require('mongoose');

async function connect(uri) {
  await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });
  return mongoose.connection;
}

const STATES = ['disconnected', 'connected', 'connecting', 'disconnecting'];
const state = () => STATES[mongoose.connection.readyState] || 'unknown';

module.exports = { connect, state, disconnect: () => mongoose.disconnect() };
