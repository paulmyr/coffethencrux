const fs = require("fs");
const path = require("path");
const matter = require("gray-matter");
const MarkdownIt = require("markdown-it");

const md = new MarkdownIt({ html: true, linkify: true });
const ENTRIES_DIR = path.join(__dirname, "..", "_src", "almanach");
const TMDB_BASE = "https://image.tmdb.org/t/p/w300";

async function fetchTmdbPoster(tmdbId, type) {
  const apiKey = process.env.TMDB_API_KEY;
  if (!apiKey || !tmdbId) return null;

  const mediaType = type === "tv" ? "tv" : "movie";
  const url = `https://api.themoviedb.org/3/${mediaType}/${tmdbId}?api_key=${apiKey}`;

  try {
    const res = await fetch(url);
    if (!res.ok) return null;
    const data = await res.json();
    return data.poster_path ? `${TMDB_BASE}${data.poster_path}` : null;
  } catch {
    return null;
  }
}

function readEntries() {
  if (!fs.existsSync(ENTRIES_DIR)) return [];

  const entries = fs
    .readdirSync(ENTRIES_DIR)
    .filter((f) => f.endsWith(".md"))
    .map((f) => {
      const raw = fs.readFileSync(path.join(ENTRIES_DIR, f), "utf-8");
      const { data, content } = matter(raw);
      // gray-matter parses YAML dates into Date objects — format back to string
      if (data.date instanceof Date) {
        data.date = data.date.toISOString().slice(0, 10);
      }
      return { ...data, review: md.render(content.trim()) };
    });

  // Sort by date, latest first (entries without a date go last)
  entries.sort((a, b) => {
    if (!a.date && !b.date) return 0;
    if (!a.date) return 1;
    if (!b.date) return -1;
    return new Date(b.date) - new Date(a.date);
  });

  return entries;
}

module.exports = async function () {
  const entries = readEntries();

  const items = await Promise.all(
    entries.map(async (item) => {
      if (item.cover) return item;

      if (item.type === "book" && item.isbn) {
        item.cover = `https://covers.openlibrary.org/b/isbn/${item.isbn}-L.jpg`;
      } else if ((item.type === "movie" || item.type === "tv") && item.tmdbId) {
        const poster = await fetchTmdbPoster(item.tmdbId, item.type);
        if (poster) item.cover = poster;
      }

      return item;
    })
  );

  return {
    books: items.filter((i) => i.type === "book"),
    movies: items.filter((i) => i.type === "movie"),
    tv: items.filter((i) => i.type === "tv"),
  };
};
