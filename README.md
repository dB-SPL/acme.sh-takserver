# acme.sh-takserver: Automate TAK Server Certificates with acme.sh
************************************

acme.sh is an ACME protocol client used for TLS certificate issuance and automated
renewal.  You can find out more at https://github.com/acmesh-official/acme.sh/

This script enables acme.sh to deploy updated certificats to TAK Server's JKS Java
keystore file and restart TAK Server.

To install the script, simply download the ``takserver.sh`` file, and place it in your
``.acme.sh/deploy/`` folder.

Generate your certificate using the ACME provider of your choice.  You can see the list
of CAs that support the ACME protocol on the acme.sh GitHub page.  The command might
look like this:

``acme.sh --standalone --issue -d <your-domain.com>``

By default, the certificate and key are placed in the ``.acme.sh/<your-domain.com>``.
Install the new certificate into a Java keystore as described in this guide:

https://mytecknet.com/lets-sign-our-tak-server/#using-lets-encrypt

When using the guide, substitute the file locations above for the ``certbot`` location
of ``/etc/letsencrypt/live/<your-domain.com>``.

By default, the script deploys certs to a Java keystore file named
``acme-<your-domain.com>.jks`` in the ``/opt/tak/certs/files/`` folder using the alias
``<your-domain.com>``.  You can customize the keystore file name and alias by adding
those variables to the acme.sh's conf file for your domain.  See the comments in
``takserver.sh`` for more information.
