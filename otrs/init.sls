{%- from 'otrs/conf/otrs_settings.sls' import otrs with context %}

otrs-user:
  group:
    - name: {{ otrs.user }}
    - present
  user.present:
    - name: {{ otrs.user }}
    - fullname: OTRS user
    - shell: /bin/sh
    - home: {{ otrs.home }}
    - groups:
       - {{ otrs.user }}
       - www-data

unpack-otrs-tarball:
  archive.extracted:
    - name: {{ otrs.prefix }}
    - source: {{ otrs.source_url }}otrs-{{ otrs.version }}.tar.gz
    - archive_format: tar
    - skip_verify: true
    - user: {{ otrs.user }}
    - options: z
    - keep: True
    - overwrite: True
    - unless: 
      - ls {{ otrs.prefix }}/otrs-{{ otrs.version }}

create-otrs-symlink:
  file.symlink:
    - name: {{ otrs.prefix }}/otrs
    - target: {{ otrs.prefix }}/otrs-{{ otrs.version }}
    - user: {{ otrs.user }}
    - watch:
      - archive: unpack-otrs-tarball


{{ otrs.prefix }}/otrs/Kernel/Config.pm:
  file.managed:
    - source: salt://otrs/templates/Config.pm.tmpl
    - user: {{ otrs.user }}
    - group: {{ otrs.user }}
    - template: jinja
    - context:
        otrs: {{ otrs }}


#installing all outstanding modules
perl /opt/otrs/bin/otrs.CheckModules.pl | grep apt-get  | cut -d "'" -f 2 > /tmp/install.sh && sh /tmp/install.sh:
  cmd.run


#Test later all things
perl -cw /opt/otrs/bin/cgi-bin/index.pl:
  cmd.run

perl -cw /opt/otrs/bin/cgi-bin/customer.pl:
  cmd.run

perl -cw /opt/otrs/bin/otrs.Console.pl:
  cmd.run

otrs-apache-configuration-symlink:
  file.symlink:
    - name: /etc/apache2/sites-enabled/zzz_otrs.conf
    - target: {{ otrs.prefix }}/otrs/scripts/apache2-httpd.include.conf
    - user: www-data
    - require:
      - pkg: apache2
    - watch_in:
      - service: apache_service

apache_service:
  service.running:
    - name: apache2
    - enable: True

cd /opt/otrs/ && bin/otrs.SetPermissions.pl:
  cmd.run

mv {{ otrs.prefix }}/otrs/var/cron/aaa_base.dist {{ otrs.prefix }}/otrs/var/cron/aaa_base:
  cmd.run:
    - creates: {{ otrs.prefix }}/otrs/var/cron/aaa_base


mv {{ otrs.prefix }}/otrs/var/cron/otrs_daemon.dist {{ otrs.prefix }}/otrs/var/cron/otrs_daemon:
  cmd.run:
    - creates: {{ otrs.prefix }}/otrs/var/cron/otrs_daemon



otrs-init-script:
  file.managed:
    - name: /etc/systemd/system/otrs.service
    - source: salt://otrs/templates/otrs.service.tmpl
    - user: root
    - group: root
    - mode: 0755
    - template: jinja
    - context:
        otrs: {{ otrs }}

systemctl daemon-reload:
  cmd.run

otrs-service:
  service.running:
    - name: otrs
    - enable: True
    - require:
      - archive: unpack-otrs-tarball
      - file: otrs-init-script
    - watch:
      - /etc/systemd/system/otrs.service
      - {{ otrs.prefix }}/otrs/Kernel/Config.pm


