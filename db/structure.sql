--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET search_path = public, pg_catalog;

--
-- Name: create_or_update_vote(integer, integer, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION create_or_update_vote(i_user_id integer, i_votable_id integer, s_votable_type text, i_sign integer) RETURNS TABLE(vote_id integer, prev_sign integer)
    LANGUAGE plpgsql
    AS $$
      BEGIN
        LOCK ONLY votes IN SHARE MODE;
        SELECT id, sign FROM votes
          WHERE user_id = i_user_id AND votable_id = i_votable_id AND votable_type = s_votable_type
          LIMIT 1
          INTO vote_id, prev_sign;
        IF (vote_id IS NOT NULL) THEN
          UPDATE votes SET sign = i_sign, updated_at = current_timestamp
            WHERE user_id = i_user_id AND votable_id = i_votable_id AND votable_type = s_votable_type;
        ELSE
          prev_sign := 0;
          INSERT INTO votes (user_id, votable_id, votable_type, sign, created_at, updated_at)
            VALUES (i_user_id, i_votable_id, s_votable_type, i_sign, current_timestamp, current_timestamp)
            RETURNING id INTO vote_id;
        END IF;
        RETURN NEXT;
      END;
      $$;


--
-- Name: flag_record(text, integer, integer, text, integer, integer, integer, text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION flag_record(s_table_name text, i_user_id integer, i_flaggable_id integer, s_flaggable_type text, i_flag_limit integer, i_flag_bits integer, i_flag_pts integer, s_description text, dt_timestamp timestamp without time zone) RETURNS TABLE(flag_created boolean, review_created boolean, flag_id integer)
    LANGUAGE plpgsql
    AS $$
  DECLARE duplicate_flag_ct INT;
  DECLARE open_review_ct INT;
  DECLARE aggregate_flagger_ids INT[];
  DECLARE contributor_id INT;
  DECLARE flag_pts_after_update INT;
  BEGIN
    -- check for existing flag with the same user and flaggable
    LOCK ONLY flags IN SHARE MODE;
    SELECT COUNT(*) FROM flags
      WHERE user_id = i_user_id
      AND flaggable_id = i_flaggable_id
      AND flaggable_type = s_flaggable_type
      LIMIT 1
      INTO duplicate_flag_ct;
    IF (SELECT duplicate_flag_ct) = 0 THEN
      -- create flag
      INSERT INTO flags (user_id, flaggable_id, flaggable_type, flag_bits, flag_pts, description, created_at) VALUES (i_user_id, i_flaggable_id, s_flaggable_type, i_flag_bits, i_flag_pts, s_description, dt_timestamp) RETURNING id INTO flag_id;
      -- increment flaggable's flag_pts
      EXECUTE FORMAT('UPDATE %s SET flag_pts = flag_pts + %s WHERE id = %s RETURNING flag_pts', s_table_name, i_flag_pts, i_flaggable_id) INTO flag_pts_after_update;
      -- set return value
      flag_created := TRUE;
      -- check whether flaggable exceeds FLAG_POINTS_LIMIT
      IF (flag_pts_after_update >= i_flag_limit) THEN
        -- check whether an open review exists for the flaggable
        LOCK ONLY reviews IN SHARE MODE;
        SELECT COUNT(*) FROM reviews
          WHERE open = TRUE
          AND reviewable_id = i_flaggable_id
          AND reviewable_type = s_flaggable_type
          LIMIT 1
          INTO open_review_ct;
        IF (SELECT open_review_ct) = 0 THEN
          -- calc aggregate flagger_ids
          SELECT ARRAY(SELECT user_id FROM flags WHERE flaggable_id = i_flaggable_id AND flaggable_type = s_flaggable_type) INTO aggregate_flagger_ids;
          -- get id of contributor whose contribution was flagged because this user is also not allowed to vote on the review to be created
          EXECUTE FORMAT('SELECT user_id FROM %s WHERE id = %s LIMIT 1', s_table_name, i_flaggable_id) INTO contributor_id;
          -- create review
          INSERT INTO reviews (reviewable_id, reviewable_type, open, contributor_id, flagger_ids, created_at)
            VALUES (
                i_flaggable_id,
                s_flaggable_type,
                TRUE,
                contributor_id,
                aggregate_flagger_ids,
                dt_timestamp
            );
          -- set return value
          review_created := TRUE;
        END IF;
      END IF;
    END IF;
    -- return
    RETURN NEXT;
  END;
$$;


--
-- Name: insert_unique_trophy(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_unique_trophy(i_user_id integer, i_category_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
      DECLARE i_duplicate_ct INT;
      BEGIN
        LOCK ONLY trophies IN SHARE MODE;
        SELECT COUNT(*) FROM trophies WHERE user_id = i_user_id AND category_id = i_category_id LIMIT 1 INTO i_duplicate_ct;
        IF (i_duplicate_ct = 0) THEN
          INSERT INTO trophies (user_id, category_id, created_at) VALUES (i_user_id, i_category_id, current_timestamp);
          RETURN TRUE;
        ELSE
          RETURN FALSE;
        END IF;
      END;
      $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments (
    id integer NOT NULL,
    user_id integer,
    drink_id integer,
    text text,
    flag_pts smallint DEFAULT 0,
    status smallint DEFAULT 1,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tip_pts integer DEFAULT 0,
    score integer DEFAULT 0,
    upvote_ct integer DEFAULT 0,
    dnvote_ct integer DEFAULT 0,
    parent_id integer,
    user_name character varying,
    user_avatar character varying
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: drinks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE drinks (
    id integer NOT NULL,
    name text NOT NULL,
    instructions text,
    glass_id smallint,
    abv smallint,
    description text,
    up_vote_ct integer DEFAULT 0,
    dn_vote_ct integer DEFAULT 0,
    score double precision DEFAULT 0.0,
    color character varying,
    revision_id integer,
    comment_ct integer DEFAULT 0,
    ingredient_ct integer DEFAULT 0,
    profane boolean DEFAULT false,
    non_alcoholic boolean DEFAULT false,
    author_id integer,
    calories smallint,
    prep_time text,
    required_canonical_ingredient_ids integer[],
    user_id integer,
    related_drink_ids integer[] DEFAULT '{}'::integer[]
);


--
-- Name: drinks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE drinks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: drinks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE drinks_id_seq OWNED BY drinks.id;


--
-- Name: drinks_ingredients; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE drinks_ingredients (
    drink_id integer,
    ingredient_id integer,
    qty character varying,
    optional boolean DEFAULT false,
    canonical_id integer,
    sort integer DEFAULT 0
);


--
-- Name: flags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE flags (
    id integer NOT NULL,
    user_id integer,
    flaggable_id integer,
    flaggable_type character varying,
    flag_bits smallint DEFAULT 0,
    flag_pts smallint NOT NULL,
    created_at timestamp without time zone,
    description text,
    tallied integer
);


--
-- Name: flags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE flags_id_seq OWNED BY flags.id;


--
-- Name: glasses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE glasses (
    glass_id integer NOT NULL,
    name text NOT NULL
);


--
-- Name: identities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE identities (
    id integer NOT NULL,
    user_id integer,
    provider character varying,
    uid character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: identities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE identities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE identities_id_seq OWNED BY identities.id;


--
-- Name: ingredient_revisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredient_revisions (
    id integer NOT NULL,
    user_id integer,
    ingredient_id integer,
    parent_id integer,
    name character varying,
    description text,
    prev_description text,
    canonical_id integer,
    prev_canonical_id integer,
    flag_pts smallint DEFAULT 0,
    status smallint DEFAULT 0,
    created_at timestamp without time zone
);


--
-- Name: ingredient_revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ingredient_revisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredient_revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ingredient_revisions_id_seq OWNED BY ingredient_revisions.id;


--
-- Name: ingredients; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredients (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    revision_id integer,
    canonical_id integer
);


--
-- Name: ingredients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ingredients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ingredients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ingredients_id_seq OWNED BY ingredients.id;


--
-- Name: photos; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE photos (
    id integer NOT NULL,
    drink_id integer,
    upvote_ct smallint DEFAULT 0,
    dnvote_ct smallint DEFAULT 0,
    score smallint DEFAULT 0,
    flag_pts smallint DEFAULT 0,
    status smallint DEFAULT 1,
    created_at timestamp without time zone,
    user_id integer,
    alt character varying,
    file_file_name character varying,
    file_content_type character varying,
    file_file_size integer,
    file_updated_at timestamp without time zone
);


--
-- Name: photos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE photos_id_seq OWNED BY photos.id;


--
-- Name: point_distributions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE point_distributions (
    id integer NOT NULL,
    user_id integer,
    points integer,
    category_id integer,
    pointable_id integer,
    pointable_type character varying,
    created_at timestamp without time zone,
    viewed boolean DEFAULT false,
    title character varying,
    description character varying,
    url character varying
);


--
-- Name: point_distributions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE point_distributions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: point_distributions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE point_distributions_id_seq OWNED BY point_distributions.id;


--
-- Name: review_votes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE review_votes (
    id integer NOT NULL,
    user_id integer,
    review_id integer,
    points smallint NOT NULL,
    created_at timestamp without time zone,
    points_awarded boolean DEFAULT false
);


--
-- Name: review_votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE review_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: review_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE review_votes_id_seq OWNED BY review_votes.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reviews (
    id integer NOT NULL,
    reviewable_id integer,
    reviewable_type character varying,
    open boolean DEFAULT true,
    contributor_id integer,
    points smallint DEFAULT 0,
    flagger_ids integer[] DEFAULT '{}'::integer[],
    created_at timestamp without time zone,
    last_hold timestamp without time zone,
    last_hold_user_id integer
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reviews_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reviews_id_seq OWNED BY reviews.id;


--
-- Name: revisions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE revisions (
    id integer NOT NULL,
    user_id integer,
    drink_id integer,
    instructions text,
    flag_pts smallint DEFAULT 0,
    status smallint DEFAULT 0,
    created_at timestamp without time zone,
    name text,
    description text,
    prep_time text,
    calories integer,
    parent_id integer,
    non_alcoholic boolean DEFAULT false,
    profane boolean DEFAULT false,
    ingredients hstore[],
    prev_description text,
    prev_instruction text,
    prev_ingredients hstore[]
);


--
-- Name: revisions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE revisions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: revisions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE revisions_id_seq OWNED BY revisions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: trophies; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE trophies (
    id integer NOT NULL,
    user_id integer NOT NULL,
    category_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: trophies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE trophies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trophies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE trophies_id_seq OWNED BY trophies.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    name character varying,
    no_alcohol boolean DEFAULT false,
    no_profanity boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    helpful_flags integer DEFAULT 0,
    unhelpful_flags integer DEFAULT 0,
    majority_review_votes integer DEFAULT 0,
    minority_review_votes integer DEFAULT 0,
    points integer DEFAULT 0,
    photo_file_name character varying,
    photo_content_type character varying,
    photo_file_size integer,
    photo_updated_at timestamp without time zone,
    nickname character varying,
    bio text,
    twitter character varying,
    location character varying,
    gold_trophy_ct integer DEFAULT 0,
    silver_trophy_ct integer DEFAULT 0,
    bronze_trophy_ct integer DEFAULT 0,
    comment_ct integer DEFAULT 0,
    revision_ct integer DEFAULT 0,
    photo_ct integer DEFAULT 0
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: votes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE votes (
    id integer NOT NULL,
    user_id integer,
    votable_id integer,
    votable_type character varying,
    sign smallint DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE votes_id_seq OWNED BY votes.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY drinks ALTER COLUMN id SET DEFAULT nextval('drinks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY flags ALTER COLUMN id SET DEFAULT nextval('flags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY identities ALTER COLUMN id SET DEFAULT nextval('identities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredient_revisions ALTER COLUMN id SET DEFAULT nextval('ingredient_revisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ingredients ALTER COLUMN id SET DEFAULT nextval('ingredients_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY photos ALTER COLUMN id SET DEFAULT nextval('photos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY point_distributions ALTER COLUMN id SET DEFAULT nextval('point_distributions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY review_votes ALTER COLUMN id SET DEFAULT nextval('review_votes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reviews ALTER COLUMN id SET DEFAULT nextval('reviews_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY revisions ALTER COLUMN id SET DEFAULT nextval('revisions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY trophies ALTER COLUMN id SET DEFAULT nextval('trophies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY votes ALTER COLUMN id SET DEFAULT nextval('votes_id_seq'::regclass);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: drinks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY drinks
    ADD CONSTRAINT drinks_pkey PRIMARY KEY (id);


--
-- Name: flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY flags
    ADD CONSTRAINT flags_pkey PRIMARY KEY (id);


--
-- Name: glasses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY glasses
    ADD CONSTRAINT glasses_pkey PRIMARY KEY (glass_id);


--
-- Name: identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: ingredient_revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredient_revisions
    ADD CONSTRAINT ingredient_revisions_pkey PRIMARY KEY (id);


--
-- Name: ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (id);


--
-- Name: photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY photos
    ADD CONSTRAINT photos_pkey PRIMARY KEY (id);


--
-- Name: point_distributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY point_distributions
    ADD CONSTRAINT point_distributions_pkey PRIMARY KEY (id);


--
-- Name: review_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY review_votes
    ADD CONSTRAINT review_votes_pkey PRIMARY KEY (id);


--
-- Name: reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: revisions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY revisions
    ADD CONSTRAINT revisions_pkey PRIMARY KEY (id);


--
-- Name: trophies_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY trophies
    ADD CONSTRAINT trophies_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (id);


--
-- Name: index_comments_on_drink_id_and_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comments_on_drink_id_and_id ON comments USING btree (drink_id, id);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comments_on_user_id ON comments USING btree (user_id);


--
-- Name: index_drinks_ingredients_on_drink_id_and_sort; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_drinks_ingredients_on_drink_id_and_sort ON drinks_ingredients USING btree (drink_id, sort);


--
-- Name: index_drinks_ingredients_on_ingredient_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_drinks_ingredients_on_ingredient_id ON drinks_ingredients USING btree (ingredient_id);


--
-- Name: index_drinks_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_drinks_on_name ON drinks USING btree (name);


--
-- Name: index_flags; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_flags ON flags USING btree (user_id, flaggable_id, flaggable_type);


--
-- Name: index_ingredient_revisions_on_ingredient_id_and_user_id_and_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_ingredient_revisions_on_ingredient_id_and_user_id_and_id ON ingredient_revisions USING btree (ingredient_id, user_id, id);


--
-- Name: index_ingredients_on_canonical_id_and_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_ingredients_on_canonical_id_and_id ON ingredients USING btree (canonical_id, id);


--
-- Name: index_ingredients_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_ingredients_on_name ON ingredients USING btree (name);


--
-- Name: index_photos_on_drink_id_and_status; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_photos_on_drink_id_and_status ON photos USING btree (drink_id, status);


--
-- Name: index_point_distributions; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_point_distributions ON point_distributions USING btree (user_id, pointable_id, pointable_type);


--
-- Name: index_reviews_on_open_and_contributor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_reviews_on_open_and_contributor_id ON reviews USING btree (open, contributor_id);


--
-- Name: index_reviews_on_reviewable_id_and_reviewable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_reviews_on_reviewable_id_and_reviewable_type ON reviews USING btree (reviewable_id, reviewable_type);


--
-- Name: index_revisions_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_revisions_on_user_id ON revisions USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_viewed_point_distributions; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_viewed_point_distributions ON point_distributions USING btree (user_id, viewed, created_at);


--
-- Name: index_votes; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_votes ON votes USING btree (user_id, votable_id, votable_type);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20150525000000');

INSERT INTO schema_migrations (version) VALUES ('20150525004907');

INSERT INTO schema_migrations (version) VALUES ('20150525004945');

INSERT INTO schema_migrations (version) VALUES ('20150525005011');

INSERT INTO schema_migrations (version) VALUES ('20150525005012');

INSERT INTO schema_migrations (version) VALUES ('20150609043501');

INSERT INTO schema_migrations (version) VALUES ('20150611031813');

INSERT INTO schema_migrations (version) VALUES ('20150613230454');

INSERT INTO schema_migrations (version) VALUES ('20150626002933');

INSERT INTO schema_migrations (version) VALUES ('20150629032253');

INSERT INTO schema_migrations (version) VALUES ('20150629034153');

INSERT INTO schema_migrations (version) VALUES ('20150703032217');

INSERT INTO schema_migrations (version) VALUES ('20150705022114');

INSERT INTO schema_migrations (version) VALUES ('20150706040344');

INSERT INTO schema_migrations (version) VALUES ('20150706224543');

INSERT INTO schema_migrations (version) VALUES ('20150709025400');

INSERT INTO schema_migrations (version) VALUES ('20150714041127');

INSERT INTO schema_migrations (version) VALUES ('20150714200552');

INSERT INTO schema_migrations (version) VALUES ('20150714200713');

INSERT INTO schema_migrations (version) VALUES ('20150715143929');

INSERT INTO schema_migrations (version) VALUES ('20150715225937');

INSERT INTO schema_migrations (version) VALUES ('20150718171031');

INSERT INTO schema_migrations (version) VALUES ('20150719231022');

INSERT INTO schema_migrations (version) VALUES ('20150721025601');

INSERT INTO schema_migrations (version) VALUES ('20150722215532');

INSERT INTO schema_migrations (version) VALUES ('20150725005201');

INSERT INTO schema_migrations (version) VALUES ('20150725173001');

INSERT INTO schema_migrations (version) VALUES ('20150725174022');

INSERT INTO schema_migrations (version) VALUES ('20150726180135');

INSERT INTO schema_migrations (version) VALUES ('20150728010414');

INSERT INTO schema_migrations (version) VALUES ('20150729003919');

INSERT INTO schema_migrations (version) VALUES ('20150730032132');

INSERT INTO schema_migrations (version) VALUES ('20150803235732');

INSERT INTO schema_migrations (version) VALUES ('20150803235836');

INSERT INTO schema_migrations (version) VALUES ('20150806001328');

INSERT INTO schema_migrations (version) VALUES ('20150806004006');

