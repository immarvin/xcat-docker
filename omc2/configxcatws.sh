#!/usr/bin/bash
RESTCFG="/usr/lib/python2.7/site-packages/openstack_dashboard/local/local_settings.py"
[ -n "$XCATMN" ] && sed -i "s/XCAT_API_URL = .*/XCAT_API_URL = \"https:\/\/$XCATMN\/xcatws\"/" $RESTCFG

exit 0
