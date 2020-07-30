#!/usr/bin/env python3
#
# Copyright (c) 2020 Dataline LLC
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

"""
Obtain IPv4 addresses from domains blacklisted in the UA and output them to standard output in a format suitable for ExaBGP.
Also filters IPs from Google, Amazon, Cloudflare IP pools.

Kostiantyn Astakhov me@lvfrfn.in.ua
"""

import argparse
import dns.resolver
import ipaddress
import re
import requests
import sys
import time

url_cloudflare = 'https://www.cloudflare.com/ips-v4'
url_amazon = 'https://ip-ranges.amazonaws.com/ip-ranges.json'
url_google = ['_netblocks.google.com', '_netblocks2.google.com', '_netblocks3.google.com', '_netblocks4.google.com']

url_uablacklist = 'https://uablacklist.net/ips.json'

def generate_allow_list():
    whitelist_ip = requests.get(url_cloudflare).text.rstrip('\n').split('\n')

    for block in requests.get(url_amazon).json()['prefixes']:
        whitelist_ip.append(block['ip_prefix'])

    for url in url_google:
        answer = dns.resolver.resolve(url, 'TXT')
        for rdata in answer:
            for txt_string in rdata.strings:
                tmp = txt_string.decode('UTF-8').split()[1:]
                for item in tmp:
                    if item.startswith('ip4'):
                        whitelist_ip.append(item[4:])

    return whitelist_ip

def generate_block_list():
    block_ip = requests.get(url_uablacklist).json()
    return block_ip

def generate_announce_list(allow_list, block_list):
    ip_list = []
    for ip in block_list:
        passed = False
        ipv4 = ipaddress.ip_address(ip)
        if ipv4.is_global:
            for subnet in allow_list:
                pass_subnet = ipaddress.ip_network(subnet)
                if ipv4 in pass_subnet:
                    passed = True
                    break
            if passed:
                continue
            else:
                ip_list.append(str(ipv4))
    return ip_list

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--community", dest='community', type=str, default="", help="community to be attached to announced prefixes, defaults to no community")
    parser.add_argument("--interval", dest='interval', type=int, default=1, help="polling interval in hours, defaults to 1 hour")
    parser.add_argument("--next-hop", dest='next_hop', type=str, default='self', help="next-hop address that will be announce, default self")
    args = parser.parse_args()

    current_prefixes = set()
    community = ""
    next_hop = 'self'    

    if args.community is not "":
        if re.match("[0-9]+:[0-9]+", args.community):
            community = "community %s" % args.community
        else:
            sys.stderr.write("error: invalid community string\n")
            sys.exit(1)

    if args.next_hop is not "self":
       try:
            ipaddress.ip_address(args.next_hop)
            next_hop = args.next_hop
       except ValueError:
            sys.stderr.write("error: invalid next-hop string\n")
            sys.exit(1) 

    while True:
        requested_prefixes = set(generate_announce_list(generate_allow_list(),generate_block_list()))

        for prefix in current_prefixes - requested_prefixes: 
            sys.stdout.write("withdraw route %s/32 next-hop %s %s\n" % (prefix, next_hop, community))

        for prefix in requested_prefixes - current_prefixes: 
            sys.stdout.write("announce route %s/32 next-hop %s %s\n" % (prefix, next_hop, community))

        if prefix is not None:
            sys.stdout.flush()
            current_prefixes = requested_prefixes

        time.sleep(3600 * args.interval)
