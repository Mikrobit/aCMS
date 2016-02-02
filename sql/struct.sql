--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: acms01; Type: COMMENT; Schema: -; Owner: acms
--

COMMENT ON DATABASE acms01 IS 'Simil-WordPress';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: acms; Tablespace: 
--

CREATE TABLE posts (
    id bigint NOT NULL,
    author bigint DEFAULT 0 NOT NULL,
    date timestamp with time zone DEFAULT now(),
    title character varying(255),
    content text,
    excerpt text,
    status character(1) DEFAULT 'q'::bpchar NOT NULL,
    modified timestamp with time zone DEFAULT now() NOT NULL,
    parent bigint DEFAULT 0,
    type character varying(128) DEFAULT 'post'::character varying NOT NULL,
    comment_count bigint DEFAULT 0,
    tags character varying(255),
    site bigint DEFAULT 1 NOT NULL,
    start timestamp with time zone DEFAULT now() NOT NULL,
    duration integer DEFAULT 1 NOT NULL,
    "end" timestamp with time zone,
    dow character varying(50),
    dom character varying(255),
    slug character varying(255)
);


ALTER TABLE public.posts OWNER TO acms;

--
-- Name: users; Type: TABLE; Schema: public; Owner: acms; Tablespace: 
--

CREATE TABLE users (
    id bigint NOT NULL,
    login character varying(127) NOT NULL,
    pass character varying(127) NOT NULL,
    email character varying(127) NOT NULL,
    url character varying(255),
    nicename character varying(255),
    registered timestamp with time zone,
    activation_key character varying(127),
    status character(1) DEFAULT 'i'::bpchar NOT NULL,
    type character varying(127) DEFAULT 'author'::character varying NOT NULL
);


ALTER TABLE public.users OWNER TO acms;

--
-- Name: blogposts; Type: VIEW; Schema: public; Owner: acms
--

CREATE VIEW blogposts AS
    SELECT p.id, u.nicename, p.date, p.title, p.content, p.excerpt, p.modified, p.tags FROM (posts p JOIN users u ON ((p.author = u.id))) WHERE (((p.type)::text = 'post'::text) AND (p.status = 'p'::bpchar)) ORDER BY p.date DESC;


ALTER TABLE public.blogposts OWNER TO acms;

--
-- Name: blogpostlimited(integer); Type: FUNCTION; Schema: public; Owner: acms
--

CREATE FUNCTION blogpostlimited("Limit" integer DEFAULT 5) RETURNS SETOF blogposts
    LANGUAGE sql
    AS $_$SELECT p.id, u.nicename, p.date, p.title, p.content, p.excerpt, p.modified, p.tags
   FROM posts p
   JOIN users u ON p.author = u.id
  WHERE p.type::text = 'post'::text AND p.status = 'p'::bpchar
  ORDER BY p.date DESC
  LIMIT $1;$_$;


ALTER FUNCTION public.blogpostlimited("Limit" integer) OWNER TO acms;

--
-- Name: blogpostltd(integer, bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION blogpostltd("Limit" integer DEFAULT 5, "Site" bigint DEFAULT 1::bigint) RETURNS SETOF blogposts
    LANGUAGE sql
    AS $_$SELECT p.id, u.nicename, p.date, p.title, p.content, p.excerpt, p.modified, p.tags
   FROM posts p
   JOIN users u ON p.author = u.id
  WHERE p.type::text = 'post'::text AND p.status = 'p'::bpchar AND p.site = $1
  ORDER BY p.date DESC
  LIMIT $2;$_$;


ALTER FUNCTION public.blogpostltd("Limit" integer, "Site" bigint) OWNER TO postgres;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: acms; Tablespace: 
--

CREATE TABLE comments (
    id bigint NOT NULL,
    "user" bigint,
    post bigint NOT NULL,
    title character varying(255),
    content text,
    author character varying(127),
    author_email character varying(127),
    author_url character varying(255),
    author_ip inet,
    approved boolean DEFAULT false NOT NULL,
    parent bigint
);


ALTER TABLE public.comments OWNER TO acms;

--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: acms
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_id_seq OWNER TO acms;

--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: acms
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: comments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: acms
--

SELECT pg_catalog.setval('comments_id_seq', 1, false);


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: acms
--

CREATE SEQUENCE posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.posts_id_seq OWNER TO acms;

--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: acms
--

ALTER SEQUENCE posts_id_seq OWNED BY posts.id;


--
-- Name: posts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: acms
--

SELECT pg_catalog.setval('posts_id_seq', 27, true);


--
-- Name: sites; Type: TABLE; Schema: public; Owner: acms; Tablespace: 
--

CREATE TABLE sites (
    id bigint NOT NULL,
    name character varying(255) DEFAULT 'aCMS'::character varying NOT NULL,
    pages boolean DEFAULT false NOT NULL,
    news boolean DEFAULT false NOT NULL,
    events boolean DEFAULT false NOT NULL,
    stats boolean DEFAULT false NOT NULL,
    domain character varying(255) DEFAULT 'example.com'::character varying NOT NULL,
    title character varying(255),
    home character varying(64) DEFAULT '/'::character varying
);


ALTER TABLE public.sites OWNER TO acms;

--
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: acms
--

CREATE SEQUENCE sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sites_id_seq OWNER TO acms;

--
-- Name: sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: acms
--

ALTER SEQUENCE sites_id_seq OWNED BY sites.id;


--
-- Name: sites_id_seq; Type: SEQUENCE SET; Schema: public; Owner: acms
--

SELECT pg_catalog.setval('sites_id_seq', 1, false);


--
-- Name: sites_users; Type: TABLE; Schema: public; Owner: acms; Tablespace: 
--

CREATE TABLE sites_users (
    "user" bigint NOT NULL,
    site bigint NOT NULL
);


ALTER TABLE public.sites_users OWNER TO acms;

--
-- Name: TABLE sites_users; Type: COMMENT; Schema: public; Owner: acms
--

COMMENT ON TABLE sites_users IS 'Relazione molti a molti siti-utenti';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: acms
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO acms;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: acms
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: acms
--

SELECT pg_catalog.setval('users_id_seq', 2, true);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: acms
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: acms
--

ALTER TABLE ONLY posts ALTER COLUMN id SET DEFAULT nextval('posts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: acms
--

ALTER TABLE ONLY sites ALTER COLUMN id SET DEFAULT nextval('sites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: acms
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);

--
-- Name: Nome utente; Type: CONSTRAINT; Schema: public; Owner: acms; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT "Nome utente" UNIQUE (login);


--
-- Name: ckey; Type: CONSTRAINT; Schema: public; Owner: acms; Tablespace: 
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT ckey PRIMARY KEY (id);


--
-- Name: pkey; Type: CONSTRAINT; Schema: public; Owner: acms; Tablespace: 
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT pkey PRIMARY KEY (id);


--
-- Name: sid; Type: CONSTRAINT; Schema: public; Owner: acms; Tablespace: 
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT sid PRIMARY KEY (id);


--
-- Name: ukey; Type: CONSTRAINT; Schema: public; Owner: acms; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT ukey PRIMARY KEY (id);


--
-- Name: usid; Type: CONSTRAINT; Schema: public; Owner: acms; Tablespace: 
--

ALTER TABLE ONLY sites_users
    ADD CONSTRAINT usid PRIMARY KEY ("user", site);


--
-- Name: Autore; Type: FK CONSTRAINT; Schema: public; Owner: acms
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT "Autore" FOREIGN KEY (author) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET DEFAULT;


--
-- Name: Post; Type: FK CONSTRAINT; Schema: public; Owner: acms
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT "Post" FOREIGN KEY (post) REFERENCES posts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Site; Type: FK CONSTRAINT; Schema: public; Owner: acms
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT "Site" FOREIGN KEY (site) REFERENCES sites(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Utente; Type: FK CONSTRAINT; Schema: public; Owner: acms
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT "Utente" FOREIGN KEY ("user") REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: site_id; Type: FK CONSTRAINT; Schema: public; Owner: acms
--

ALTER TABLE ONLY sites_users
    ADD CONSTRAINT site_id FOREIGN KEY (site) REFERENCES sites(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: user_id; Type: FK CONSTRAINT; Schema: public; Owner: acms
--

ALTER TABLE ONLY sites_users
    ADD CONSTRAINT user_id FOREIGN KEY ("user") REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

