#!/bin/bash -e

while getopts e:p:d: option
    do
        case "${option}"
        in
        e) EMAIL="${OPTARG}";;
        p) PASSWORD="${OPTARG}";;
        d) DOMAIN="${OPTARG}";;
    esac
done

cd /var/www/drupal10
vendor/bin/drush -y config-set contact.form.feedback recipients "$EMAIL" &> /dev/null
vendor/bin/drush -y config-set update.settings notification.emails.0 "$EMAIL" &> /dev/null
vendor/bin/drush -y config-set system.site mail "$EMAIL" &> /dev/null
vendor/bin/drush user-password admin "$PASSWORD" &> /dev/null

# delete all trusted hosts
sed -i '/^\$settings\['\''trusted_host_patterns'\''\]/,/\]/{ /^\$settings\['\''trusted_host_patterns'\''\]/n;/\]/ !d}' '/var/www/drupal10/web/sites/default/settings.php'
# add trusted host
sed -i '/^\$settings\['\''trusted_host_patterns'\''\]/a\
'"'\\^$DOMAIN\\$'" '/var/www/drupal10/web/sites/default/settings.php'

vendor/bin/drush cache-rebuild &> /dev/null
