#!/usr/bin/env python3
"""Add email addresses to Thunderbird's remote-content sender allow list.

Thunderbird must be closed: it holds permissions in memory and rewrites
permissions.sqlite on exit.

Addresses come from a Thunderbird address book (--addressbook) or a
file/stdin (plain list or a CSV/LDIF address book export).

  tb-allow-senders.py --addressbook "Company Directory" --dry-run
  tb-allow-senders.py --addressbook "Company Directory" --domain example.com --domain example.org
  tb-allow-senders.py addresses.txt
"""
import argparse
import configparser
import re
import shutil
import sqlite3
import sys
import time
from pathlib import Path

ORIGIN_PREFIX = "chrome://messenger/content/email="
PERM_TYPE = "image"  # Thunderbird's remote-content permission type
ALLOW = 1


def find_profile() -> Path:
    for root in (Path.home() / ".thunderbird",
                 Path.home() / "Library/Thunderbird",
                 Path.home() / ".var/app/org.mozilla.Thunderbird/.thunderbird"):
        ini = root / "profiles.ini"
        if not ini.exists():
            continue
        cp = configparser.ConfigParser()
        cp.read(ini)
        # [Install...] Default= is the profile Thunderbird actually launches.
        for sec in cp.sections():
            if sec.startswith("Install") and cp.has_option(sec, "Default"):
                return root / cp.get(sec, "Default")
        for sec in cp.sections():
            if cp.get(sec, "Default", fallback="0") == "1" and cp.has_option(sec, "Path"):
                p = cp.get(sec, "Path")
                return root / p if cp.get(sec, "IsRelative", fallback="1") == "1" else Path(p)
    sys.exit("Couldn't find a Thunderbird profile; pass --profile")


def addressbook_emails(profile: Path, name: str) -> list[str]:
    # prefs.js maps each address book's display name to its SQLite file:
    #   user_pref("ldap_2.servers.X.description", "Company Directory");
    #   user_pref("ldap_2.servers.X.filename", "abook-1.sqlite");
    prefs = {}
    for m in re.finditer(r'user_pref\("ldap_2\.servers\.([^.]+)\.(\w+)",\s*"((?:[^"\\]|\\.)*)"\);',
                         (profile / "prefs.js").read_text()):
        prefs.setdefault(m[1], {})[m[2]] = m[3]
    books = {v["description"]: v for v in prefs.values() if "description" in v}
    book = books.get(name)
    if not book:
        sys.exit(f"No address book named {name!r}. Found: {', '.join(sorted(books))}")
    if not book.get("filename") or not (profile / book["filename"]).exists():
        sys.exit(f"{name!r} has no local copy ({book.get('uri', '?')}). If it's LDAP, enable "
                 "offline use: Address Book > right-click it > Properties > Offline > Download Now")
    db = sqlite3.connect(f"file:{profile / book['filename']}?mode=ro", uri=True)
    emails = [r[0] for r in db.execute(
        "SELECT value FROM properties WHERE name IN ('PrimaryEmail', 'SecondEmail')")]
    # Newer Thunderbird keeps the full vCard too; pick up any extra EMAIL lines.
    for (vcard,) in db.execute("SELECT value FROM properties WHERE name = '_vCard'"):
        emails += re.findall(r"^EMAIL[^:]*:(.+?)\r?$", vcard, re.M | re.I)
    return emails


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file", nargs="?", help="address list or CSV/LDIF export (default stdin)")
    ap.add_argument("--addressbook", metavar="NAME", help="pull from this Thunderbird address book")
    ap.add_argument("--domain", action="append", default=[],
                    help="only keep addresses at this domain (repeatable)")
    ap.add_argument("--profile", type=Path)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    profile = args.profile or find_profile()
    if args.addressbook:
        raw = addressbook_emails(profile, args.addressbook)
    else:
        src = open(args.file) if args.file else sys.stdin
        # Accepts a plain list or a raw CSV/LDIF export: grab anything address-shaped.
        raw = re.findall(r"[\w.+'-]+@[\w-]+(?:\.[\w-]+)+", src.read())
    emails = sorted({e.strip().lower() for e in raw if "@" in e})
    if args.domain:
        doms = {d.lower().lstrip("@") for d in args.domain}
        emails = [e for e in emails if e.rsplit("@", 1)[1] in doms]
    if not emails:
        sys.exit("No addresses to add")

    if (profile / "lock").exists() or (profile / ".parentlock").exists():
        # .parentlock lingers after exit on Linux, so only warn.
        print("warning: lock file present — make sure Thunderbird is closed", file=sys.stderr)
    db_path = profile / "permissions.sqlite"
    if not db_path.exists():
        sys.exit(f"{db_path} not found (start Thunderbird once to create it)")

    db = sqlite3.connect(db_path)
    existing = {row[0] for row in db.execute(
        "SELECT origin FROM moz_perms WHERE type = ?", (PERM_TYPE,))}
    new = [e for e in emails if ORIGIN_PREFIX + e not in existing]
    print(f"{len(emails)} addresses, {len(emails) - len(new)} already allowed, {len(new)} to add")
    if args.dry_run or not new:
        for e in new:
            print("  +", e)
        return

    backup = db_path.with_suffix(f".sqlite.bak-{int(time.time())}")
    shutil.copy2(db_path, backup)
    now = int(time.time() * 1000)
    with db:
        db.executemany(
            "INSERT INTO moz_perms (origin, type, permission, expireType, expireTime, modificationTime)"
            " VALUES (?, ?, ?, 0, 0, ?)",
            [(ORIGIN_PREFIX + e, PERM_TYPE, ALLOW, now) for e in new])
    print(f"Added {len(new)}. Backup: {backup}")


if __name__ == "__main__":
    main()
