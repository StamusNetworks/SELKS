#! /bin/sh

echo "Updating Suricata rules from Scirius"
docker exec scirius python /opt/scirius/manage.py updatesuricata && echo "done." || echo "ERROR"
