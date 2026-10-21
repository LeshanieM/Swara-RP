const catalog = require('../data/taskCatalog.json');
const ApiError = require('../../../lib/ApiError');

const MIN_AGE = 5;
const MAX_AGE = 14;

function bandForAge(age) {
  const band = catalog.ageBands.find((b) => age >= b.minAge && age <= b.maxAge);
  if (!band) {
    throw ApiError.unprocessable('age_out_of_range', `C1 supports ages ${MIN_AGE}-${MAX_AGE}; got ${age}.`);
  }
  return band;
}

function tasksForAge(age, language) {
  const band = bandForAge(age);
  const byLanguage = (item) => !language || item.language === language;
  return {
    age,
    ageBand: band.id,
    taskType: band.taskType,
    passages: band.taskType === 'reading'
      ? catalog.passages.filter((p) => p.ageBand === band.id).filter(byLanguage) : [],
    pictures: band.taskType === 'picture_description'
      ? catalog.pictures.filter((p) => p.ageBand === band.id) : [],
  };
}

function findPassage(id) {
  return catalog.passages.find((p) => p.id === id);
}

function findPicture(id) {
  return catalog.pictures.find((p) => p.id === id);
}

module.exports = { bandForAge, tasksForAge, findPassage, findPicture, MIN_AGE, MAX_AGE };
