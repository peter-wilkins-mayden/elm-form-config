CREATE DATABASE aggy;

\c aggy
CREATE EXTENSION unaccent;
CREATE EXTENSION pg_trgm;
-- Private data structures

CREATE TABLE public.meeting (
  id integer PRIMARY KEY,
  start_time timestamp NOT NULL,
  duration integer NOT NULL,
  data json,
  created_at timestamp NOT NULL default current_timestamp,
  updated_at timestamp NOT NULL default current_timestamp
);

CREATE TABLE public.user (
  email text PRIMARY KEY,
  name text NOT NULL,
  data json,
  created_at timestamp NOT NULL default current_timestamp,
  updated_at timestamp NOT NULL default current_timestamp
);

CREATE TABLE public.user_meeting (
  meeting integer REFERENCES public.meeting (id),
  user_email integer REFERENCES public.user (email),
  data json,
  created_at timestamp NOT NULL default current_timestamp,
  updated_at timestamp NOT NULL default current_timestamp,
  PRIMARY KEY (meeting, user_email)
);

-- Triggers to update updated_at columns
CREATE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE 'plpgsql'
AS $$
BEGIN
  NEW.updated_at := current_timestamp;
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_updated_at
BEFORE UPDATE ON public.meeting
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at();

CREATE TRIGGER update_updated_at
BEFORE UPDATE ON public.dependencies
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at();

CREATE TRIGGER update_updated_at
BEFORE UPDATE ON public.extensions
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at();

CREATE TRIGGER update_updated_at
BEFORE UPDATE ON public.repos
FOR EACH ROW
EXECUTE PROCEDURE update_updated_at();

CREATE VIEW public.package_repos AS
SELECT
  p.package_name,
  r[1] as owner,
  r[2] as repo
FROM
  packages p,
  regexp_matches(repo_location, 'github.com[:\/]([^\/]*)\/([^\. ]*)') r
WHERE
  repo_location ~* 'github';

CREATE OR REPLACE VIEW public.categories AS
SELECT
  p.package_name,
  initcap(btrim(translate(c.c, chr(10) || chr(13), ''))) AS category_name
FROM
  packages p,
  LATERAL regexp_split_to_table(p.category, ','::text) c(c)
WHERE
  btrim(c.c) <> ''::text;

-- API exposed through PostgREST
CREATE SCHEMA api;

CREATE OR REPLACE VIEW api.packages AS
SELECT
  p.package_name,
  p.version,
  p.license,
  p.description,
  p.category,
  p.homepage,
  p.package_url,
  p.repo_type,
  p.repo_location,
  r.stars,
  r.forks,
  r.collaborators,
  (
    SELECT coalesce(json_agg(DISTINCT e.extension), '[]')
    FROM extensions e
    WHERE e.extension IS NOT NULL AND e.package_name = p.package_name
  ) AS extensions,
  (
    SELECT coalesce(json_agg(d.dependency), '[]')
    FROM dependencies d
    WHERE d.dependency IS NOT NULL AND d.dependent = p.package_name
  ) AS dependencies,
  (
    SELECT coalesce(json_agg(d.dependent), '[]')
    FROM dependencies d
    WHERE d.dependent IS NOT NULL AND d.dependency = p.package_name
  ) AS dependents,
  -- when querying created at we usually want to know when it first got into our database
  LEAST(p.created_at, r.created_at) as created_at,
  -- when querying created at we usually want to know when it was last updated
  GREATEST(p.updated_at, r.updated_at) as updated_at
FROM
  packages p
  JOIN repos r USING (package_name)
GROUP BY
  p.package_name, r.package_name;

CREATE USER postgrest PASSWORD 'temporary_password';
-- CREATE ROLE anonymous;
-- GRANT anonymous TO postgrest;
-- GRANT USAGE ON SCHEMA api TO anonymous;
-- GRANT SELECT ON ALL TABLES IN SCHEMA api TO anonymous;

create role web_anon nologin;
grant web_anon to postgrest;

grant usage on schema api to web_anon;
grant select on ALL TABLES IN SCHEMA api to web_anon;
