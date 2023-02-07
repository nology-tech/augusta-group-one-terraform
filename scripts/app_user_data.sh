Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
echo export DB_PATH=${mongodb_ip} >> /etc/profile
echo export NODE_ENV=prod >> /etc/profile

ex /etc/systemd/system/nodeapp.service <<eof                                                                                                                  
5 insert
Environment=NODE_ENV=prod
Environment=DB_PATH=${mongodb_ip}
.
xit
eof

systemctl daemon-reload
systemctl start nodeapp
systemctl enable nodeapp
systemctl status nodeapp
--//--