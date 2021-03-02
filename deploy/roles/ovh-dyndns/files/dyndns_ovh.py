#!/usr/bin/env python3
import json
import ovh
import logging
from requests import get

from configparser import ConfigParser


logging.basicConfig(level=logging.INFO)
parser = ConfigParser()

# Hack to get ovh config parameters from let's encrypt config file
# Certbot needs a flat ini file without section while ConfigParser requires at least one section
# https://stackoverflow.com/questions/2885190/using-configparser-to-read-a-file-without-section-name
with open("/etc/letsencrypt/certbot_ovh.ini") as stream:
    parser.read_string("[hack]\n" + stream.read())

ZONE = "hackervaillant.eu"
SUBDOMAINS = ["blog", "zenikanard"]

# OVH API credentials used by Certbot

conf = {
    "endpoint": parser.get("hack", "dns_ovh_endpoint"),
    "application_key": parser.get("hack", "dns_ovh_application_key"),
    "application_secret": parser.get("hack", "dns_ovh_application_secret"),
    "consumer_key": parser.get("hack", "dns_ovh_consumer_key"),
}

client = ovh.Client(**conf)

logging.info("get public ip")
ip_response = get("https://api.ipify.org")
ip_response.raise_for_status()

ip = ip_response.text
logging.info(f"public ip is {ip}")

for SUBDOMAIN in SUBDOMAINS:
    logging.info(f"get {SUBDOMAIN}.{ZONE} recordID from ovh API")
    recordList = client.get(
        f"/domain/zone/{ZONE}/record",
        fieldType="A",
        subDomain=f"{SUBDOMAIN}",
    )

    if len(recordList) == 0:
        logging.info(f"didn't find a record for {SUBDOMAIN}.{ZONE} - create record")
        result = client.post(
            f"/domain/zone/{ZONE}/record",
            fieldType="A",
            subDomain=SUBDOMAIN,
            target=ip,
            ttl=60,
        )
        logging.info(f'{SUBDOMAIN}.{ZONE} set to {result["target"]}')
        result = client.post(f"/domain/zone/{ZONE}/refresh")
        continue

    recordID = recordList[0]

    logging.info(f"get {SUBDOMAIN}.{ZONE} record from ovh API")
    record = client.get(f"/domain/zone/{ZONE}/record/{recordID}")

    if record["target"] != ip:
        logging.info(
            f'dns ip ({record["target"]}) differ from current public ip ({ip}) - update record'
        )
        createdRecord = client.put(f"/domain/zone/{ZONE}/record/{recordID}", target=ip)
        result = client.post(f"/domain/zone/{ZONE}/refresh")
    else:
        logging.info(f"{ip} is already set for {SUBDOMAIN}.{ZONE}")
