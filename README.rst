Drupal 9 - Content Management Framework
=======================================

`Drupal`_ is an open source content management platform licensed under
the GPL. Equipped with a powerful blend of features, Drupal can support
a variety of websites ranging from personal blogs, corporate brochures
and large community-driven websites.

This appliance includes all the standard features in `TurnKey Core`_,
and on top of that:

- Drupal 9 configurations:
   
   - Installed (using composer) from upstream source code to /var/www/drupal9

     **Security note**: Updates to Drupal may require supervision so
     they **ARE NOT** configured to install automatically. See below for
     updating Drupal. And/or see `Drupal 8 documentation`_

   - Includes drush and composer for command line administration and
     configuration.

   - Drupal security update alerts delivered to your inbox - requires
     `Security Alerts`_ ('secalerts') be enabled on firstboot with a valid
     email address.

   - **Note** - For trouble free commandline usage (i.e. Composer or Drush)
     PHP RAM limit may need to be bumped to 2048MB. For that to work, the
     system requires at least 2GB+ free memory (physical &/or virtual; i.e.
     swap - a temporary swap file is acceptable).

- Bundled Drupal 9 modules and dependencies (installed to 
  /var/www/drupal9/web/modules - new default for Drupal9):

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
UI:: **Admin > Reports > Avaialble Updates**

Updates for Drupal9 Core often need to be done via commandline. For full
details, please consult the `Drupal8 Upgrade docs`_, we recommend using
`Composer to update from the commandline`_::

    cd /var/www/drupal9
    # update composer - not strictly neccessary
    composer self-update
    composer update drupal/core webflo/drupal-core-require-dev --with-dependencies
    drush updatedb -y
    drush cr

Modules can be updated like this, e.g. ctools::

    composer update drupal/ctools
    drush updatedb -y
    drush cr

We also recommend that you  subscribe to the drupal.org security
newsletter (create a user account on drupal.org and within your drupal.org
profile:: **Edit > My newsletter** tab).

Notes on documentation
----------------------

The links here relevant to documentation all link to drupal 8
documentation, this is not an accident but rather due to the fact that
as of writing there are no drupal 9 documentation specifically. This
AFAIK is partially (or wholly perhaps) due to the fact that the
changes between drupal 8 and 9 are rather small, and mostly not apparent
on the surface. As such the documentation for drupal 8 should largely
suffice.


Credentials *(passwords set at first boot)*
-------------------------------------------

-  Webmin, SSH, MySQL: username **root**
-  Adminer: username **adminer**
-  Drupal 9: username **admin**

.. _Drupal: https://drupal.org
.. _TurnKey Core: https://www.turnkeylinux.org/core
.. _Security Alerts: https://www.turnkeylinux.org/docs/automatic-security-alerts
.. _Drupal 8 documentation: https://www.drupal.org/docs/8/update
.. _Field group: https://www.drupal.org/project/field_group
.. _Google analytics: https://www.drupal.org/project/google_analytics
.. _Honeypot: https://www.drupal.org/project/honeypot
.. _Imce: https://drupal.org/project/imce
.. _PathAuto: https://drupal.org/project/pathauto
.. _Token: https://drupal.org/project/token
.. _Adminer: https://www.adminer.org
.. _Drupal8 Upgrade docs: https://www.drupal.org/docs/8/update
.. _Composer to update from the commandline: https://www.drupal.org/docs/8/update/update-core-via-composer
