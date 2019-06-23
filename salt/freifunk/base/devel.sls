{# Packages for compilling - bmxd / fastd #}
devel:
  pkg.installed:
    - refresh: True
    - names:
      - build-essential
      - nodejs
      - zlib1g-dev
      - liblzo2-dev
      - libssl-dev
      - bison
      - flex
      - zlibc
      - libjson-c-dev
      - pkg-config
      - cmake
{% if grains['os'] == 'Ubuntu' and grains['osrelease'] == '18.04' %}
      - libcurl4
{% elif grains['os'] == 'Debian' and grains['osrelease'] == 'buster' %}
      - libcurl4
{% else %}
      - libcurl3
{% endif %}
