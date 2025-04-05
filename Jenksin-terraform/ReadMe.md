Here’s the focused section for adding the Jenkins user and enabling root access:

---

## Adding Jenkins User and Enabling Root Access

1. **Switch to Jenkins User**:
   ```bash
   sudo su jenkins
   ```

2. **Verify Sudo Group Permissions**:
   Check if the `jenkins` user has sudo privileges:
   ```bash
   sudo cat /etc/group | grep sudo
   ```

3. **Add Jenkins User to Sudo Group**:
   If the `jenkins` user is not in the `sudo` group, add them:
   ```bash
   sudo usermod -aG sudo jenkins
   ```

4. **Set/Reset Jenkins User Password**:
   Assign or update the password for the `jenkins` user:
   ```bash
   sudo passwd jenkins
   ```

5. **Switch to Root User**:
   Once the Jenkins user has sudo privileges, you can switch to the root user:
   ```bash
   sudo su
   ```

---

This guide simplifies the process of managing the `jenkins` user and enabling root-level access responsibly. Let me know if you'd like any additional information! 🚀