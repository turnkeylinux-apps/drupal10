#!/usr/bin/python3
"""Set Drupal10 admin password, email and domain to serve

Option:
    --pass=     unless provided, will ask interactively
    --email=    unless provided, will ask interactively
    --domain=   unless provided, will ask interactively
                DEFAULT=www.example.com
"""

import sys
import getopt
from libinithooks import inithooks_cache
import time
import shutil
import os
from pwd import getpwnam
from grp import getgrnam

from libinithooks.dialog_wrapper import Dialog
from mysqlconf import MySQL

import subprocess

def usage(s=None):
    if s:
        print("Error:", s, file=sys.stderr)
    print("Syntax: %s [options]" % sys.argv[0], file=sys.stderr)
    print(__doc__, file=sys.stderr)
    sys.exit(1)

DEFAULT_DOMAIN="www.example.com"

def main():
    try:
        opts, args = getopt.gnu_getopt(sys.argv[1:], "h",
                                       ['help', 'pass=', 'email=', 'domain='])
    except getopt.GetoptError as e:
        usage(e)

    password = ""
    email = ""
    domain = ""
    for opt, val in opts:
        if opt in ('-h', '--help'):
            usage()
        elif opt == '--pass':
            password = val
        elif opt == '--email':
            email = val
        elif opt == '--domain':
            domain = val

    if not password:
        d = Dialog('TurnKey Linux - First boot configuration')
        password = d.get_password(
            "Drupal10 Password",
            "Enter new password for the Drupal10 'admin' account.")

    if not email:
        if 'd' not in locals():
            d = Dialog('TurnKey Linux - First boot configuration')

        email = d.get_email(
            "Drupal10 Email",
            "Enter email address for the Drupal10 'admin' account.",

            "admin@example.com")

    inithooks_cache.write('APP_EMAIL', email)

    if not domain:
        if 'd' not in locals():
            d = Dialog('TurnKey Linux - First boot configuration')

        domain = d.get_input(
            "Drupal10 Domain",
            "Enter the domain to serve Drupal10.",
            DEFAULT_DOMAIN)

    if domain == "DEFAULT":
        domain = DEFAULT_DOMAIN

    inithooks_cache.write('APP_DOMAIN', domain)

    m = MySQL()
    m.execute('UPDATE drupal10.users_field_data SET mail=%s WHERE name=\"admin\";', (email,))
    m.execute('UPDATE drupal10.users_field_data SET init=%s WHERE name=\"admin\";', (email,))
    subprocess.run(['turnkey-drush', '-y', 'config-set', 'contact.form.feedback', 'recipients', email])
    subprocess.run(['turnkey-drush', '-y', 'config-set', 'update.settings', 'notification.emails.0', email])
    subprocess.run(['turnkey-drush', '-y', 'config-set', 'system.site', 'mail', email])
    subprocess.run(['turnkey-drush', 'user-password', 'admin', password])
    conf = '/var/www/drupal10/web/sites/default/settings.php'
    conf_tmp = f'{conf}.tmp'
    shutil.move(conf, conf_tmp)
    domain = domain.replace('.', r'\.')
    with open(conf_tmp) as fob_tmp:
        with open(conf, 'w') as fob:
            for line in fob_tmp:
                if line.startswith("$settings['trusted_host_patterns']"):
                    if line.endswith(';\n'):
                        line = f"$settings['trusted_host_patterns'] = ['^{domain}$'];\n"
                    else:
                        print(f"Expected trusted_host_patterns line not found in {conf}",
                              file=sys.stderr)
                        shutil.move(conf_tmp, conf)
                        sys.exit(1)
                fob.write(line)
    os.remove(conf_tmp)
    # restore conf file default perms; i.e. owned by www-data:www-data and read-only
    uid = getpwnam('www-data').pw_uid
    gid = getgrnam('www-data').gr_gid
    os.chown(conf, uid, gid)
    os.chmod(conf, 0o444)
    print('Data updated; clearing caches')
    subprocess.run(['/etc/cron.hourly/drupal10'])

if __name__ == "__main__":
    main()
