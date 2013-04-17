# Using the installation scripts

1. Copy the scripts in this directory to the target machine and log in.

2. Execute the first script, plexus-server-setup, with root privileges:

   sudo ./plexus-server-setup

3. Assume the identity of the plexus1 user, created by the previous
script. You need to use the su command, as that account has no password:

   sudo su plexus1

4. Execute the second script:

   ./plexus-app-setup

5. Finally, execute the third script:

   ./plexus-app-installation

6. When a new version of the Plexus code is available, repeat only steps 3 and
5 to install it. Your existing data will be preserved.

7. In order to use or test Plexus from a browser or other web client, you will
need access to port 443 (the https port) of the target machine. Plexus does
not support unencrypted http traffic via port 80. Also note that if you use a
self-signed SSL certificate - which the installation script generates
automatically unless an existing certificate is found; see plexus-server-setup
for details - your browser will alert you to the fact that untrusted
certificate is being used. This is normal at this stage and no cause for
alarm, as long as you can ascertain by other means that you are indeed
connecting to the correct server.
