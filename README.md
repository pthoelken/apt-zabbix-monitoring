# apt-zabbix-monitoring

This project provides a simple way to monitor available Debian/Ubuntu package updates (including security updates) with **Zabbix 7.2**. It installs the required configuration files for the Zabbix Agent2 and apt periodic jobs, and provides a ready-to-use Zabbix template.

---

## 🚀 Installation

Run the following command on your Debian/Ubuntu host:

```bash
wget https://raw.githubusercontent.com/pthoelken/apt-zabbix-monitoring/refs/heads/main/install.sh -O install_apt_zabbix_monitoring.sh ; bash install_apt_zabbix_monitoring.sh ;
```

The script will:

1. Check if `git` is installed – if not, it installs it silently.
2. Clone this repository into `/tmp`.
3. Copy:
   - `zabbix_agentd.d/apt-updates.conf` → `/etc/zabbix/zabbix_agent2.d/apt-updates.conf`
   - `apt.conf.d/02periodic` → `/etc/apt/apt.conf.d/02periodic`
4. Restart the Zabbix Agent2 service and verify that it is running.
5. Clean up all temporary files.

All operations are logged in the format:

```
SUCCESS | YYYY-MM-DD HH:MM:SS | message
ERROR   | YYYY-MM-DD HH:MM:SS | message
```

with green/red color highlighting.

---

## 📦 Zabbix Template

After installation, you must import the template:

1. Go to **Configuration → Templates** in Zabbix 7.2.
2. Click **Import**.
3. Select the file [`templates/zbx_export_templates_7.X.xml`](templates/).
4. Attach the template to your host(s).

---

## ✅ What you get

- Automatic detection of available Debian/Ubuntu updates
- Differentiation between **security updates** and **non-security updates**
- Ready-to-use template for Zabbix 7.2 and LTS 7.0
- Minimal system overhead (lightweight Bash + apt commands)

---

## 📝 Requirements

- Debian/Ubuntu with `apt-get`
- Zabbix Agent2 installed and running
- Zabbix Server 7.2+

---

## 📂 Repository structure

```
├── install.sh                   # Installation script
├── zabbix_agentd.d/apt-updates.conf
├── apt.conf.d/02periodic
└── templates/
    └── zbx_export_templates.xml
```

---

## 📖 Usage

Once the template is attached to your host, Zabbix will start collecting:

- Number of available **security updates**
- Number of available **non-security updates**
- Combined update statistics

You can then build triggers, graphs, or dashboards on top of this data.

---

## ⚡ Example Zabbix Item

Example item key used in the template:

```
apt.updates
```

Update interval can be adjusted as needed (default: every 900s = 15 minutes).

---

## 🧹 Uninstallation

To remove the integration, simply delete:

- `/etc/zabbix/zabbix_agent2.d/apt-updates.conf`
- `/etc/apt/apt.conf.d/02periodic`

and remove the template from Zabbix.

---
