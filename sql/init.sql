CREATE DATABASE steam_dw;

DROP TABLE IF EXISTS steam_games;

CREATE TABLE steam_games (
    app_id                       BIGINT PRIMARY KEY,       -- Unique Steam application ID.
    name                        TEXT NOT NULL,            -- Game title.
    release_date                TEXT,                     -- Release date (e.g., "Jun 23, 2022").
    estimated_owners            TEXT,                     -- Estimated number of owners (e.g., "0 - 20000").
    peak_ccu                    INTEGER,                  -- Peak concurrent users.
    required_age                INTEGER,                  -- Minimum age required to play.
    price                       NUMERIC(10, 2),          -- Price in USD.
    discount                    INTEGER,                  -- Discount percentage.
    dlc_count                   INTEGER,                  -- Number of downloadable content packs.
    about_the_game              TEXT,                     -- Full description of the game.
    supported_languages         TEXT,                     -- List of supported languages (string representation).
    full_audio_languages        TEXT,                     -- Languages with full audio support.
    reviews                     TEXT,                     -- Review summary text.
    header_image                TEXT,                     -- URL to the header image.
    website                     TEXT,                     -- Official website URL.
    support_url                 TEXT,                     -- Support page URL.
    support_email               TEXT,                     -- Support email address.
    windows                     BOOLEAN,                  -- Whether the game supports Windows.
    mac                         BOOLEAN,                  -- Whether the game supports macOS.
    linux                       BOOLEAN,                  -- Whether the game supports Linux.
    metacritic_score            INTEGER,                  -- Metacritic score (if available).
    metacritic_url              TEXT,                     -- Metacritic page URL.
    user_score                  INTEGER,                  -- User score (e.g., from Metacritic).
    positive                    INTEGER,                  -- Number of positive reviews.
    negative                    INTEGER,                  -- Number of negative reviews.
    score_rank                  INTEGER,                  -- Score rank.
    achievements                INTEGER,                  -- Number of achievements.
    recommendations             INTEGER,                  -- Number of recommendations.
    notes                       TEXT,                     -- Content notes (e.g., mature content warnings).
    average_playtime_forever    INTEGER,                  -- Average playtime in minutes (all time).
    average_playtime_two_weeks  INTEGER,                  -- Average playtime in minutes (last two weeks).
    median_playtime_forever     INTEGER,                  -- Median playtime in minutes (all time).
    median_playtime_two_weeks   INTEGER,                  -- Median playtime in minutes (last two weeks).
    developers                  TEXT,                     -- Developer(s) of the game.
    publishers                  TEXT,                     -- Publisher(s) of the game.
    categories                  TEXT,                     -- List of categories (e.g., Single-player, Family Sharing).
    genres                      TEXT,                     -- List of genres.
    tags                        TEXT,                     -- List of user-defined tags.
    screenshots                 TEXT,                     -- URLs of screenshots.
    movies                      TEXT                     -- URLs of movies/trailers.
);
