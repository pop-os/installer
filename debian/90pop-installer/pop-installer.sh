#!/bin/sh
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
USERNAME=$(getarg username)
APP=io.elementary.installer

# Create live user account
chroot ${NEWROOT} useradd -m -c ${USERNAME} -G adm,sudo,video -s /bin/bash ${USERNAME}
chroot ${NEWROOT} passwd -d ${USERNAME} >/dev/null 2>&1
chroot ${NEWROOT} sh -c "echo $USERNAME:pop-os | chpasswd -c SHA512"

# Install autostart desktop file
AUTOSTART_DIR="/home/$USERNAME/.config/autostart"
chroot ${NEWROOT} install -d -o "$USERNAME" -g "$USERNAME" ${AUTOSTART_DIR}
chroot ${NEWROOT} install -D -o "$USERNAME" -g "$USERNAME" "/usr/share/applications/$APP.desktop" "${AUTOSTART_DIR}/$APP.desktop"

# Disable suspend for the live environment
chroot ${NEWROOT} mkdir -p "/home/$USERNAME/.config/cosmic/com.system76.CosmicIdle/v1/"
chroot ${NEWROOT} cat > "/home/$USERNAME/.config/cosmic/com.system76.CosmicIdle/v1/suspend_on_ac_time" <<< None
chroot ${NEWROOT} cat > "/home/$USERNAME/.config/cosmic/com.system76.CosmicIdle/v1/suspend_on_battery_time" <<< None
chroot ${NEWROOT} cat > "/home/$USERNAME/.config/cosmic/com.system76.CosmicIdle/v1/screen_off_time" <<< None

# Prevent initial setup popup
chroot ${NEWROOT} touch "/home/$USERNAME/.config/cosmic-initial-setup-done"

# Change permissions of the files we generated for the live user
chroot ${NEWROOT} chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

ln -s /run/initramfs/live ${NEWROOT}/cdrom

# Overwrite cosmic-greeter's config to enable automatic login for the live user
cat > "${NEWROOT}/etc/greetd/cosmic-greeter.toml" <<_EOF
[terminal]
vt = "1"

[general]
service = "cosmic-greeter"

[default_session]
command = "cosmic-greeter-start"
user = "cosmic-greeter"

[initial_session]
command = "start-cosmic"
user = "${USERNAME}"
_EOF

# Passwordless polkit and sudo permissions
echo "${USERNAME} ALL=(ALL:ALL) NOPASSWD: ALL" > "${NEWROOT}/etc/sudoers.d/99-pop-live"
cat > ${NEWROOT}/etc/polkit-1/rules.d/pop-live.rules <<_EOF
polkit.addAdminRule(function(action, subject) {
    return ["unix-group:adm"];
});

polkit.addRule(function(action, subject) {
    if (subject.isInGroup("adm")) {
        return polkit.Result.YES;
    }
});
_EOF
chroot ${NEWROOT} chown polkitd:polkitd /etc/polkit-1/rules.d/pop-live.rules

# Set favorites for COSMIC
favorites="${NEWROOT}/usr/share/cosmic/com.system76.CosmicAppList/v1/favorites"
mkdir -p "$(dirname "${favorites}")"
cat > "${favorites}" <<_EOF
[
    "firefox",
    "com.system76.CosmicFiles",
    "com.system76.CosmicEdit",
    "com.system76.CosmicTerm",
    "com.system76.CosmicStore",
    "com.system76.CosmicSettings",
    "$APP",
]
_EOF

# Set COSMIC X11 scaling to optimize for applications
descale="${NEWROOT}/usr/share/cosmic/com.system76.CosmicComp/v1/descale_xwayland"
mkdir -p "$(dirname "${descale}")"
echo "r#true" > "${descale}"
