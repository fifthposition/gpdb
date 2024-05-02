---
title: Installing gpMLBot
---

The VMware Greenplum Automated Machine Learning Agent (gpMLBot) provides a conversational interface to guide users in leveraging Apache MADlib and PostgresML for automatic data processing, hyperparameter optimization, and model management.

## Prerequisites

To install gpMLBot, you will need:

* The Data Science bundle, to enable PostgresML. For information about installing the Data Science bundle, see [Before Registering the postgresml Module](../ref_guide/modules/postgresml.html#prereqs) in _postgresml_.

* A `gpmlbot` database, which will be used internally to store trained models.

    To create the database:

    ```
    $ createdb gpmlbot
    ```

* MADlib and PostgresML installed on any additional user databases.

    To install MADlib and PostgresML:

    ```
    $ madpack -p greenplum -c /gpmlbot install
    $ psql --dbname=gpmlbot -c "CREATE EXTENSION IF NOT EXISTS pgml;"
    ```

1. A `gpmlbot` user record in the `pg_hba.conf` file.

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

To install gpMLBot:

1. Install the gpmlbot utility to the default or a user-defined location.

    To install to the default `/usr/local/bin/` location on all hosts, use the `yum` command with `sudo` (or as `root`):

    ```
    $ sudo yum install gpugrade-<version>.el7.x86_64.rpm
    ```

    Alternatively, install the `gpmlbot` utility to a user-specified location:

    ```
    $ sudo rpm  --prefix=<USER_DIRECTORY> -ivh gpmlbot-<version>.el7.x86_64.rpm
    ```

1. Add the `gpmlbot` binaries to the user's executable path:

    ```
    $ export PATH=<USER_DIRECTORY>:$PATH
    ```

1. Change the owner and group of the installed files to `gpadmin`:

    ```
    $ sudo chown -R gpadmin:gpadmin <USER_DIRECTORY>/greenplum/gpmlbot/*
    ```
