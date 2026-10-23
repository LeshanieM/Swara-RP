const express = require('express');
const validate = require('../../../middleware/validate');
const { tasksQuery } = require('../validation/schemas');
const taskService = require('../services/taskService');

const router = express.Router();

// GET /api/c1/tasks?age=8[&language=si] -> the task, passages and pictures for the child's age band.
router.get('/', validate(tasksQuery, 'query'), (req, res) => {
  const { age, language } = req.valid.query;
  res.json(taskService.tasksForAge(age, language));
});

module.exports = router;
