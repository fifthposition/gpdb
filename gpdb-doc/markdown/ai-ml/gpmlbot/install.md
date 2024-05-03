---
title: Installing gpMLBot
---

The VMware Greenplum Automated Machine Learning Agent (gpMLBot) provides a conversational interface to guide users in leveraging Apache MADlib and PostgresML for automatic data processing, hyperparameter optimization, and model management.

## Prerequisites

To install gpMLBot, you will need:

* The Python Data Science Package, to enable PostgresML. For information about installing the Data Science bundle, see [Before Registering the postgresml Module](../ref_guide/modules/postgresml.html#prereqs) in _postgresml_.

* A `gpmlbot` database, which will be used internally to store trained models.

    To create the database:

    ```
    $ createdb gpmlbot
    ```

* MADlib and PostgresML installed on the `gpmlbot` database and any additional user databases.

    To install MADlib and PostgresML on the `gpmlbot` database:

    ```
    $ madpack -p greenplum -c /gpmlbot install
    $ psql --dbname=gpmlbot -c "CREATE EXTENSION IF NOT EXISTS pgml;"
    ```

* A `gpmlbot` user record in the `pg_hba.conf` file.

    To add the `gpmlbot` user:

    1. Append the record line to the configuration file.

        ```
        $ echo -e 'host\tgpmlbot\tgpmlbot\tsamehost\ttrust' >> ${COORDINATOR_DATA_DIRECTORY}/pg_hba.conf
        ```

    1. If connecting remotely, add a record for the database user and its remote IP and hostname.

    1. Use the `gpstop` utility to reload your configuration file changes without shutting down the VMware Greenplum system:

        ```
        $ gpstop -u
        ```

## Installing

You can install gpMLBot in the default location, `/usr/local/bin/`, for all hosts. Alternatively, you can install to a custom location.

* To install to the default location on all hosts:

    1. Use the `yum` command with `sudo` (or as `root`).

        ```
        $ sudo yum install gpmlbot-<version>.el7.x86_64.rpm
        ```

    1. Change the owner and group of the installed files to `gpadmin`.

        ```
        $ sudo chown -R gpadmin:gpadmin /usr/local/bin/greenplum/*
        ```

* To install in a custom location:

    1. Use the `rpm` command with the `--prefix` option.

        ```
        $ sudo rpm  --prefix=<USER_DIRECTORY> -ivh gpmlbot-<version>.el7.x86_64.rpm
        ```

    1. Add the custom location to the user's executable path.

        ```
        $ export PATH=<USER_DIRECTORY>:$PATH
        ```

    1. Change the owner and group of the installed files to `gpadmin`.

        ```
        $ sudo chown -R gpadmin:gpadmin <USER_DIRECTORY>/greenplum/gpmlbot/*
        ```
