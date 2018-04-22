{% set p  = salt['pillar.get']('otrs', {}) %}
{% set g  = salt['grains.get']('otrs', {}) %}



{%- set default_version      = '6.0.6' %}
{%- set default_prefix       = '/opt' %}

{%- set default_source_url   = 'http://ftp.otrs.org/pub/otrs/' %}
{%- set default_user    = 'otrs' %}
{%- set default_group   = 'otrs' %}

{%- set default_db_server    = 'localhost' %}
{%- set default_db_name      = 'otrs' %}
{%- set default_db_username  = 'otrs' %}
{%- set default_db_password  = 'otrs' %}



{%- set default_db_type      = 'postgresql72' %}

{%- set default_db_port      = '5432' %}
{%- set default_db_type_name      = 'postgresql' %}
{%- set default_hostname	  = 'localhost' %}

{%- set default_use_https   = false %}

{%- set default_home  = '/opt/otrs-home' %}


{%- set version        = g.get('version', p.get('version', default_version)) %}
{%- set prefix         = g.get('prefix', p.get('prefix', default_prefix)) %}

{%- set source_url     = g.get('source_url', p.get('source_url', default_source_url)) %}
{%- set user           = g.get('user', p.get('user', default_user)) %}
{%- set group          = g.get('group', p.get('group', default_group)) %}

{%- set db_server      = g.get('db_server', p.get('db_server', default_db_server)) %}
{%- set db_name        = g.get('db_name', p.get('db_name', default_db_name)) %}
{%- set db_username    = g.get('db_username', p.get('db_username', default_db_username)) %}
{%- set db_password    = g.get('db_password', p.get('db_password', default_db_password)) %}


{%- set db_type      = g.get('db_type', p.get('db_type', default_db_type)) %}
{%- set db_port      = g.get('db_port', p.get('db_port', default_db_port)) %}
{%- set db_type_name      = g.get('db_type_name', p.get('db_type_name', default_db_type_name)) %}
{%- set hostname     = g.get('hostname', p.get('hostname', default_hostname)) %}

{%- set use_https     = g.get('use_https', p.get('use_https', default_use_https)) %}

{%- set home      = g.get('home', p.get('home', default_home)) %}





{%- set otrs = {} %}
{%- do  otrs.update( { 'version'       : version,
                      'source_url'     : source_url,
                      'home'           : home,
                      'prefix'         : prefix,
                      'user'           : user,
                      'group'          : group,
                      'db_server'      : db_server,
                      'db_name'        : db_name,
                      'db_username'    : db_username,
                      'db_password'    : db_password,
                      'db_port'        : db_port,
                      'db_type'        : db_type,
                      'db_type_name'   : db_type_name,
                      'hostname'       : hostname,
                      'use_https'      : use_https
                  }) %}


