#!/bin/bash

echo "Wait for firstboot change to be ready"
while ! snap changes | grep -q "Done"; do
	snap changes || true
	snap change 1 || true
	sleep 1
done

echo "Ensure fundamental snaps are still present"
. $TESTSLIB/snap-names.sh
for name in $gadget_name $kernel_name $core_name; do
	if ! snap list | grep -q $name ; then
		echo "Not all fundamental snaps are available, all-snap image not valid"
		echo "Currently installed snaps:"
		snap list
		exit 1
	fi
done

echo "Kernel has a store revision"
snap list | grep ^${kernel_name} | grep -E " [0-9]+\s+canonical"

# If we don't install pulseaudio here we get a system
# without any network connectivity after reboot.
if [ -n "$SNAP_CHANNEL" ] ; then
	# Don't reinstall if we have it installed already
	if ! snap list | grep pulseaudio ; then
		snap install --$SNAP_CHANNEL pulseaudio
	fi
	echo "USING-CHANNEL"
else
	echo "INSTALLING-PULSEAUDIO-SNAP"
        # Install prebuilt pulseaudio snap but first install if from
	# the store to work around the fact that we are not allowed
	# anymore to connect pulseaudio slot to a snap installed with
	# --dangerous
	snap install --beta pulseaudio
	snap install --dangerous /home/pulseaudio/pulseaudio_*_amd64.snap
fi

# Snapshot of the current snapd state for a later restore
if [ ! -f $SPREAD_PATH/snapd-state.tar.gz ] ; then
	systemctl stop snapd.service snapd.socket
	tar czf $SPREAD_PATH/snapd-state.tar.gz /var/lib/snapd
	systemctl start snapd.socket
fi

# For debugging dump all snaps and connected slots/plugs
snap list
snap interfaces