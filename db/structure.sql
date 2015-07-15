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
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET search_path = public, pg_catalog;

--
-- Name: flag_comments(integer, integer, text, integer, integer, integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION flag_comments(i_user_id integer, i_flaggable_id integer, s_flaggable_type text, i_flag_limit integer, i_flag_bits integer, i_flag_pts integer, dt_timestamp timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
        DECLARE duplicate_flag_ct INT;
        DECLARE open_review_ct INT;
        DECLARE aggregate_flagger_ids INT[];
        DECLARE return_value INT := 0;
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
            INSERT INTO flags (user_id, flaggable_id, flaggable_type, flag_bits, flag_pts, created_at) VALUES (i_user_id, i_flaggable_id, s_flaggable_type, i_flag_bits, i_flag_pts, dt_timestamp);
            -- increment flaggable's flag_pts
            UPDATE comments SET flag_pts = flag_pts + i_flag_pts WHERE id = i_flaggable_id;
            -- set return value
            return_value := 1;
            -- check whether flaggable exceeds FLAG_POINTS_LIMIT
            IF ((SELECT flag_pts FROM comments WHERE id = i_flaggable_id) >= i_flag_limit) THEN
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
                -- create review
                INSERT INTO reviews (reviewable_id, reviewable_type, open, contributor_id, flagger_ids, created_at)
                  VALUES (
                      i_flaggable_id,
                      s_flaggable_type,
                      TRUE,
                      (SELECT user_id FROM comments WHERE id = i_flaggable_id LIMIT 1),
                      aggregate_flagger_ids,
                      dt_timestamp
                  );
                return_value := 2;
              END IF;
            END IF;
          END IF;
          RETURN return_value;
        END;
      $$;


--
-- Name: flag_revisions(integer, integer, text, integer, integer, integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION flag_revisions(i_user_id integer, i_flaggable_id integer, s_flaggable_type text, i_flag_limit integer, i_flag_bits integer, i_flag_pts integer, dt_timestamp timestamp without time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
        DECLARE duplicate_flag_ct INT;
        DECLARE open_review_ct INT;
        DECLARE aggregate_flagger_ids INT[];
        DECLARE return_value INT := 0;
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
            INSERT INTO flags (user_id, flaggable_id, flaggable_type, flag_bits, flag_pts, created_at) VALUES (i_user_id, i_flaggable_id, s_flaggable_type, i_flag_bits, i_flag_pts, dt_timestamp);
            -- increment flaggable's flag_pts
            UPDATE revisions SET flag_pts = flag_pts + i_flag_pts WHERE id = i_flaggable_id;
            -- set return value
            return_value := 1;
            -- check whether flaggable exceeds FLAG_POINTS_LIMIT
            IF ((SELECT flag_pts FROM revisions WHERE id = i_flaggable_id) >= i_flag_limit) THEN
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
                -- create review
                INSERT INTO reviews (reviewable_id, reviewable_type, open, contributor_id, flagger_ids, created_at)
                  VALUES (
                      i_flaggable_id,
                      s_flaggable_type,
                      TRUE,
                      (SELECT user_id FROM revisions WHERE id = i_flaggable_id LIMIT 1),
                      aggregate_flagger_ids,
                      dt_timestamp
                  );
                return_value := 2;
              END IF;
            END IF;
          END IF;
          RETURN return_value;
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
    commentable_id integer,
    commentable_type character varying,
    text text,
    flag_pts smallint DEFAULT 0,
    status smallint DEFAULT 1,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
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
    ingredient_ids integer[]
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
    optional boolean DEFAULT false
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
    description text
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
-- Name: ingredients; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ingredients (
    id integer NOT NULL,
    name text NOT NULL,
    description text,
    revision_id integer
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
-- Name: point_distributions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE point_distributions (
    id integer NOT NULL,
    user_id integer,
    points integer,
    category_id integer,
    pointable_id integer,
    pointable_type character varying,
    created_at timestamp without time zone
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
    points integer DEFAULT 0
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

ALTER TABLE ONLY ingredients ALTER COLUMN id SET DEFAULT nextval('ingredients_id_seq'::regclass);


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

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


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
-- Name: ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (id);


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
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_comments_on_commentable_id_and_commentable_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comments_on_commentable_id_and_commentable_type ON comments USING btree (commentable_id, commentable_type);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_comments_on_user_id ON comments USING btree (user_id);


--
-- Name: index_drinks_ingredients_on_drink_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_drinks_ingredients_on_drink_id ON drinks_ingredients USING btree (drink_id);


--
-- Name: index_drinks_ingredients_on_ingredient_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_drinks_ingredients_on_ingredient_id ON drinks_ingredients USING btree (ingredient_id);


--
-- Name: index_drinks_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_drinks_on_name ON drinks USING btree (name);


--
-- Name: index_ingredients_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_ingredients_on_name ON ingredients USING btree (name);


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

