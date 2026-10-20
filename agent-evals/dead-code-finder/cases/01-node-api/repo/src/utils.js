const dayjs = require('dayjs');

function formatDate(date) {
  return dayjs(date).format('YYYY-MM-DD');
}

function parseLegacyDate(value) {
  const [month, day, year] = value.split('/');
  return dayjs(`${year}-${month}-${day}`).toDate();
}

// function formatDateTime(date) {
//   const d = dayjs(date);
//   const time = d.format('HH:mm');
//   return `${d.format('YYYY-MM-DD')} ${time}`;
// }

module.exports = { formatDate, parseLegacyDate };
