const fs = require("fs");
const path = require("path");

const galleryDir = path.join(__dirname, "..", "assets", "gallery");
const extensions = [".jpg", ".jpeg", ".png", ".gif", ".webp", ".avif", ".svg"];

module.exports = function () {
  if (!fs.existsSync(galleryDir)) return [];

  return fs
    .readdirSync(galleryDir)
    .filter((file) => extensions.includes(path.extname(file).toLowerCase()))
    .sort()
    .map((file) => ({
      src: `/assets/gallery/${file}`,
      alt: path.basename(file, path.extname(file)).replace(/[-_]/g, " "),
    }));
};
