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

