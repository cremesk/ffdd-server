{# FFDD Routing Tables #}
iproute2:
  pkg.installed:
    - refresh: True
    - name: iproute2

/etc/iproute2/rt_tables:
  file.managed:
    - source: salt://iproute2/etc/iproute2/rt_tables
    - user: root
    - group: root
    - mode: 755
    - require:
      - pkg: iproute2
