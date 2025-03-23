#### General Concept
 
This repository serves as the primary source of Ansible automation code for deploying and maintaining security tools. The code has undergone significant refactoring, following the guiding principles outlined in `CONCEPTS.md` (not included here). Any future enhancements should be made exclusively in this repository to further improve automation.
 
#### Prerequisites
If (1) a new VM is provisioned or (2) an existing VM is upgraded to RHEL8, then you **must** choose one of the following options **before executing the playbook**:

- Run the `Hosts Inventory Update - Ansible` Jenkins job.
- OR execute `ansible-playbook` with the extra parameter `-e x_os_ver=<VERSION>` to explicitly set the correct RHEL major release version.
 
#### Installation and Removal of Security Tools
The playbook relies on the `x_cms_sectools` parameter from the inventory. This parameter defines the list of security tools that must be installed on a given host to ensure security compliance. The required security tools are determined based on a set of CMS attributes that apply to that specific host.

For further details:
- Refer to the [Process Flow Diagram for Security Tool Onboarding](../original_code/README.md#original-process-flow-diagram).
- To understand the logic behind determining **required** security tools, see [`cms_sectools.jq`](../original_code/cms_sectools.jq).
 
The playbook can:
- Install **all** or a **specific** security tool(s).
- Run specific tasks related to a security tool using the appropriate tags.
- Ensure that if `splunk` is installed, the setup process includes configuring `splunk`, `syslog` permissions, and `auditd` integration.
- Uninstall **all** or a **specific** security tool(s) with `--tags uninstall`.

See the examples below for details on execution.

---

#### Ansible Playbook Call Simplification
This section provides simplified examples of how to use Ansible playbooks for installing, uninstalling, and managing security tools.

##### Install **all** required security tools
```bash
## Note: the 'sectools' tag is required for all tasks pertaining to setup/install of all sectools.
 
$> ansible-playbook playbooks/os_fullsetup.yml --tags sectools --limit='<HOSTNAME>'  
```
*(Replace `<HOSTNAME>` with your actual target server.)*
 
##### Forcibly Supply The RHEL Major Release Version During Installation
```bash
## Same as above, but the Hosts Inventory does not currently contain the correct `x_os_ver` variable.
 
$> ansible-playbook playbooks/os_fullsetup.yml --tags sectools --limit='<HOSTNAME>' -e x_os_ver=<VERSION>
```
*(Replace `<HOSTNAME>` with your actual target server and `<VERSION>` with the RHEL version.)*
 
##### Uninstall **all** security tools
```bash
## Note: You MUST include the 'uninstall' tag when executing the removal playbook.
 
$> ansible-playbook playbooks/os_sectools/removal.yml --tags uninstall --limit='<HOSTNAME>'
```
*(Replace `<HOSTNAME>` with your actual target server.)*

##### Install/Uninstall a single security tool
```bash
## Default behavior is to setup the sectool of choice when no tags are specified.
## You can also specify `--tags install` to explicitly install.
 
$> ansible-playbook playbooks/os_sectools/imperva.yml --limit='<HOSTNAME>'
$> ansible-playbook playbooks/os_sectools/imperva.yml --tags install --limit='<HOSTNAME>'
$> ansible-playbook playbooks/os_sectools/imperva.yml --tags uninstall --limit='<HOSTNAME>'
```
*(Replace `<HOSTNAME>` with your actual target server.)*
 
##### Stop/Start a security tool
```bash
$> ansible-playbook playbooks/os_sectools/imperva.yml --tags stop,start --limit='<HOSTNAME>'
```
*(Replace `<HOSTNAME>` with your actual target server.)*