#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIR="$SCRIPT_DIR/_src/almanach"

# Load .env if present
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  . "$SCRIPT_DIR/.env"
  set +a
fi
mkdir -p "$DIR"

# --- helpers ---
ask() {
  local prompt="$1" var="$2" default="${3:-}"
  if [ -n "$default" ]; then
    printf "%s [%s]: " "$prompt" "$default" >&2
  else
    printf "%s: " "$prompt" >&2
  fi
  read -r val
  val="${val:-$default}"
  eval "$var=\$val"
}

ask_required() {
  local prompt="$1" var="$2" default="${3:-}"
  if [ -n "$default" ]; then
    printf "%s [%s]: " "$prompt" "$default" >&2
    read -r val
    val="${val:-$default}"
    eval "$var=\$val"
  else
    while true; do
      printf "%s: " "$prompt" >&2
      read -r val
      if [ -n "$val" ]; then
        eval "$var=\$val"
        return
      fi
      echo "  (required)" >&2
    done
  fi
}

# extract a JSON field — usage: json_field "$json" "key"
json_field() {
  python3 -c "
import json, sys
data = json.loads(sys.argv[1])
keys = sys.argv[2].split('.')
v = data
for k in keys:
    if isinstance(v, list):
        v = v[int(k)] if len(v) > int(k) else None
    elif isinstance(v, dict):
        v = v.get(k)
    else:
        v = None
    if v is None:
        break
print(v if v is not None else '')
" "$1" "$2" 2>/dev/null || echo ""
}

# --- type ---
echo ""
echo "=== New Almanach Entry ==="
echo ""
echo "  1) book"
echo "  2) movie"
echo "  3) tv"
echo ""
while true; do
  printf "Type [1/2/3]: " >&2
  read -r type_choice
  case "$type_choice" in
    1|book)   TYPE="book";  break ;;
    2|movie)  TYPE="movie"; break ;;
    3|tv)     TYPE="tv";    break ;;
    *) echo "  Pick 1, 2, or 3" >&2 ;;
  esac
done

# --- lookup by ID ---
DEF_TITLE="" DEF_CREATOR="" DEF_YEAR="" DEF_TAGS=""
ISBN="" TMDB=""
echo ""

if [ "$TYPE" = "book" ]; then
  ask "ISBN (13-digit)" ISBN
  if [ -n "$ISBN" ]; then
    echo "  Looking up ISBN $ISBN..." >&2
    OL_JSON="$(curl -sf "https://openlibrary.org/api/books?bibkeys=ISBN:${ISBN}&format=json&jscmd=data" || echo "")"
    if [ -n "$OL_JSON" ] && [ "$OL_JSON" != "{}" ]; then
      BOOK_JSON="$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
key = list(data.keys())[0] if data else ''
print(json.dumps(data[key]) if key else '{}')
" "$OL_JSON" 2>/dev/null || echo "{}")"
      DEF_TITLE="$(json_field "$BOOK_JSON" "title")"
      DEF_CREATOR="$(json_field "$BOOK_JSON" "authors.0.name")"
      DEF_YEAR="$(json_field "$BOOK_JSON" "publish_date" | grep -oE '[0-9]{4}' | head -1 || echo "")"
      DEF_TAGS="$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
subjects = data.get('subjects', [])
names = [s['name'].lower() for s in subjects[:3]]
print(', '.join(names))
" "$BOOK_JSON" 2>/dev/null || echo "")"
      if [ -n "$DEF_TITLE" ]; then
        echo "  Found: $DEF_TITLE" >&2
      fi
    else
      echo "  No results found." >&2
    fi
  fi
else
  ask "TMDB ID" TMDB
  if [ -n "$TMDB" ]; then
    TMDB_KEY="${TMDB_API_KEY:-}"
    if [ -n "$TMDB_KEY" ]; then
      MEDIA="$( [ "$TYPE" = "tv" ] && echo "tv" || echo "movie" )"
      echo "  Looking up TMDB $MEDIA/$TMDB..." >&2
      TMDB_JSON="$(curl -sf "https://api.themoviedb.org/3/${MEDIA}/${TMDB}?api_key=${TMDB_KEY}&append_to_response=credits" || echo "")"
      if [ -n "$TMDB_JSON" ]; then
        if [ "$TYPE" = "tv" ]; then
          DEF_TITLE="$(json_field "$TMDB_JSON" "name")"
          DEF_YEAR="$(json_field "$TMDB_JSON" "first_air_date" | cut -c1-4)"
          DEF_CREATOR="$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
creators = data.get('created_by', [])
print(', '.join(c['name'] for c in creators[:2]))
" "$TMDB_JSON" 2>/dev/null || echo "")"
        else
          DEF_TITLE="$(json_field "$TMDB_JSON" "title")"
          DEF_YEAR="$(json_field "$TMDB_JSON" "release_date" | cut -c1-4)"
          DEF_CREATOR="$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
crew = data.get('credits', {}).get('crew', [])
dirs = [c['name'] for c in crew if c.get('job') == 'Director']
print(', '.join(dirs[:2]))
" "$TMDB_JSON" 2>/dev/null || echo "")"
        fi
        DEF_TAGS="$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
genres = data.get('genres', [])
print(', '.join(g['name'].lower() for g in genres[:3]))
" "$TMDB_JSON" 2>/dev/null || echo "")"
        if [ -n "$DEF_TITLE" ]; then
          echo "  Found: $DEF_TITLE" >&2
        fi
      else
        echo "  No results found." >&2
      fi
    else
      echo "  TMDB_API_KEY not set — skipping lookup." >&2
    fi
  fi
fi

# --- fill in details (with defaults from lookup) ---
echo ""
ask_required "Title" TITLE "$DEF_TITLE"

case "$TYPE" in
  book)  ask_required "Author" CREATOR "$DEF_CREATOR" ;;
  movie) ask_required "Director" CREATOR "$DEF_CREATOR" ;;
  tv)    ask_required "Creator" CREATOR "$DEF_CREATOR" ;;
esac

YEAR=""
if [ "$TYPE" != "book" ]; then
  ask "Release year" YEAR "$DEF_YEAR"
fi

# --- date ---
TODAY="$(date +%Y-%m-%d)"
case "$TYPE" in
  book)  ask "Date finished" DATE "$TODAY" ;;
  *)     ask "Date watched" DATE "$TODAY" ;;
esac

# --- rating ---
while true; do
  printf "Rating [1-5]: " >&2
  read -r RATING
  case "$RATING" in
    1|2|3|4|5) break ;;
    *) echo "  Enter a number from 1 to 5" >&2 ;;
  esac
done

# --- tags ---
ask "Tags (comma-separated)" TAGS "$DEF_TAGS"
echo ""

# --- review ---
echo "Review (end with an empty line):" >&2
REVIEW=""
while IFS= read -r line; do
  [ -z "$line" ] && break
  if [ -n "$REVIEW" ]; then
    REVIEW="$REVIEW
$line"
  else
    REVIEW="$line"
  fi
done

# --- build filename ---
SLUG="$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')"
FILE="$DIR/$SLUG.md"

if [ -f "$FILE" ]; then
  printf "\n%s already exists. Overwrite? [y/N]: " "$FILE" >&2
  read -r confirm
  case "$confirm" in
    y|Y) ;;
    *) echo "Aborted." >&2; exit 1 ;;
  esac
fi

# --- write frontmatter ---
{
  echo "---"
  echo "type: $TYPE"
  echo "title: \"$TITLE\""
  echo "creator: \"$CREATOR\""

  [ -n "$ISBN" ] && echo "isbn: \"$ISBN\""
  [ -n "$YEAR" ] && echo "year: $YEAR"
  [ -n "$TMDB" ] && echo "tmdbId: $TMDB"

  echo "date: $DATE"
  echo "rating: $RATING"

  if [ -n "$TAGS" ]; then
    echo "tags:"
    IFS=',' read -ra tag_arr <<< "$TAGS"
    for t in "${tag_arr[@]}"; do
      trimmed="$(echo "$t" | sed 's/^ *//;s/ *$//')"
      echo "  - $trimmed"
    done
  fi

  echo "---"
  echo ""
  echo "$REVIEW"
} > "$FILE"

echo ""
echo "Created: $FILE"
