-- =============================================================================
-- LinkittyDoRanch — MySQL schema (v1 DRAFT)
-- Target: MySQL 8.x, InnoDB, utf8mb4.  Engine for api.linkittydo.com (EF6).
-- This is a PLANNING draft that lives under plan/schema. The authoritative copy
-- will live in the API repo's db/ folder and be applied by the deploy/verify
-- scripts. Derived from the four original SQL Server ER diagrams; NO data is
-- migrated. See plan/02-data-model.md for column notes and deviations.
--
-- Conventions: every table carries create_dt, update_dt, sysversion (optimistic
-- concurrency token, EF6-mapped). IDs are INT AUTO_INCREMENT except LK_USERS.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS linkittydo
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE linkittydo;

SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- Group 1 — Users, Societies & Roles
-- -----------------------------------------------------------------------------

CREATE TABLE LK_USERS (
  user_id              VARCHAR(50)   NOT NULL,
  unickname            VARCHAR(100)  NULL,
  uemail               VARCHAR(255)  NOT NULL,
  upassword_hash       VARCHAR(255)  NULL,        -- was: upassword varchar(100) CLEARTEXT
  upassword_salt       VARCHAR(100)  NULL,
  uthumbnail_url       VARCHAR(512)  NULL,        -- was: uthumbnail varbinary(max)
  ustatus              VARCHAR(20)   NOT NULL DEFAULT 'pending', -- pending|active|disabled
  udefault_profile_id  INT           NULL,        -- default game-play profile set
  create_dt            DATETIME      NULL,
  update_dt            DATETIME      NULL,
  sysversion           VARCHAR(10)   NULL,
  CONSTRAINT PK_LK_USERS PRIMARY KEY (user_id),
  CONSTRAINT UQ_LK_USERS_email UNIQUE (uemail)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_USER_PROPS (
  user_id        VARCHAR(50)  NOT NULL,
  upname         VARCHAR(100) NOT NULL,
  upvalue        VARCHAR(255) NULL,               -- added: the property value
  updescription  VARCHAR(255) NULL,
  create_dt      DATETIME     NULL,
  update_dt      DATETIME     NULL,
  sysversion     VARCHAR(10)  NULL,
  CONSTRAINT PK_LK_USER_PROPS PRIMARY KEY (user_id, upname),
  CONSTRAINT FK_LK_USER_PROPS_user FOREIGN KEY (user_id) REFERENCES LK_USERS(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_ROLES (
  role_id       INT          NOT NULL AUTO_INCREMENT,
  rname         VARCHAR(50)  NOT NULL,
  rdescription  VARCHAR(255) NULL,
  create_dt     DATETIME     NULL,
  update_dt     DATETIME     NULL,
  sysversion    VARCHAR(10)  NULL,
  CONSTRAINT PK_LK_ROLES PRIMARY KEY (role_id),
  CONSTRAINT UQ_LK_ROLES_name UNIQUE (rname)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_USER_ROLES (
  user_id     VARCHAR(50) NOT NULL,
  role_id     INT         NOT NULL,
  create_dt   DATETIME    NULL,
  update_dt   DATETIME    NULL,
  sysversion  VARCHAR(10) NULL,
  CONSTRAINT PK_LK_USER_ROLES PRIMARY KEY (user_id, role_id),
  CONSTRAINT FK_LK_USER_ROLES_user FOREIGN KEY (user_id) REFERENCES LK_USERS(user_id),
  CONSTRAINT FK_LK_USER_ROLES_role FOREIGN KEY (role_id) REFERENCES LK_ROLES(role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- Group 2 — Games, Phrases, Parses & Profiles
-- -----------------------------------------------------------------------------

CREATE TABLE LK_PHRASES (
  phrase_id          INT          NOT NULL AUTO_INCREMENT,
  pphrase            VARCHAR(255) NOT NULL,
  pdefault_parse_id  INT          NULL,
  create_dt          DATETIME     NULL,
  update_dt          DATETIME     NULL,
  sysversion         VARCHAR(10)  NULL,
  CONSTRAINT PK_LK_PHRASES PRIMARY KEY (phrase_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_PARSES (
  parse_id     INT         NOT NULL AUTO_INCREMENT,
  pascore      FLOAT       NULL,                  -- parser likelihood/score
  prow_count   INT         NULL,
  pword_count  INT         NULL,
  pchar_count  INT         NULL,
  create_dt    DATETIME    NULL,
  update_dt    DATETIME    NULL,
  sysversion   VARCHAR(10) NULL,
  CONSTRAINT PK_LK_PARSES PRIMARY KEY (parse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE LK_PHRASES
  ADD CONSTRAINT FK_LK_PHRASES_defparse FOREIGN KEY (pdefault_parse_id) REFERENCES LK_PARSES(parse_id);

CREATE TABLE LK_PHRASE_PARSES (
  phrase_id     INT         NOT NULL,
  parse_id      INT         NOT NULL,
  parse_source  VARCHAR(50) NULL,                 -- e.g. 'OpenNLP'
  owner_id      VARCHAR(50) NULL,
  create_dt     DATETIME    NULL,
  update_dt     DATETIME    NULL,
  sysversion    VARCHAR(10) NULL,
  CONSTRAINT PK_LK_PHRASE_PARSES PRIMARY KEY (phrase_id, parse_id),
  CONSTRAINT FK_LK_PHRASE_PARSES_phrase FOREIGN KEY (phrase_id) REFERENCES LK_PHRASES(phrase_id),
  CONSTRAINT FK_LK_PHRASE_PARSES_parse  FOREIGN KEY (parse_id)  REFERENCES LK_PARSES(parse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_PARSE_NODES (
  parse_id          INT         NOT NULL,
  pnposition        INT         NOT NULL,         -- tree ordinal (lower-left leaf = 1, upward)
  pnsub_phrase      VARCHAR(255) NULL,
  pnrow             INT         NULL,             -- tree level (row 1 = leaf row)
  pnword_start      INT         NULL,
  pnword_length     INT         NULL,
  pnchar_start      INT         NULL,
  pnchar_length     INT         NULL,
  pnpart_of_speech  VARCHAR(20) NULL,
  create_dt         DATETIME    NULL,
  update_dt         DATETIME    NULL,
  sysversion        VARCHAR(10) NULL,
  CONSTRAINT PK_LK_PARSE_NODES PRIMARY KEY (parse_id, pnposition),
  CONSTRAINT FK_LK_PARSE_NODES_parse FOREIGN KEY (parse_id) REFERENCES LK_PARSES(parse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_PROFILES (
  profile_id   INT          NOT NULL,             -- a profile is the SET of rows sharing profile_id
  property_id  INT          NOT NULL,             -- per-profile property sequence
  prtype       VARCHAR(30)  NULL,                 -- relation|search_style|context_style|display_style|search_engine|grammatical_depth
  prname       VARCHAR(50)  NULL,
  prvalue      VARCHAR(100) NULL,
  create_dt    DATETIME     NULL,
  update_dt    DATETIME     NULL,
  sysversion   VARCHAR(10)  NULL,
  CONSTRAINT PK_LK_PROFILES PRIMARY KEY (profile_id, property_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_GAMES (
  game_id          INT          NOT NULL AUTO_INCREMENT,
  gtitle           VARCHAR(150) NULL,             -- added: title distinct from phrase
  gphrase_id       INT          NOT NULL,
  gprofile_id      INT          NULL,             -- creation profile set (LK_PROFILES.profile_id)
  gcreate_user_id  VARCHAR(50)  NULL,
  glast_played_dt  DATETIME     NULL,
  gplay_count      INT          NOT NULL DEFAULT 0,
  gsolve_count     INT          NOT NULL DEFAULT 0,
  glast_solved_dt  DATETIME     NULL,
  gstatus          VARCHAR(20)  NOT NULL DEFAULT 'new', -- new|processing|processed|approval_ready|live|not_approved|unavailable
  create_dt        DATETIME     NULL,
  update_dt        DATETIME     NULL,
  sysversion       VARCHAR(10)  NULL,
  CONSTRAINT PK_LK_GAMES PRIMARY KEY (game_id),
  CONSTRAINT FK_LK_GAMES_phrase FOREIGN KEY (gphrase_id)      REFERENCES LK_PHRASES(phrase_id),
  CONSTRAINT FK_LK_GAMES_user   FOREIGN KEY (gcreate_user_id) REFERENCES LK_USERS(user_id),
  INDEX IX_LK_GAMES_status (gstatus)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_GAME_TAGS (
  game_id     INT         NOT NULL,
  tag         VARCHAR(50) NOT NULL,
  create_dt   DATETIME    NULL,
  update_dt   DATETIME    NULL,
  sysversion  VARCHAR(10) NULL,
  CONSTRAINT PK_LK_GAME_TAGS PRIMARY KEY (game_id, tag),
  CONSTRAINT FK_LK_GAME_TAGS_game FOREIGN KEY (game_id) REFERENCES LK_GAMES(game_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Deferred FK (added after LK_PROFILES exists): user's default profile set.
ALTER TABLE LK_USERS
  ADD INDEX IX_LK_USERS_defprofile (udefault_profile_id);

-- -----------------------------------------------------------------------------
-- Group 3 — Clues & Links
-- -----------------------------------------------------------------------------

CREATE TABLE LK_LINKS (
  link_id         INT           NOT NULL AUTO_INCREMENT,
  lurl            VARCHAR(2048) NOT NULL,
  ltitle          VARCHAR(255)  NULL,             -- added: page title
  lsearch_engine  VARCHAR(30)   NULL,
  create_dt       DATETIME      NULL,
  update_dt       DATETIME      NULL,
  sysversion      VARCHAR(10)   NULL,
  CONSTRAINT PK_LK_LINKS PRIMARY KEY (link_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_CLUES (
  clue_id     INT          NOT NULL AUTO_INCREMENT,
  game_id     INT          NOT NULL,
  parse_id    INT          NOT NULL,
  pnordinal   INT          NOT NULL,              -- -> LK_PARSE_NODES.pnposition
  profile_id  INT          NULL,
  ccontext    VARCHAR(255) NULL,                  -- encoded grammatical context
  create_dt   DATETIME     NULL,
  update_dt   DATETIME     NULL,
  sysversion  VARCHAR(10)  NULL,
  CONSTRAINT PK_LK_CLUES PRIMARY KEY (clue_id),
  CONSTRAINT FK_LK_CLUES_game  FOREIGN KEY (game_id)  REFERENCES LK_GAMES(game_id),
  CONSTRAINT FK_LK_CLUES_parse FOREIGN KEY (parse_id) REFERENCES LK_PARSES(parse_id),
  INDEX IX_LK_CLUES_game_parse_ord (game_id, parse_id, pnordinal)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_CLUE_LINKS (
  clue_id     INT         NOT NULL,
  link_id     INT         NOT NULL,
  create_dt   DATETIME    NULL,
  update_dt   DATETIME    NULL,
  sysversion  VARCHAR(10) NULL,
  CONSTRAINT PK_LK_CLUE_LINKS PRIMARY KEY (clue_id, link_id),
  CONSTRAINT FK_LK_CLUE_LINKS_clue FOREIGN KEY (clue_id) REFERENCES LK_CLUES(clue_id),
  CONSTRAINT FK_LK_CLUE_LINKS_link FOREIGN KEY (link_id) REFERENCES LK_LINKS(link_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- Group 4 — Played Games, Clues & Guesses
-- -----------------------------------------------------------------------------

CREATE TABLE LK_PLAYED_GAMES (
  played_game_id  INT         NOT NULL AUTO_INCREMENT,
  player_id       VARCHAR(50) NOT NULL,
  game_id         INT         NOT NULL,
  parse_id        INT         NOT NULL,
  pgclue_count    INT         NOT NULL DEFAULT 0,
  pgguess_count   INT         NOT NULL DEFAULT 0,
  pgstart_date    DATETIME    NULL,
  pgsolve_date    DATETIME    NULL,
  pgstatus        VARCHAR(20) NOT NULL DEFAULT 'started', -- started|solved|quit
  pgscore         INT         NOT NULL DEFAULT 0,
  create_dt       DATETIME    NULL,
  update_dt       DATETIME    NULL,
  sysversion      VARCHAR(10) NULL,
  CONSTRAINT PK_LK_PLAYED_GAMES PRIMARY KEY (played_game_id),
  CONSTRAINT FK_LK_PG_player FOREIGN KEY (player_id) REFERENCES LK_USERS(user_id),
  CONSTRAINT FK_LK_PG_game   FOREIGN KEY (game_id)   REFERENCES LK_GAMES(game_id),
  CONSTRAINT FK_LK_PG_parse  FOREIGN KEY (parse_id)  REFERENCES LK_PARSES(parse_id),
  INDEX IX_LK_PG_player (player_id),
  INDEX IX_LK_PG_game (game_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_CLUES_PLAYED (
  played_game_id  INT         NOT NULL,
  clue_id         INT         NOT NULL,
  cpweight        FLOAT       NOT NULL DEFAULT 0,  -- reinforcement weight
  create_dt       DATETIME    NULL,
  update_dt       DATETIME    NULL,
  sysversion      VARCHAR(10) NULL,
  CONSTRAINT PK_LK_CLUES_PLAYED PRIMARY KEY (played_game_id, clue_id),
  CONSTRAINT FK_LK_CP_pg   FOREIGN KEY (played_game_id) REFERENCES LK_PLAYED_GAMES(played_game_id),
  CONSTRAINT FK_LK_CP_clue FOREIGN KEY (clue_id)        REFERENCES LK_CLUES(clue_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_SOLVED_ORDINALS (
  played_game_id  INT         NOT NULL,
  soordinal       INT         NOT NULL,
  create_dt       DATETIME    NULL,
  update_dt       DATETIME    NULL,
  sysversion      VARCHAR(10) NULL,
  CONSTRAINT PK_LK_SOLVED_ORDINALS PRIMARY KEY (played_game_id, soordinal),
  CONSTRAINT FK_LK_SO_pg FOREIGN KEY (played_game_id) REFERENCES LK_PLAYED_GAMES(played_game_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_GUESSES (
  guess_id        INT          NOT NULL AUTO_INCREMENT, -- added surrogate (multiple guesses per ordinal)
  played_game_id  INT          NOT NULL,
  guordinal       INT          NOT NULL,
  guwords         VARCHAR(255) NULL,
  create_dt       DATETIME     NULL,
  update_dt       DATETIME     NULL,
  sysversion      VARCHAR(10)  NULL,
  CONSTRAINT PK_LK_GUESSES PRIMARY KEY (guess_id),
  CONSTRAINT FK_LK_GU_pg FOREIGN KEY (played_game_id) REFERENCES LK_PLAYED_GAMES(played_game_id),
  INDEX IX_LK_GU_pg_ord (played_game_id, guordinal, create_dt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- P2 — Societies (deferred)
-- -----------------------------------------------------------------------------

CREATE TABLE LK_SOCIETIES (
  society_id      INT          NOT NULL AUTO_INCREMENT,
  sname           VARCHAR(100) NOT NULL,
  sdescription    VARCHAR(500) NULL,
  sowner_user_id  VARCHAR(50)  NULL,
  create_dt       DATETIME     NULL,
  update_dt       DATETIME     NULL,
  sysversion      VARCHAR(10)  NULL,
  CONSTRAINT PK_LK_SOCIETIES PRIMARY KEY (society_id),
  CONSTRAINT FK_LK_SOC_owner FOREIGN KEY (sowner_user_id) REFERENCES LK_USERS(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_USER_SOCIETIES (
  user_id     VARCHAR(50) NOT NULL,
  society_id  INT         NOT NULL,
  create_dt   DATETIME    NULL,
  update_dt   DATETIME    NULL,
  sysversion  VARCHAR(10) NULL,
  CONSTRAINT PK_LK_USER_SOCIETIES PRIMARY KEY (user_id, society_id),
  CONSTRAINT FK_LK_US_user FOREIGN KEY (user_id)    REFERENCES LK_USERS(user_id),
  CONSTRAINT FK_LK_US_soc  FOREIGN KEY (society_id) REFERENCES LK_SOCIETIES(society_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_SOCIETY_ROLES (
  society_id  INT         NOT NULL,
  role_id     INT         NOT NULL,
  create_dt   DATETIME    NULL,
  update_dt   DATETIME    NULL,
  sysversion  VARCHAR(10) NULL,
  CONSTRAINT PK_LK_SOCIETY_ROLES PRIMARY KEY (society_id, role_id),
  CONSTRAINT FK_LK_SR_soc  FOREIGN KEY (society_id) REFERENCES LK_SOCIETIES(society_id),
  CONSTRAINT FK_LK_SR_role FOREIGN KEY (role_id)    REFERENCES LK_ROLES(role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_SOCIETY_COMMENTS (
  comment_id  INT           NOT NULL AUTO_INCREMENT,
  society_id  INT           NOT NULL,
  user_id     VARCHAR(50)   NOT NULL,
  cstatus     VARCHAR(20)   NOT NULL DEFAULT 'displayed', -- displayed|hidden|removed|private
  ctext       VARCHAR(1000) NULL,
  create_dt   DATETIME      NULL,
  update_dt   DATETIME      NULL,
  sysversion  VARCHAR(10)   NULL,
  CONSTRAINT PK_LK_SOCIETY_COMMENTS PRIMARY KEY (comment_id),
  CONSTRAINT FK_LK_SC_soc  FOREIGN KEY (society_id) REFERENCES LK_SOCIETIES(society_id),
  CONSTRAINT FK_LK_SC_user FOREIGN KEY (user_id)    REFERENCES LK_USERS(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
-- P3 — Home News & site content (stubs)
-- -----------------------------------------------------------------------------

CREATE TABLE LK_NEWS (
  news_id     INT           NOT NULL AUTO_INCREMENT,
  ntitle      VARCHAR(200)  NOT NULL,
  nbody       TEXT          NULL,
  nsource     VARCHAR(100)  NULL,
  npublish_dt DATETIME      NULL,
  nstatus     VARCHAR(20)   NOT NULL DEFAULT 'draft', -- draft|published|hidden
  create_dt   DATETIME      NULL,
  update_dt   DATETIME      NULL,
  sysversion  VARCHAR(10)   NULL,
  CONSTRAINT PK_LK_NEWS PRIMARY KEY (news_id),
  INDEX IX_LK_NEWS_pub (nstatus, npublish_dt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE LK_CONTENT (
  content_key  VARCHAR(100) NOT NULL,             -- e.g. 'home.intro', 'footer.privacy'
  cvalue       TEXT         NULL,
  create_dt    DATETIME     NULL,
  update_dt    DATETIME     NULL,
  sysversion   VARCHAR(10)  NULL,
  CONSTRAINT PK_LK_CONTENT PRIMARY KEY (content_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- Seed: roles (minimal). Admin user + sample games are provisioned by separate,
-- credential-free seed scripts (see plan/06-roadmap-and-backlog.md).
-- -----------------------------------------------------------------------------
INSERT INTO LK_ROLES (rname, rdescription, create_dt, update_dt, sysversion) VALUES
  ('Guest',         'Unauthenticated visitor',        NOW(), NOW(), '0.1.0'),
  ('Player',        'Registered player',              NOW(), NOW(), '0.1.0'),
  ('Manager',       'Society manager',                NOW(), NOW(), '0.1.0'),
  ('Administrator', 'Site administrator',             NOW(), NOW(), '0.1.0');
