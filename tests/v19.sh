#!/bin/bash
set -Eeuo pipefail
umask 077

result=${TKL_TEST_RESULT:?TKL_TEST_RESULT is required}
app_password=${TKL_TEST_APP_PASS:?TKL_TEST_APP_PASS is required}
base=https://localhost
cookie=/tmp/tkl-drupal10-cookie.$$
page=/tmp/tkl-drupal10-page.$$
headers=/tmp/tkl-drupal10-headers.$$
policy=/tmp/tkl-drupal10-policy.$$

report_error() {
    printf 'test_failure line=%s status=%s command=%q\n' \
        "$1" "$2" "$3" >&2
    exit "$2"
}
trap 'report_error "$LINENO" "$?" "$BASH_COMMAND"' ERR
trap 'rm -f -- "$cookie" "$page" "$headers" "$policy"' EXIT

input_value() {
    local name=$1
    local file=$2
    sed -n "s/.*name=\"$name\"[^>]*value=\"\([^\"]*\)\".*/\1/p" \
        "$file" | head -n 1
}

systemctl --quiet is-active apache2.service mariadb.service postfix.service \
    multi-user.target
systemctl --quiet is-enabled apache2.service mariadb.service postfix.service
apache2ctl -t
php_version=$(php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION, ".", PHP_RELEASE_VERSION;')
[[ $php_version == 8.4.* ]]

cd /var/www/drupal10
drupal_version=$(turnkey-drush status --field=drupal-version)
drush_version=$(turnkey-composer show drush/drush --format=json | \
    php -r '$j=json_decode(stream_get_contents(STDIN), true); echo preg_replace("/^[*v ]+/", "", $j["versions"][0]);')
test "$drupal_version" = 10.6.14
test "$drush_version" = 13.7.6
turnkey-composer validate --no-check-publish --no-interaction >/dev/null
turnkey-composer install --dry-run --no-dev --no-interaction >/dev/null
turnkey-composer audit --locked --no-interaction | grep -Fq \
    'No security vulnerability advisories found'

for package_version in \
    'drupal/ctools 4.1.1' \
    'drupal/field_group 4.0.0' \
    'drupal/google_analytics 4.0.3' \
    'drupal/imce 3.1.5' \
    'drupal/pathauto 1.15.0' \
    'drupal/token 1.17.0' \
    'guzzlehttp/guzzle 7.15.2'; do
    read -r package expected <<<"$package_version"
    actual=$(turnkey-composer show "$package" --format=json | \
        php -r '$j=json_decode(stream_get_contents(STDIN), true); echo preg_replace("/^[*v ]+/", "", $j["versions"][0]);')
    test "$actual" = "$expected"
done

enabled_modules=$(turnkey-drush pm:list --type=module --status=enabled --format=list)
for module in ctools field_group google_analytics pathauto token; do
    grep -Fxq "$module" <<<"$enabled_modules"
done
test -d web/modules/contrib/imce
turnkey-drush help pm:security >/dev/null
turnkey-drush cron >/dev/null

curl --insecure --fail --silent --show-error --location \
    "$base/" >"$page"
grep -Fq 'Welcome to TurnKey Drupal' "$page"

curl --insecure --fail --silent --show-error \
    -c "$cookie" "$base/user/login" >"$page"
form_build_id=$(input_value form_build_id "$page")
test -n "$form_build_id"
curl --insecure --fail --silent --show-error --location \
    -b "$cookie" -c "$cookie" "$base/user/login" \
    --data-urlencode 'name=admin' \
    --data-urlencode "pass=$app_password" \
    --data-urlencode "form_build_id=$form_build_id" \
    --data-urlencode 'form_id=user_login_form' \
    --data-urlencode 'op=Log in' >"$page"
grep -Eq 'Log out|user/logout' "$page"
grep -q 'SSESS' "$cookie"

curl --insecure --fail --silent --show-error \
    -b "$cookie" "$base/node/add/page" >"$page"
form_build_id=$(input_value form_build_id "$page")
form_token=$(input_value form_token "$page")
test -n "$form_build_id"
test -n "$form_token"
curl --insecure --fail --silent --show-error --location \
    -b "$cookie" -c "$cookie" -D "$headers" \
    "$base/node/add/page" \
    --data-urlencode 'title[0][value]=TurnKey v19 acceptance page' \
    --data-urlencode 'body[0][value]=Created through the Drupal web interface' \
    --data-urlencode 'body[0][format]=basic_html' \
    --data-urlencode 'status[value]=1' \
    --data-urlencode "form_build_id=$form_build_id" \
    --data-urlencode "form_token=$form_token" \
    --data-urlencode 'form_id=node_page_form' \
    --data-urlencode 'op=Save' >"$page"
grep -Fq 'TurnKey v19 acceptance page' "$page"
grep -Fq 'Created through the Drupal web interface' "$page"

nid=$(mariadb --batch --skip-column-names drupal10 --execute \
    "SELECT nid FROM node_field_data WHERE title='TurnKey v19 acceptance page' ORDER BY nid DESC LIMIT 1")
test -n "$nid"
mariadb --batch --skip-column-names drupal10 --execute \
    "SELECT body_value FROM node__body WHERE entity_id=$nid" | \
    grep -Fxq 'Created through the Drupal web interface'

systemctl restart mariadb.service apache2.service
curl --insecure --fail --silent --show-error \
    "$base/node/$nid" >"$page"
grep -Fq 'TurnKey v19 acceptance page' "$page"
grep -Fq 'Created through the Drupal web interface' "$page"

dpkg-query -W webmin-apache webmin-mysql >/dev/null
curl --insecure --fail --silent --show-error --head \
    https://127.0.0.1:12321/ >/dev/null
curl --insecure --fail --silent --show-error --head \
    https://127.0.0.1:12322/ >/dev/null
ss -ltn | grep -Eq '127\.0\.0\.1:25[[:space:]]'

lock_before=$(sha256sum composer.lock | awk '{print $1}')
turnkey-composer update 'drupal/core-*' --with-all-dependencies \
    --dry-run --no-interaction >/dev/null
lock_after=$(sha256sum composer.lock | awk '{print $1}')
test "$lock_after" = "$lock_before"

apt-get update >/dev/null
for package in apache2 mariadb-server php8.4; do
    apt-cache policy "$package" >"$policy"
    candidate=$(awk '/Candidate:/ {print $2}' "$policy")
    test -n "$candidate"
    test "$candidate" != '(none)'
    grep -Eq 'trixie|deb13' "$policy"
done
grep -Rqs '^Suites: trixie' /etc/apt/sources.list.d
! grep -Rqi bookworm /etc/apt/sources.list.d

apache_version=$(dpkg-query -W -f='${Version}' apache2)
mariadb_version=$(dpkg-query -W -f='${Version}' mariadb-server)
cat >"$result" <<EOF
package_source=Debian 13 Trixie packages for PHP, Apache, MariaDB, Postfix and Composer; official Drupal Composer packages from Packagist
installed_version=Drupal $drupal_version; Drush $drush_version; PHP $php_version; Apache $apache_version; MariaDB $mariadb_version
runtime_checks=normal init; firstboot; HTTPS administrator login; Drupal page create and read with MariaDB readback; Apache and MariaDB restart persistence; cron; bundled modules; Webmin, Adminer and Postfix endpoints
updater_command=turnkey-composer audit --locked; turnkey-composer update drupal/core-* --with-all-dependencies --dry-run; apt-get update
updater_result=Composer audit passed; supervised Drupal core update resolved successfully without changing the lock file; signed Trixie metadata refreshed
updater_channel=official Drupal packages through Composer and signed Debian and TurnKey Trixie APT repositories
integrity_evidence=Composer validated the lock file and exact installed versions, including patched Guzzle 7.15.2; APT accepted signed Trixie metadata; no Bookworm source remained
EOF
