--
-- PostgreSQL database dump
--

-- Dumped from database version 15.5
-- Dumped by pg_dump version 15.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: oban_job_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.oban_job_state AS ENUM (
    'available',
    'scheduled',
    'executing',
    'retryable',
    'completed',
    'discarded',
    'cancelled'
);


--
-- Name: oban_jobs_notify(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.oban_jobs_notify() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  channel text;
  notice json;
BEGIN
  IF NEW.state = 'available' THEN
    channel = 'public.oban_insert';
    notice = json_build_object('queue', NEW.queue);

    PERFORM pg_notify(channel, notice::text);
  END IF;

  RETURN NULL;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id uuid NOT NULL,
    handle public.citext NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    customer_id character varying(255)
);


--
-- Name: builds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.builds (
    id uuid NOT NULL,
    version character varying(255) NOT NULL,
    type integer NOT NULL,
    status integer DEFAULT 1 NOT NULL,
    vm_id character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    vm_logs_url character varying(255),
    markdown_error_message character varying(255),
    metadata jsonb DEFAULT '{}'::jsonb
);


--
-- Name: content_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_sources (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    id_in_content_platform public.citext NOT NULL,
    content_platform integer NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: credentials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credentials (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    provider integer NOT NULL,
    provider_id integer NOT NULL,
    token character varying(255) NOT NULL,
    refresh_token character varying(255) NOT NULL,
    expires_at timestamp(0) without time zone NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    refresh_token_expires_at timestamp(0) without time zone
);


--
-- Name: oban_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oban_jobs (
    id bigint NOT NULL,
    state public.oban_job_state DEFAULT 'available'::public.oban_job_state NOT NULL,
    queue text DEFAULT 'default'::text NOT NULL,
    worker text NOT NULL,
    args jsonb DEFAULT '{}'::jsonb NOT NULL,
    errors jsonb[] DEFAULT ARRAY[]::jsonb[] NOT NULL,
    attempt integer DEFAULT 0 NOT NULL,
    max_attempts integer DEFAULT 20 NOT NULL,
    inserted_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    scheduled_at timestamp without time zone DEFAULT timezone('UTC'::text, now()) NOT NULL,
    attempted_at timestamp without time zone,
    completed_at timestamp without time zone,
    attempted_by text[],
    discarded_at timestamp without time zone,
    priority integer DEFAULT 0 NOT NULL,
    tags character varying(255)[] DEFAULT ARRAY[]::character varying[],
    meta jsonb DEFAULT '{}'::jsonb,
    cancelled_at timestamp without time zone,
    CONSTRAINT attempt_range CHECK (((attempt >= 0) AND (attempt <= max_attempts))),
    CONSTRAINT positive_max_attempts CHECK ((max_attempts > 0)),
    CONSTRAINT priority_range CHECK (((priority >= 0) AND (priority <= 3))),
    CONSTRAINT queue_length CHECK (((char_length(queue) > 0) AND (char_length(queue) < 128))),
    CONSTRAINT worker_length CHECK (((char_length(worker) > 0) AND (char_length(worker) < 128)))
);


--
-- Name: TABLE oban_jobs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.oban_jobs IS '11';


--
-- Name: oban_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oban_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oban_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oban_jobs_id_seq OWNED BY public.oban_jobs.id;


--
-- Name: oban_peers; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE public.oban_peers (
    name text NOT NULL,
    node text NOT NULL,
    started_at timestamp without time zone NOT NULL,
    expires_at timestamp without time zone NOT NULL
);


--
-- Name: organization_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_users (
    id uuid NOT NULL,
    role integer NOT NULL,
    organization_id uuid NOT NULL,
    user_id uuid NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id uuid NOT NULL,
    account_id uuid NOT NULL,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email public.citext NOT NULL,
    hashed_password character varying(255) NOT NULL,
    confirmed_at timestamp(0) without time zone,
    inserted_at timestamp(0) without time zone NOT NULL,
    updated_at timestamp(0) without time zone NOT NULL,
    account_id uuid NOT NULL,
    role integer DEFAULT 0 NOT NULL
);


--
-- Name: users_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token bytea NOT NULL,
    context character varying(255) NOT NULL,
    sent_to character varying(255),
    inserted_at timestamp(0) without time zone NOT NULL
);


--
-- Name: oban_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_jobs ALTER COLUMN id SET DEFAULT nextval('public.oban_jobs_id_seq'::regclass);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: credentials credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_pkey PRIMARY KEY (id);


--
-- Name: builds git_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.builds
    ADD CONSTRAINT git_events_pkey PRIMARY KEY (id);


--
-- Name: oban_jobs oban_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_jobs
    ADD CONSTRAINT oban_jobs_pkey PRIMARY KEY (id);


--
-- Name: oban_peers oban_peers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oban_peers
    ADD CONSTRAINT oban_peers_pkey PRIMARY KEY (name);


--
-- Name: organization_users organization_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: content_sources projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_sources
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_tokens users_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_pkey PRIMARY KEY (id);


--
-- Name: accounts_customer_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts_customer_id_index ON public.accounts USING btree (customer_id);


--
-- Name: accounts_handle_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX accounts_handle_index ON public.accounts USING btree (handle);


--
-- Name: builds_version_type_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX builds_version_type_index ON public.builds USING btree (version, type);


--
-- Name: content_sources_id_in_content_platform_content_platform_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX content_sources_id_in_content_platform_content_platform_index ON public.content_sources USING btree (id_in_content_platform, content_platform);


--
-- Name: credentials_user_id_provider_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX credentials_user_id_provider_index ON public.credentials USING btree (user_id, provider);


--
-- Name: oban_jobs_args_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_args_index ON public.oban_jobs USING gin (args);


--
-- Name: oban_jobs_meta_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_meta_index ON public.oban_jobs USING gin (meta);


--
-- Name: oban_jobs_state_queue_priority_scheduled_at_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX oban_jobs_state_queue_priority_scheduled_at_id_index ON public.oban_jobs USING btree (state, queue, priority, scheduled_at, id);


--
-- Name: organization_users_organization_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX organization_users_organization_id_user_id_index ON public.organization_users USING btree (organization_id, user_id);


--
-- Name: organizations_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX organizations_account_id_index ON public.organizations USING btree (account_id);


--
-- Name: users_account_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_account_id_index ON public.users USING btree (account_id);


--
-- Name: users_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_index ON public.users USING btree (email);


--
-- Name: users_tokens_context_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_tokens_context_token_index ON public.users_tokens USING btree (context, token);


--
-- Name: users_tokens_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_tokens_user_id_index ON public.users_tokens USING btree (user_id);


--
-- Name: oban_jobs oban_notify; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER oban_notify AFTER INSERT ON public.oban_jobs FOR EACH ROW EXECUTE FUNCTION public.oban_jobs_notify();


--
-- Name: credentials credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credentials
    ADD CONSTRAINT credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: organization_users organization_users_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organizations(id) ON DELETE CASCADE;


--
-- Name: organization_users organization_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_users
    ADD CONSTRAINT organization_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: organizations organizations_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: content_sources projects_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_sources
    ADD CONSTRAINT projects_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: users users_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: users_tokens users_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_tokens
    ADD CONSTRAINT users_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20230711104335);
INSERT INTO public."schema_migrations" (version) VALUES (20230711104631);
INSERT INTO public."schema_migrations" (version) VALUES (20230711152254);
INSERT INTO public."schema_migrations" (version) VALUES (20230717082832);
INSERT INTO public."schema_migrations" (version) VALUES (20230718121759);
INSERT INTO public."schema_migrations" (version) VALUES (20230718181410);
INSERT INTO public."schema_migrations" (version) VALUES (20230720134037);
INSERT INTO public."schema_migrations" (version) VALUES (20230720172921);
INSERT INTO public."schema_migrations" (version) VALUES (20230724101641);
INSERT INTO public."schema_migrations" (version) VALUES (20230724161306);
INSERT INTO public."schema_migrations" (version) VALUES (20230725141331);
INSERT INTO public."schema_migrations" (version) VALUES (20230725150014);
INSERT INTO public."schema_migrations" (version) VALUES (20230726161449);
INSERT INTO public."schema_migrations" (version) VALUES (20230726161505);
INSERT INTO public."schema_migrations" (version) VALUES (20230726182257);
INSERT INTO public."schema_migrations" (version) VALUES (20230727131541);
INSERT INTO public."schema_migrations" (version) VALUES (20230727132456);
INSERT INTO public."schema_migrations" (version) VALUES (20230727132757);
INSERT INTO public."schema_migrations" (version) VALUES (20230727134150);
INSERT INTO public."schema_migrations" (version) VALUES (20230727135033);
INSERT INTO public."schema_migrations" (version) VALUES (20230727142222);
INSERT INTO public."schema_migrations" (version) VALUES (20230727143003);
INSERT INTO public."schema_migrations" (version) VALUES (20230730165042);
INSERT INTO public."schema_migrations" (version) VALUES (20230730171003);
INSERT INTO public."schema_migrations" (version) VALUES (20230730194205);
INSERT INTO public."schema_migrations" (version) VALUES (20230814161822);
INSERT INTO public."schema_migrations" (version) VALUES (20230814170535);
INSERT INTO public."schema_migrations" (version) VALUES (20230829093317);
INSERT INTO public."schema_migrations" (version) VALUES (20230901124423);
INSERT INTO public."schema_migrations" (version) VALUES (20230902105218);
INSERT INTO public."schema_migrations" (version) VALUES (20230911154758);
INSERT INTO public."schema_migrations" (version) VALUES (20230914144628);
INSERT INTO public."schema_migrations" (version) VALUES (20230923162017);
INSERT INTO public."schema_migrations" (version) VALUES (20230923172220);
INSERT INTO public."schema_migrations" (version) VALUES (20230924145856);
INSERT INTO public."schema_migrations" (version) VALUES (20230924154601);
INSERT INTO public."schema_migrations" (version) VALUES (20231006134415);
INSERT INTO public."schema_migrations" (version) VALUES (20231031133721);
INSERT INTO public."schema_migrations" (version) VALUES (20240213055018);
INSERT INTO public."schema_migrations" (version) VALUES (20240226175502);
