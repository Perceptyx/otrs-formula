{%- from 'otrs/conf/otrs_settings.sls' import otrs with context %}

include:
  - sun-java
  - sun-java.env

#installing elastic search
'wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - && echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list && apt-get update && apt-get install -y elasticsearch':
  cmd.run

#installing nodejs
"curl -sL https://deb.nodesource.com/setup_8.x | bash && apt-get install -y nodejs":
  cmd.run




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
        otrs: {{ otrs|tojson }}


#installing all outstanding modules
perl /opt/otrs/bin/otrs.CheckEnvironment.pl | grep apt-get  | cut -d "'" -f 2 > /tmp/install.sh && sh /tmp/install.sh:
  cmd.run

"echo export PERL_MM_USE_DEFAULT=1 > /tmp/install_cpan.sh && perl /opt/otrs/bin/otrs.CheckEnvironment.pl  | grep -e \"Use: 'cpan\" | grep -v 'optional' | cut -d \"'\" -f 2 >> /tmp/install_cpan.sh && sh /tmp/install_cpan.sh":
  cmd.run



#chmod a+rx /usr/share/perl5/Module/ && chmod a+rx /usr/share/perl5/ && chmod a+rx /usr/local/share/perl/5.22.1/Module:
#  cmd.run
# Not needed in ubuntu 18

su -c "/opt/otrs/bin/otrs.Console.pl Admin::Package::ReinstallAll" -s /bin/bash otrs; exit 0:
  cmd.run

#Test later all things

perl -cw /opt/otrs/bin/otrs.Console.pl:
  cmd.run

a2enmod proxy_http:
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
        otrs: {{ otrs|tojson }}

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
