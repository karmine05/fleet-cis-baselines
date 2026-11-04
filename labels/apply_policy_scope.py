#!/usr/bin/env python3
"""Scope Fleet policies to the labels in the catalogs.

Reads windows/, macos/ and ubuntu/catalog.csv and sets each policy's labels_include_any to
the catalog's scope_label. Policies are matched by name, so policy IDs do not matter.

Dry run by default: it prints what would change. Pass --apply to write.

  export FLEET_URL=https://fleet.example.com
  export FLEET_API_TOKEN=...            # or FLEET_TOKEN_FILE=~/fleet.token
  export FLEET_CA_FILE=~/fleet-ca.pem   # only for a self-signed Fleet server
  ./apply_policy_scope.py --team-id 1 [--apply]

Create the labels first (labels.yml). A policy whose label does not exist in Fleet is skipped.
"""
import argparse, csv, json, os, ssl, sys, urllib.parse, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOGS = ("windows/catalog.csv", "macos/catalog.csv", "ubuntu/catalog.csv")


def token():
    if os.environ.get("FLEET_API_TOKEN"):
        return os.environ["FLEET_API_TOKEN"].strip()
    return open(os.path.expanduser(os.environ["FLEET_TOKEN_FILE"])).read().strip()


def api(method, path, body=None):
    url = os.environ["FLEET_URL"].rstrip("/") + "/api/latest/fleet" + path
    req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    ca = os.environ.get("FLEET_CA_FILE")
    ctx = ssl.create_default_context(cafile=os.path.expanduser(ca)) if ca else None  # TLS is always verified
    with urllib.request.urlopen(req, context=ctx) as r:
        return json.load(r) if r.status != 204 else {}


def wanted():
    """policy name -> label name, from all catalogs."""
    out = {}
    for rel in CATALOGS:
        for row in csv.DictReader(open(os.path.join(ROOT, rel), newline="")):
            if row.get("scope_label"):
                out[row["policy_name"]] = row["scope_label"]
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--team-id", type=int, required=True, help="Fleet team that holds the policies")
    ap.add_argument("--apply", action="store_true", help="write the changes (default: dry run)")
    a = ap.parse_args()

    labels = {l["name"] for l in api("GET", "/labels")["labels"]}
    policies = api("GET", f"/teams/{a.team_id}/policies?" + urllib.parse.urlencode({"per_page": 5000}))["policies"]
    want = wanted()
    changes = skipped = 0
    for p in policies:
        label = want.get(p["name"])
        if not label:
            continue
        if label not in labels:
            skipped += 1
            print(f"skip: label not in Fleet: {label!r} ({p['name']})")
            continue
        have = sorted(l["name"] for l in (p.get("labels_include_any") or []))
        if have == [label]:
            continue
        changes += 1
        print(f"{'set' if a.apply else 'would set'} {p['name']!r}: {have} -> [{label!r}]")
        if a.apply:
            api("PATCH", f"/teams/{a.team_id}/policies/{p['id']}", {"labels_include_any": [label]})
    print(f"{changes} policies {'updated' if a.apply else 'would change'}, {skipped} skipped")


if __name__ == "__main__":
    sys.exit(main())
