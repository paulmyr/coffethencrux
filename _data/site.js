module.exports = function () {
  return {
    buildDate: new Date().toISOString().split("T")[0],
  };
};
