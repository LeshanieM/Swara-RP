// One entry per component. Each module exports { name, title, router, health(), recover() } and is mounted at /api/<name>.
module.exports = [
  require('./c1'),
  require('./c2'),
  require('./c3'),
  require('./c4'),
];
