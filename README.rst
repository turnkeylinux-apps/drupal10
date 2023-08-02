Drupal 9 - Content Management Framework
=======================================

`Drupal`_ is an open source content management platform licensed under
the GPL. Equipped with a powerful blend of features, Drupal can support
a variety of websites ranging from personal blogs, corporate brochures
and large community-driven websites.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Drupal 9 configurations:
   
   - Installed (using composer_) from upstream source code to /var/www/drupal10.
     As of v16.1, doc root is owned by www-data (webserver user). This new
     default eases management (especially with tools such as the turnkey script
     wrappers) but also has potential security implications.

     **Security note**: Updates to Drupal may require supervision so
     they **ARE NOT** configured to install automatically. See below for
     updating Drupal. And/or see `Drupal 8 documentation`_

   - Includes drush_, drupal-console_ and composer_ for command line
     administration, configuration and development. Also includes relevant
     wrapper scripts; turnkey-drush_, turnkey-drupal_ & turnkey-composer_ (run
     the relevant command, but as www-data user).

   - Drupal security update alerts delivered to your inbox - requires
     `Security Alerts`_ ('secalerts') be enabled on firstboot with a valid
     email address.

   - **Note** - For trouble free commandline usage (i.e. Composer or Drush)
     PHP RAM limit may need to be bumped to 2048MB. For that to work, the
     system requires at least 2GB+ free memory (physical &/or virtual; i.e.
     swap - a temporary swap file is acceptable).

- Bundled Drupal 9 modules and dependencies (installed to 
  /var/www/drupal10/web/modules - new default for Drupal10):

   - `Field group`_: Allows fields to be grouped together.
   - `Google analytics`_: Adds Google Analytics js tracking code to all
     your site's pages.
   - `Honeypot`_: A honeypot for deterring spam bots from completing
     forms on your site  (additionally uses timestamp method).
   - `Imce`_: Powerful image file uploader and browser, with support for
     on the fly resizing.
   - `PathAuto`_: Auto-generate search engine friendly URLs (SEO).
   - `Token`_: Provides a shared API for replacement of textual
     placeholders with actual data.

   Note: Only some modules are enabled by default. To enable/disable 
     modules, navigate to **Administer > Modules** (or
     http://example.com/admin/modules). Some modules may require
     additional configuration and/or permissions settings.

- SSL support out of the box.
- `Adminer`_ administration frontend for MySQL (listening on port
  12322 - uses SSL).
- Postfix MTA (bound to localhost) to allow sending of email (e.g.,
  password recovery).
- Webmin modules for configuring Apache2, PHP, MySQL and Postfix.

Supervised Manual Drupal Update
-------------------------------

It is possible to check for and install updates from the Drupal Admin
UI:: **Admin > Reports > Available Updates**

Updates for Drupal10 Core often need to be done via commandline. For full
details, please consult the `Drupal Upgrade docs`_, we recommend using
`Composer to update from the commandline`_ (via turnkey-composer_)::

    cd /var/www/drupal10
    # update composer - not strictly necessary
    composer self-update
    turnkey-composer update drupal/core --with-dependencies
    turnkey-drush updatedb -y
    turnkey-drush cr

Modules can be updated like this, e.g. ctools::

    turnkey-composer update drupal/ctools
    turnkey-drush updatedb -y
    turnkey-drush cr

We also recommend that you  subscribe to the drupal.org security
newsletter (create a user account on drupal.org and within your drupal.org
profile:: **Edit > My newsletter** tab).


Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL: username **root**
-  Adminer: username **adminer**
-  Drupal 9: username **admin**

.. _Drupal: https://drupal.org
.. _TurnKey Core: https://www.turnkeylinux.org/core
.. _composer: https://getcomposer.org/
.. _drush: https://www.drush.org/
.. _drupal-console: https://drupalconsole.com/
.. _turnkey-drush: https://github.com/turnkeylinux-apps/drupal9/blob/master/overlay/usr/local/bin/turnkey-drush
.. _turnkey-drupal: https://github.com/turnkeylinux-apps/drupal9/blob/master/overlay/usr/local/bin/turnkey-drupal
.. _turnkey-composer: https://github.com/turnkeylinux/common/blob/master/overlays/composer/usr/local/bin/turnkey-composer
.. _Security Alerts: https://www.turnkeylinux.org/docs/automatic-security-alerts
.. _Drupal 8 documentation: https://www.drupal.org/docs/8/update
.. _Field group: https://www.drupal.org/project/field_group
.. _Google analytics: https://www.drupal.org/project/google_analytics
.. _Honeypot: https://www.drupal.org/project/honeypot
.. _Imce: https://drupal.org/project/imce
.. _PathAuto: https://drupal.org/project/pathauto
.. _Token: https://drupal.org/project/token
.. _Adminer: https://www.adminer.org
.. _Drupal Upgrade docs: https://www.drupal.org/docs/updating-drupal
.. _Composer to update from the commandline: https://www.drupal.org/docs/updating-drupal/updating-drupal-core-via-composer
